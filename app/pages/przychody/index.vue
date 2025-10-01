<template>
  <div>
    <div class="flex justify-between items-center mb-8">
      <h1 class="text-3xl font-bold">Przychody</h1>
      <UButton @click="openCreateModal"> Dodaj przychód </UButton>
    </div>

    <!-- Filters -->
    <UCard class="mb-6">
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <UFormField label="Od daty">
          <UInput v-model="filters.dateFrom" type="date" />
        </UFormField>
        <UFormField label="Do daty">
          <UInput v-model="filters.dateTo" type="date" />
        </UFormField>
        <UFormField label="Typ">
          <USelect
            v-model="filters.companyType"
            :options="[
              { label: 'Wszystkie', value: '' },
              { label: 'Firmowe', value: 'company' },
              { label: 'Prywatne', value: 'private' },
            ]"
          />
        </UFormField>
      </div>
    </UCard>

    <UCard v-if="loading" class="text-center"> Ładowanie... </UCard>

    <UCard v-else-if="filteredIncomes.length === 0">
      <div class="text-center text-gray-500">
        Brak przychodów. Dodaj pierwszy przychód.
      </div>
    </UCard>

    <UCard v-else>
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
          <thead class="bg-gray-50 dark:bg-gray-800">
            <tr>
              <th
                class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Data
              </th>
              <th
                class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Tytuł
              </th>
              <th
                class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Kontrahent
              </th>
              <th
                class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Kwota brutto
              </th>
              <th
                class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                VAT
              </th>
              <th
                class="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Typ
              </th>
              <th
                class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Akcje
              </th>
            </tr>
          </thead>
          <tbody
            class="bg-white dark:bg-gray-900 divide-y divide-gray-200 dark:divide-gray-700"
          >
            <tr v-for="income in filteredIncomes" :key="income.id">
              <td class="px-6 py-4 whitespace-nowrap text-sm">
                {{ formatDate(income.issue_date) }}
              </td>
              <td class="px-6 py-4 text-sm">
                <div class="font-medium">{{ income.title }}</div>
                <div v-if="income.invoice_number" class="text-gray-500 text-xs">
                  {{ income.invoice_number }}
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                {{ income.counterparty || '-' }}
              </td>
              <td
                class="px-6 py-4 whitespace-nowrap text-sm text-right font-medium"
              >
                {{ formatCurrency(income.amount_gross) }}
              </td>
              <td
                class="px-6 py-4 whitespace-nowrap text-sm text-right text-gray-500"
              >
                {{ formatCurrency(income.vat_amount) }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-center">
                <UBadge
                  :color="income.is_company ? 'blue' : 'gray'"
                  variant="subtle"
                >
                  {{ income.is_company ? 'Firmowy' : 'Prywatny' }}
                </UBadge>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right text-sm">
                <UDropdownMenu :items="getDropdownItems(income)">
                  <UButton
                    color="neutral"
                    variant="ghost"
                    icon="i-heroicons-ellipsis-vertical"
                  />
                </UDropdownMenu>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Summary -->
      <div class="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
        <div class="grid grid-cols-2 gap-4 text-sm">
          <div>
            <span class="text-gray-500"
              >Suma przychodów ({{ filteredIncomes.length }} pozycji)</span
            >
          </div>
          <div class="text-right">
            <span class="font-bold text-lg">{{
              formatCurrency(totalGross)
            }}</span>
          </div>
          <div>
            <span class="text-gray-500">VAT należny</span>
          </div>
          <div class="text-right">
            <span class="font-semibold">{{ formatCurrency(totalVat) }}</span>
          </div>
        </div>
      </div>
    </UCard>

    <!-- Create/Edit Modal -->
    <UModal
      v-model:open="isModalOpen"
      :title="editingIncome ? 'Edytuj przychód' : 'Dodaj przychód'"
    >
      <template #content>
        <form @submit.prevent="handleSubmit" class="space-y-4 p-4">
          <UFormField label="Tytuł" name="title" required>
            <UInput
              v-model="form.title"
              placeholder="Nazwa przychodu"
              required
            />
          </UFormField>

          <UFormField label="Kontrahent" name="counterparty">
            <UInput
              v-model="form.counterparty"
              placeholder="Nazwa kontrahenta"
            />
          </UFormField>

          <UFormField label="Numer faktury" name="invoice_number">
            <UInput v-model="form.invoice_number" placeholder="FV/01/2025" />
          </UFormField>

          <UFormField label="Data wystawienia" name="issue_date" required>
            <UInput v-model="form.issue_date" type="date" required />
          </UFormField>

          <UFormField label="Stawka VAT (%)" name="vat_rate" required>
            <USelect
              v-model="form.vat_rate"
              :options="[
                { label: '23%', value: 23 },
                { label: '8%', value: 8 },
                { label: '5%', value: 5 },
                { label: '0%', value: 0 },
                { label: 'Zwolnione', value: -1 },
              ]"
            />
          </UFormField>

          <div class="grid grid-cols-2 gap-4">
            <UFormField label="Kwota netto" name="amount_net">
              <UInput
                v-model="form.amount_net"
                type="number"
                step="0.01"
                placeholder="0.00"
                @input="calculateFromNet"
                @focus="activeField = 'net'"
              />
            </UFormField>

            <UFormField label="Kwota brutto" name="amount_gross">
              <UInput
                v-model="form.amount_gross"
                type="number"
                step="0.01"
                placeholder="0.00"
                @input="calculateFromGross"
                @focus="activeField = 'gross'"
              />
            </UFormField>
          </div>

          <UFormField label="VAT" name="vat_amount">
            <UInput
              :model-value="form.vat_amount"
              type="number"
              step="0.01"
              disabled
              class="bg-gray-50 dark:bg-gray-800"
            />
          </UFormField>

          <UFormField label="Przychód firmowy" name="is_company">
            <USwitch v-model="form.is_company" />
          </UFormField>

          <UFormField label="Notatka" name="note">
            <UTextarea
              v-model="form.note"
              placeholder="Dodatkowe informacje..."
              rows="3"
            />
          </UFormField>

          <div class="flex justify-end space-x-2">
            <UButton color="neutral" variant="ghost" @click="closeModal">
              Anuluj
            </UButton>
            <UButton type="submit" :loading="saving">
              {{ editingIncome ? 'Zapisz' : 'Dodaj' }}
            </UButton>
          </div>
        </form>
      </template>
    </UModal>
  </div>
</template>

<script setup lang="ts">
import type { Database } from '~/types/database';

definePageMeta({
  middleware: 'auth',
});

type Income = Database['public']['Tables']['incomes']['Row'];

const supabase = useSupabaseClient<Database>();
const user = useSupabaseUser();
const { fromNet, fromGross } = useVat();

const incomes = ref<Income[]>([]);
const loading = ref(true);
const isModalOpen = ref(false);
const editingIncome = ref<Income | null>(null);
const saving = ref(false);
const activeField = ref<'net' | 'gross'>('gross');

const filters = reactive({
  dateFrom: '',
  dateTo: '',
  companyType: '',
});

const form = reactive({
  title: '',
  note: '',
  counterparty: '',
  invoice_number: '',
  issue_date: new Date().toISOString().split('T')[0],
  vat_rate: 23,
  amount_net: null as number | null,
  amount_gross: null as number | null,
  vat_amount: 0,
  is_company: false,
});

const loadIncomes = async () => {
  if (!user.value) return;

  loading.value = true;
  const { data, error } = await supabase
    .from('incomes')
    .select('*')
    .eq('user_id', user.value.sub)
    .order('issue_date', { ascending: false });

  if (error) {
    console.error('Error loading incomes:', error);
  } else {
    incomes.value = data || [];
  }
  loading.value = false;
};

const filteredIncomes = computed(() => {
  return incomes.value.filter((income) => {
    if (filters.dateFrom && income.issue_date < filters.dateFrom) return false;
    if (filters.dateTo && income.issue_date > filters.dateTo) return false;
    if (filters.companyType === 'company' && !income.is_company) return false;
    if (filters.companyType === 'private' && income.is_company) return false;
    return true;
  });
});

const totalGross = computed(() => {
  return filteredIncomes.value.reduce(
    (sum, income) => sum + (income.amount_gross || 0),
    0
  );
});

const totalVat = computed(() => {
  return filteredIncomes.value
    .filter((i) => i.is_company)
    .reduce((sum, income) => sum + (income.vat_amount || 0), 0);
});

const formatDate = (date: string) => {
  return new Date(date).toLocaleDateString('pl-PL');
};

const formatCurrency = (amount: number | null) => {
  if (amount === null) return '-';
  return new Intl.NumberFormat('pl-PL', {
    style: 'currency',
    currency: 'PLN',
  }).format(amount);
};

const calculateFromNet = () => {
  if (activeField.value !== 'net') return;
  if (form.amount_net === null || form.amount_net === 0) {
    form.amount_gross = null;
    form.vat_amount = 0;
    return;
  }

  const result = fromNet(
    form.amount_net,
    form.vat_rate === -1 ? 0 : form.vat_rate
  );
  form.amount_gross = result.gross;
  form.vat_amount = result.vat;
};

const calculateFromGross = () => {
  if (activeField.value !== 'gross') return;
  if (form.amount_gross === null || form.amount_gross === 0) {
    form.amount_net = null;
    form.vat_amount = 0;
    return;
  }

  const result = fromGross(
    form.amount_gross,
    form.vat_rate === -1 ? 0 : form.vat_rate
  );
  form.amount_net = result.net;
  form.vat_amount = result.vat;
};

const openCreateModal = () => {
  editingIncome.value = null;
  form.title = '';
  form.note = '';
  form.counterparty = '';
  form.invoice_number = '';
  form.issue_date = new Date().toISOString().split('T')[0];
  form.vat_rate = 23;
  form.amount_net = null;
  form.amount_gross = null;
  form.vat_amount = 0;
  form.is_company = false;
  activeField.value = 'gross';
  isModalOpen.value = true;
};

const openEditModal = (income: Income) => {
  editingIncome.value = income;
  form.title = income.title;
  form.note = income.note || '';
  form.counterparty = income.counterparty || '';
  form.invoice_number = income.invoice_number || '';
  form.issue_date = income.issue_date;
  form.vat_rate = income.vat_rate;
  form.amount_net = income.amount_net;
  form.amount_gross = income.amount_gross;
  form.vat_amount = income.vat_amount || 0;
  form.is_company = income.is_company;
  activeField.value = 'gross';
  isModalOpen.value = true;
};

const closeModal = () => {
  isModalOpen.value = false;
  editingIncome.value = null;
};

const handleSubmit = async () => {
  if (!user.value) return;

  saving.value = true;

  const incomeData = {
    user_id: user.value.sub,
    title: form.title,
    note: form.note || null,
    counterparty: form.counterparty || null,
    invoice_number: form.invoice_number || null,
    issue_date: form.issue_date,
    vat_rate: form.vat_rate === -1 ? 0 : form.vat_rate,
    amount_net: form.amount_net,
    amount_gross: form.amount_gross,
    is_company: form.is_company,
  };

  if (editingIncome.value) {
    const { error } = await supabase
      .from('incomes')
      .update(incomeData)
      .eq('id', editingIncome.value.id);

    if (error) {
      console.error('Error updating income:', error);
    } else {
      await loadIncomes();
      closeModal();
    }
  } else {
    const { error } = await supabase.from('incomes').insert(incomeData);

    if (error) {
      console.error('Error creating income:', error);
    } else {
      await loadIncomes();
      closeModal();
    }
  }

  saving.value = false;
};

const deleteIncome = async (income: Income) => {
  if (!confirm(`Czy na pewno chcesz usunąć przychód "${income.title}"?`)) {
    return;
  }

  const { error } = await supabase.from('incomes').delete().eq('id', income.id);

  if (error) {
    console.error('Error deleting income:', error);
  } else {
    await loadIncomes();
  }
};

const getDropdownItems = (income: Income) => [
  [
    {
      label: 'Edytuj',
      icon: 'i-heroicons-pencil-square',
      click: () => openEditModal(income),
    },
    {
      label: 'Usuń',
      icon: 'i-heroicons-trash',
      click: () => deleteIncome(income),
    },
  ],
];

watch(
  () => form.vat_rate,
  () => {
    if (activeField.value === 'net' && form.amount_net) {
      calculateFromNet();
    } else if (activeField.value === 'gross' && form.amount_gross) {
      calculateFromGross();
    }
  }
);

onMounted(() => {
  // Set default date range (current month)
  const now = new Date();
  const firstDay = new Date(now.getFullYear(), now.getMonth(), 1);
  const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0);

  filters.dateFrom = firstDay.toISOString().split('T')[0];
  filters.dateTo = lastDay.toISOString().split('T')[0];

  loadIncomes();
});
</script>
