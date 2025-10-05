<template>
  <div>
    <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4 mb-6 sm:mb-8">
      <h1 class="text-2xl sm:text-3xl font-bold">Kredyty</h1>
      <UButton @click="showAddModal = true" class="w-full sm:w-auto">
        Dodaj kredyt
      </UButton>
    </div>

    <UCard v-if="loading" class="text-center"> Ładowanie... </UCard>

    <UCard v-else-if="loans.length === 0">
      <div class="text-center text-gray-500">
        Brak kredytów. Dodaj pierwszy kredyt.
      </div>
    </UCard>

    <UCard v-else>
      <!-- Mobile view - Cards -->
      <div class="md:hidden space-y-4">
        <UCard v-for="loan in loans" :key="loan.id">
          <div class="space-y-3">
            <div class="flex justify-between items-start">
              <div class="flex-1">
                <div class="font-medium text-base">{{ loan.title }}</div>
                <div class="text-xs text-gray-500 mt-0.5">
                  {{ loan.bank_name }}
                </div>
              </div>
              <UDropdownMenu :items="getDropdownItems(loan)">
                <UButton
                  color="neutral"
                  variant="ghost"
                  icon="i-heroicons-ellipsis-vertical"
                  size="sm"
                />
              </UDropdownMenu>
            </div>

            <div class="flex justify-between items-center">
              <span class="text-lg font-bold">
                {{ formatCurrency(loan.monthly_amount) }}/mies.
              </span>
              <div class="flex gap-2">
                <UBadge
                  :color="loan.is_company ? 'info' : 'neutral'"
                  variant="subtle"
                  size="sm"
                >
                  {{ loan.is_company ? 'Firmowy' : 'Prywatny' }}
                </UBadge>
                <UBadge
                  :color="isLoanActive(loan) ? 'success' : 'neutral'"
                  variant="subtle"
                  size="sm"
                >
                  {{ isLoanActive(loan) ? 'Aktywny' : 'Zakończony' }}
                </UBadge>
              </div>
            </div>

            <div class="text-xs text-gray-500 mb-2">
              {{ formatDate(loan.start_date) }} - {{ formatDate(loan.end_date) }}
            </div>
            <div class="space-y-1">
              <div class="flex items-center gap-2 text-xs">
                <span class="text-green-600 dark:text-green-400">
                  Zapłacone: {{ getPaymentInfo(loan).paid }}
                </span>
                <span class="text-gray-400">|</span>
                <span class="text-red-600 dark:text-red-400">
                  Pozostało: {{ getPaymentInfo(loan).remaining }}
                </span>
              </div>
              <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                <div
                  class="bg-gradient-to-r from-green-500 to-green-600 h-2 rounded-full transition-all"
                  :style="{ width: getPaymentInfo(loan).percentage + '%' }"
                />
              </div>
            </div>
          </div>
        </UCard>
      </div>

      <!-- Desktop view - Table -->
      <div class="hidden md:block overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
          <thead class="bg-gray-50 dark:bg-gray-800">
            <tr>
              <th
                class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Tytuł
              </th>
              <th
                class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Bank
              </th>
              <th
                class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Rata miesięczna
              </th>
              <th
                class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Okres
              </th>
              <th
                class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Postęp
              </th>
              <th
                class="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Typ
              </th>
              <th
                class="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Status
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
            <tr v-for="loan in loans" :key="loan.id">
              <td class="px-6 py-4 text-sm">
                <div class="font-medium">{{ loan.title }}</div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm">
                {{ loan.bank_name }}
              </td>
              <td
                class="px-6 py-4 whitespace-nowrap text-sm text-right font-medium"
              >
                {{ formatCurrency(loan.monthly_amount) }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                {{ formatDate(loan.start_date) }} - {{ formatDate(loan.end_date) }}
              </td>
              <td class="px-6 py-4 text-sm">
                <div class="space-y-2 min-w-[180px]">
                  <div class="flex items-center gap-3 text-xs">
                    <span class="text-green-600 dark:text-green-400 font-medium">
                      {{ getPaymentInfo(loan).paid }}
                    </span>
                    <span class="text-gray-400">/</span>
                    <span class="text-red-600 dark:text-red-400 font-medium">
                      {{ getPaymentInfo(loan).remaining }}
                    </span>
                    <span class="text-gray-400 ml-auto">
                      {{ getPaymentInfo(loan).percentage }}%
                    </span>
                  </div>
                  <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                    <div
                      class="bg-gradient-to-r from-green-500 to-green-600 h-2 rounded-full transition-all"
                      :style="{ width: getPaymentInfo(loan).percentage + '%' }"
                    />
                  </div>
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-center">
                <UBadge
                  :color="loan.is_company ? 'info' : 'neutral'"
                  variant="subtle"
                >
                  {{ loan.is_company ? 'Firmowy' : 'Prywatny' }}
                </UBadge>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-center">
                <UBadge
                  :color="isLoanActive(loan) ? 'success' : 'neutral'"
                  variant="subtle"
                >
                  {{ isLoanActive(loan) ? 'Aktywny' : 'Zakończony' }}
                </UBadge>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right text-sm">
                <UDropdownMenu :items="getDropdownItems(loan)">
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
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div class="text-center sm:text-left">
            <div class="text-sm text-gray-500">Aktywne kredyty</div>
            <div class="text-2xl font-bold">{{ activeLoansCount }}</div>
          </div>
          <div class="text-center sm:text-left">
            <div class="text-sm text-gray-500">Suma miesięcznych rat</div>
            <div class="text-2xl font-bold">{{ formatCurrency(totalMonthlyPayments) }}</div>
          </div>
          <div class="text-center sm:text-left">
            <div class="text-sm text-gray-500">Wszystkie kredyty</div>
            <div class="text-2xl font-bold">{{ loans.length }}</div>
          </div>
        </div>
      </div>
    </UCard>

    <!-- Add/Edit Modal -->
    <UModal v-model:open="showAddModal" :title="editingLoan ? 'Edytuj kredyt' : 'Dodaj kredyt'">
      <template #content>
        <UForm :state="formState" @submit="saveLoan" class="space-y-4 p-4">
          <UFormField label="Tytuł" name="title" required>
            <UInput v-model="formState.title" placeholder="np. Kredyt hipoteczny" />
          </UFormField>

          <UFormField label="Bank" name="bank_name" required>
            <UInput v-model="formState.bank_name" placeholder="np. PKO BP" />
          </UFormField>

          <UFormField label="Rata miesięczna (PLN)" name="monthly_amount" required>
            <UInput v-model.number="formState.monthly_amount" type="number" step="0.01" />
          </UFormField>

          <UFormField label="Data rozpoczęcia" name="start_date" required>
            <UInput v-model="formState.start_date" type="date" />
          </UFormField>

          <UFormField label="Data zakończenia" name="end_date" required>
            <UInput v-model="formState.end_date" type="date" />
          </UFormField>

          <UFormField label="Typ kredytu" name="is_company">
            <USelect
              v-model="formState.is_company"
              :items="[
                { label: 'Prywatny', value: false },
                { label: 'Firmowy', value: true },
              ]"
            />
          </UFormField>

          <div class="flex justify-end gap-2 pt-4">
            <UButton
              color="neutral"
              variant="outline"
              @click="showAddModal = false"
            >
              Anuluj
            </UButton>
            <UButton type="submit">
              {{ editingLoan ? 'Zapisz' : 'Dodaj' }}
            </UButton>
          </div>
        </UForm>
      </template>
    </UModal>
  </div>
</template>

<script setup lang="ts">
import type { Database } from '~/types/database';

definePageMeta({
  middleware: 'auth',
});

type Loan = Database['public']['Tables']['loans']['Row'];

const supabase = useSupabaseClient<Database>();
const user = useSupabaseUser();

const loans = ref<Loan[]>([]);
const loading = ref(true);
const showAddModal = ref(false);
const editingLoan = ref<Loan | null>(null);

const formState = reactive({
  title: '',
  bank_name: '',
  loan_purpose: 'Kredyt',
  monthly_amount: 0,
  start_date: '',
  end_date: '',
  is_company: false,
});

const resetForm = () => {
  formState.title = '';
  formState.bank_name = '';
  formState.loan_purpose = 'Kredyt';
  formState.monthly_amount = 0;
  formState.start_date = '';
  formState.end_date = '';
  formState.is_company = false;
  editingLoan.value = null;
};

const loadLoans = async () => {
  if (!user.value) return;

  loading.value = true;
  const { data, error } = await supabase
    .from('loans')
    .select('*')
    .eq('user_id', user.value.sub)
    .order('start_date', { ascending: false });

  if (error) {
    console.error('Error loading loans:', error);
  } else {
    loans.value = data || [];
  }
  loading.value = false;
};

const saveLoan = async () => {
  if (!user.value) return;

  if (editingLoan.value) {
    // Update existing loan
    const { error } = await supabase
      .from('loans')
      .update({
        title: formState.title,
        bank_name: formState.bank_name,
        loan_purpose: formState.loan_purpose,
        monthly_amount: formState.monthly_amount,
        start_date: formState.start_date,
        end_date: formState.end_date,
        is_company: formState.is_company,
      })
      .eq('id', editingLoan.value.id);

    if (error) {
      console.error('Error updating loan:', error);
      return;
    }
  } else {
    // Create new loan
    const { error } = await supabase.from('loans').insert({
      user_id: user.value.sub,
      title: formState.title,
      bank_name: formState.bank_name,
      loan_purpose: formState.loan_purpose,
      monthly_amount: formState.monthly_amount,
      start_date: formState.start_date,
      end_date: formState.end_date,
      is_company: formState.is_company,
    });

    if (error) {
      console.error('Error creating loan:', error);
      return;
    }
  }

  showAddModal.value = false;
  resetForm();
  await loadLoans();
};

const editLoan = (loan: Loan) => {
  editingLoan.value = loan;
  formState.title = loan.title;
  formState.bank_name = loan.bank_name;
  formState.loan_purpose = loan.loan_purpose;
  formState.monthly_amount = Number(loan.monthly_amount);
  formState.start_date = loan.start_date;
  formState.end_date = loan.end_date;
  formState.is_company = loan.is_company;
  showAddModal.value = true;
};

const deleteLoan = async (loan: Loan) => {
  if (!confirm(`Czy na pewno chcesz usunąć kredyt "${loan.title}"?`)) {
    return;
  }

  const { error } = await supabase
    .from('loans')
    .delete()
    .eq('id', loan.id);

  if (error) {
    console.error('Error deleting loan:', error);
  } else {
    await loadLoans();
  }
};

const isLoanActive = (loan: Loan) => {
  const today = new Date().toISOString().split('T')[0];
  return loan.start_date <= today && loan.end_date >= today;
};

const getPaymentInfo = (loan: Loan) => {
  const startDate = new Date(loan.start_date);
  const endDate = new Date(loan.end_date);
  const today = new Date();

  // Calculate total months between start and end
  const totalMonths = (endDate.getFullYear() - startDate.getFullYear()) * 12
    + (endDate.getMonth() - startDate.getMonth()) + 1;

  // Calculate elapsed months
  let elapsedMonths = 0;
  if (today >= startDate) {
    elapsedMonths = Math.min(
      (today.getFullYear() - startDate.getFullYear()) * 12
        + (today.getMonth() - startDate.getMonth()) + 1,
      totalMonths
    );
  }

  const remainingMonths = Math.max(0, totalMonths - elapsedMonths);
  const percentage = totalMonths > 0 ? Math.round((elapsedMonths / totalMonths) * 100) : 0;

  return {
    paid: elapsedMonths,
    remaining: remainingMonths,
    total: totalMonths,
    percentage
  };
};

const activeLoansCount = computed(() => {
  return loans.value.filter(loan => isLoanActive(loan)).length;
});

const totalMonthlyPayments = computed(() => {
  return loans.value
    .filter(loan => isLoanActive(loan))
    .reduce((sum, loan) => sum + Number(loan.monthly_amount), 0);
});

const formatDate = (date: string) => {
  return new Date(date).toLocaleDateString('pl-PL');
};

const { formatCurrency: formatCurrencyFn } = useCurrency();

const formatCurrency = (amount: number | null, currencyCode: string = 'PLN') => {
  return formatCurrencyFn(amount, currencyCode);
};

const getDropdownItems = (loan: Loan) => [
  [
    {
      label: 'Edytuj',
      icon: 'i-heroicons-pencil-square',
      onSelect: () => editLoan(loan),
    },
    {
      label: 'Usuń',
      icon: 'i-heroicons-trash',
      onSelect: () => deleteLoan(loan),
    },
  ],
];

watch(showAddModal, (newValue) => {
  if (!newValue) {
    resetForm();
  }
});

onMounted(() => {
  loadLoans();
});
</script>
