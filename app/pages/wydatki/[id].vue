<template>
  <div>
    <div class="mb-8">
      <UButton
        variant="ghost"
        icon="i-heroicons-arrow-left"
        @click="$router.push('/wydatki')"
      >
        Powrót do listy
      </UButton>
      <h1 class="text-3xl font-bold mt-4">Edytuj wydatek</h1>
    </div>

    <UCard v-if="loading" class="text-center py-8"> Ładowanie... </UCard>

    <UCard v-else-if="!expense" class="text-center py-8">
      <p class="text-gray-500 mb-4">Nie znaleziono wydatku</p>
      <UButton @click="$router.push('/wydatki')"> Powrót do listy </UButton>
    </UCard>

    <UCard v-else>
      <form class="space-y-6" @submit.prevent="handleSubmit">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <!-- Basic Info -->
          <UFormField label="Tytuł" name="title" required>
            <UInput v-model="form.title" placeholder="Nazwa wydatku" required />
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

          <UFormField label="Termin płatności" name="due_date">
            <UInput v-model="form.due_date" type="date" />
          </UFormField>

          <UFormField label="Stawka VAT (%)" name="vat_rate" required>
            <USelect
              v-model="form.vat_rate"
              :items="[
                { label: '23%', value: 23 },
                { label: '8%', value: 8 },
                { label: '5%', value: 5 },
                { label: '0%', value: 0 },
                { label: 'Zwolnione', value: -1 },
              ]"
            />
          </UFormField>
        </div>

        <!-- Amount Calculation -->
        <div class="border-t border-gray-200 dark:border-gray-700 pt-6">
          <h3 class="text-lg font-semibold mb-4">Kwoty</h3>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
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

            <UFormField label="VAT" name="vat_amount">
              <UInput
                :model-value="form.vat_amount"
                type="number"
                step="0.01"
                disabled
                class="bg-gray-50 dark:bg-gray-800"
              />
            </UFormField>
          </div>
        </div>

        <!-- Categories -->
        <div class="border-t border-gray-200 dark:border-gray-700 pt-6">
          <h3 class="text-lg font-semibold mb-4">Kategorie</h3>
          <div v-if="loadingCategories" class="text-gray-500">
            Ładowanie kategorii...
          </div>
          <div v-else-if="categories.length === 0" class="text-gray-500">
            Brak dostępnych kategorii.
            <NuxtLink to="/kategorie" class="text-primary-500"
              >Dodaj kategorie</NuxtLink
            >
          </div>
          <div v-else class="flex flex-wrap gap-2">
            <UButton
              v-for="category in categories"
              :key="category.id"
              :color="
                form.category_ids.includes(category.id) ? 'primary' : 'neutral'
              "
              :variant="
                form.category_ids.includes(category.id) ? 'solid' : 'outline'
              "
              @click="toggleCategory(category.id)"
            >
              <div class="flex items-center space-x-2">
                <div
                  class="w-3 h-3 rounded-full"
                  :style="{ backgroundColor: category.color || '#3b82f6' }"
                />
                <span>{{ category.name }}</span>
              </div>
            </UButton>
          </div>
        </div>

        <!-- Tax Deduction -->
        <div class="border-t border-gray-200 dark:border-gray-700 pt-6">
          <h3 class="text-lg font-semibold mb-4">Ustawienia</h3>

          <UFormField label="Wydatek firmowy" name="is_company" class="mb-4">
            <USwitch v-model="form.is_company" />
          </UFormField>

          <div
            v-if="form.is_company"
            class="space-y-4 pl-4 border-l-2 border-primary-500"
          >
            <UFormField label="Odliczalność" name="deductible_override">
              <USelect
                v-model="deductibleOverrideSelect"
                :items="[
                  { label: 'Dziedzicz z kategorii', value: 'inherit' },
                  { label: 'Odliczalne', value: 'deductible' },
                  { label: 'Nieodliczalne', value: 'non-deductible' },
                ]"
              />
            </UFormField>

            <UFormField
              v-if="form.deductible_override !== false"
              label="Proporcja odliczenia (%)"
              name="deductible_ratio"
            >
              <UInput
                v-model="form.deductible_ratio_percent"
                type="number"
                min="0"
                max="100"
                step="1"
                placeholder="100"
              />
            </UFormField>
          </div>

          <UFormField label="Opłacone" name="is_paid" class="mt-4">
            <USwitch v-model="form.is_paid" />
          </UFormField>

          <UFormField
            v-if="form.is_paid"
            label="Data płatności"
            name="paid_at"
            class="mt-4"
          >
            <UInput v-model="form.paid_at" type="date" />
          </UFormField>
        </div>

        <!-- Note -->
        <div class="border-t border-gray-200 dark:border-gray-700 pt-6">
          <UFormField label="Notatka" name="note">
            <UTextarea
              v-model="form.note"
              placeholder="Dodatkowe informacje..."
              rows="3"
            />
          </UFormField>
        </div>

        <!-- Submit -->
        <div class="flex justify-end space-x-4 pt-6">
          <UButton
            color="neutral"
            variant="ghost"
            @click="$router.push('/wydatki')"
          >
            Anuluj
          </UButton>
          <UButton type="submit" :loading="saving"> Zapisz zmiany </UButton>
        </div>
      </form>
    </UCard>
  </div>
</template>

<script setup lang="ts">
import type { Database } from '~/types/database';

definePageMeta({
  middleware: 'auth',
});

type Expense = Database['public']['Tables']['expenses']['Row'];
type Category = Database['public']['Tables']['categories']['Row'];

const route = useRoute();
const supabase = useSupabaseClient<Database>();
const user = useSupabaseUser();
const router = useRouter();
const { fromNet, fromGross } = useVat();

const expenseId = route.params.id as string;

const expense = ref<Expense | null>(null);
const categories = ref<Category[]>([]);
const loading = ref(true);
const loadingCategories = ref(true);
const saving = ref(false);
const activeField = ref<'net' | 'gross'>('gross');

const form = reactive({
  title: '',
  note: '',
  counterparty: '',
  invoice_number: '',
  issue_date: '',
  due_date: '',
  vat_rate: 23,
  amount_net: null as number | null,
  amount_gross: null as number | null,
  vat_amount: 0,
  is_company: false,
  deductible_override: null as boolean | null,
  deductible_ratio_percent: null as number | null,
  is_paid: false,
  paid_at: '',
  category_ids: [] as string[],
});

const deductibleOverrideSelect = computed({
  get: () => {
    if (form.deductible_override === null) return 'inherit';
    if (form.deductible_override === true) return 'deductible';
    return 'non-deductible';
  },
  set: (value: string) => {
    if (value === 'inherit') form.deductible_override = null;
    else if (value === 'deductible') form.deductible_override = true;
    else form.deductible_override = false;
  },
});

const loadExpense = async () => {
  if (!user.value) return;

  loading.value = true;

  try {
    // Load expense
    const { data: expenseData, error: expenseError } = await supabase
      .from('expenses')
      .select('*')
      .eq('id', expenseId)
      .eq('user_id', user.value.sub)
      .single();

    if (expenseError) throw expenseError;

    expense.value = expenseData;

    // Load expense categories
    const { data: categoryData } = await supabase
      .from('expense_categories')
      .select('category_id')
      .eq('expense_id', expenseId);

    // Populate form
    form.title = expenseData.title;
    form.note = expenseData.note || '';
    form.counterparty = expenseData.counterparty || '';
    form.invoice_number = expenseData.invoice_number || '';
    form.issue_date = expenseData.issue_date;
    form.due_date = expenseData.due_date || '';
    form.vat_rate = expenseData.vat_rate;
    form.amount_net = expenseData.amount_net;
    form.amount_gross = expenseData.amount_gross;
    form.vat_amount = expenseData.vat_amount || 0;
    form.is_company = expenseData.is_company;
    form.deductible_override = expenseData.deductible_override;
    form.deductible_ratio_percent =
      expenseData.deductible_ratio !== null
        ? expenseData.deductible_ratio * 100
        : null;
    form.is_paid = expenseData.is_paid;
    form.paid_at = expenseData.paid_at || '';
    form.category_ids = (categoryData || []).map((c) => c.category_id);
  } catch (error) {
    console.error('Error loading expense:', error);
  } finally {
    loading.value = false;
  }
};

const loadCategories = async () => {
  if (!user.value) return;

  loadingCategories.value = true;
  const { data, error } = await supabase
    .from('categories')
    .select('*')
    .eq('user_id', user.value.sub)
    .order('name');

  if (error) {
    console.error('Error loading categories:', error);
  } else {
    categories.value = data || [];
  }
  loadingCategories.value = false;
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

const toggleCategory = (categoryId: string) => {
  const index = form.category_ids.indexOf(categoryId);
  if (index > -1) {
    form.category_ids.splice(index, 1);
  } else {
    form.category_ids.push(categoryId);
  }
};

const handleSubmit = async () => {
  if (!user.value || !expense.value) return;

  saving.value = true;

  try {
    // Update expense
    const { error: expenseError } = await supabase
      .from('expenses')
      .update({
        title: form.title,
        note: form.note || null,
        counterparty: form.counterparty || null,
        invoice_number: form.invoice_number || null,
        issue_date: form.issue_date,
        due_date: form.due_date || null,
        vat_rate: form.vat_rate === -1 ? 0 : form.vat_rate,
        amount_net: form.amount_net,
        amount_gross: form.amount_gross,
        is_company: form.is_company,
        deductible_override: form.deductible_override,
        deductible_ratio:
          form.deductible_ratio_percent !== null
            ? form.deductible_ratio_percent / 100
            : null,
        is_paid: form.is_paid,
        paid_at: form.paid_at || null,
      })
      .eq('id', expenseId);

    if (expenseError) throw expenseError;

    // Delete existing categories
    await supabase.from('expense_categories').delete().eq('expense_id', expenseId);

    // Insert new categories
    if (form.category_ids.length > 0) {
      const categoryInserts = form.category_ids.map((categoryId) => ({
        expense_id: expenseId,
        category_id: categoryId,
      }));

      const { error: categoryError } = await supabase
        .from('expense_categories')
        .insert(categoryInserts);

      if (categoryError) throw categoryError;
    }

    router.push('/wydatki');
  } catch (error) {
    console.error('Error updating expense:', error);
  } finally {
    saving.value = false;
  }
};

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
  loadExpense();
  loadCategories();
});
</script>
