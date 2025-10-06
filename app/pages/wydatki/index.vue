<template>
  <div>
    <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4 mb-6 sm:mb-8">
      <h1 class="text-2xl sm:text-3xl font-bold">Wydatki</h1>
      <UButton @click="$router.push('/wydatki/nowy')" class="w-full sm:w-auto">
        Dodaj wydatek
      </UButton>
    </div>

    <!-- Filters -->
    <UCard class="mb-6">
      <div class="flex justify-between items-center mb-4">
        <h3 class="text-sm font-medium text-gray-700 dark:text-gray-300">Filtry</h3>
        <UButton
          color="neutral"
          variant="ghost"
          size="xs"
          icon="i-heroicons-x-mark"
          @click="clearFilters"
        >
          Wyczyść filtry
        </UButton>
      </div>
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <UFormField label="Od daty">
          <UInput v-model="filters.dateFrom" type="date" />
        </UFormField>
        <UFormField label="Do daty">
          <UInput v-model="filters.dateTo" type="date" />
        </UFormField>
        <UFormField label="Status płatności">
          <USelect
            v-model="filters.paymentStatus"
            placeholder="Wszystkie"
            :items="[
              { label: 'Opłacone', value: 'paid' },
              { label: 'Nieopłacone', value: 'unpaid' },
            ]"
          />
        </UFormField>
        <UFormField label="Typ">
          <USelect
            v-model="filters.companyType"
            placeholder="Wszystkie"
            :items="[
              { label: 'Firmowe', value: 'company' },
              { label: 'Prywatne', value: 'private' },
            ]"
          />
        </UFormField>
      </div>
    </UCard>

    <UCard v-if="loading" class="text-center"> Ładowanie... </UCard>

    <UCard v-else-if="filteredExpenses.length === 0">
      <div class="text-center text-gray-500">
        Brak wydatków. Dodaj pierwszy wydatek.
      </div>
    </UCard>

    <UCard v-else>
      <!-- Mobile view - Cards -->
      <div class="md:hidden space-y-4">
        <UCard v-for="expense in filteredExpenses" :key="expense.id">
          <div class="space-y-3">
            <div class="flex justify-between items-start">
              <div class="flex-1">
                <div class="font-medium text-base">{{ expense.title }}</div>
                <div class="text-xs text-gray-500 mt-0.5">
                  {{ formatDate(expense.issue_date) }}
                </div>
                <div
                  v-if="expense.counterparty"
                  class="text-xs text-gray-500 mt-0.5"
                >
                  {{ expense.counterparty }}
                </div>
                <div
                  v-if="expense.invoice_number"
                  class="text-xs text-gray-500 mt-0.5"
                >
                  {{ expense.invoice_number }}
                </div>
              </div>
              <UDropdownMenu :items="getDropdownItems(expense)">
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
                {{ formatCurrency(expense.amount_gross, expense.currency_code || 'PLN') }}
              </span>
              <div class="flex gap-2">
                <UBadge
                  :color="expense.is_company ? 'info' : 'neutral'"
                  variant="subtle"
                  size="sm"
                >
                  {{ expense.is_company ? 'Firmowy' : 'Prywatny' }}
                </UBadge>
                <UBadge
                  :color="expense.is_paid ? 'success' : 'error'"
                  variant="subtle"
                  size="sm"
                >
                  {{ expense.is_paid ? 'Opłacone' : 'Nieopłacone' }}
                </UBadge>
              </div>
            </div>

            <div
              v-if="expense.currency_code !== 'PLN' && expense.amount_gross_pln"
              class="text-xs text-gray-500"
            >
              ≈ {{ formatCurrency(expense.amount_gross_pln, 'PLN') }}
            </div>

            <div v-if="expense.categories.length > 0" class="flex flex-wrap gap-1">
              <UBadge
                v-for="cat in expense.categories"
                :key="cat.id"
                color="neutral"
                variant="subtle"
                size="xs"
              >
                <div class="flex items-center gap-1">
                  <div
                    class="w-2 h-2 rounded-full"
                    :style="{ backgroundColor: cat.color || '#3b82f6' }"
                  />
                  {{ cat.name }}
                </div>
              </UBadge>
            </div>
          </div>
        </UCard>
      </div>

      <!-- Desktop view - Table -->
      <div class="hidden md:block overflow-x-auto -mx-6 px-6">
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
                class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Kwota brutto
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
            <tr v-for="expense in filteredExpenses" :key="expense.id">
              <td class="px-6 py-4 whitespace-nowrap text-sm">
                {{ formatDate(expense.issue_date) }}
              </td>
              <td class="px-6 py-4 text-sm">
                <div class="font-medium">{{ expense.title }}</div>
                <div
                  v-if="expense.counterparty"
                  class="text-gray-500 text-xs mt-0.5"
                >
                  {{ expense.counterparty }}
                </div>
                <div
                  v-if="expense.invoice_number"
                  class="text-gray-500 text-xs mt-0.5"
                >
                  {{ expense.invoice_number }}
                </div>
                <div v-if="expense.categories.length > 0" class="flex flex-wrap gap-1 mt-1.5">
                  <UBadge
                    v-for="cat in expense.categories"
                    :key="cat.id"
                    color="neutral"
                    variant="subtle"
                    size="xs"
                  >
                    <div class="flex items-center gap-1">
                      <div
                        class="w-2 h-2 rounded-full"
                        :style="{ backgroundColor: cat.color || '#3b82f6' }"
                      />
                      {{ cat.name }}
                    </div>
                  </UBadge>
                </div>
              </td>
              <td
                class="px-6 py-4 whitespace-nowrap text-sm text-right font-medium"
              >
                <div>{{ formatCurrency(expense.amount_gross, expense.currency_code || 'PLN') }}</div>
                <div
                  v-if="expense.currency_code !== 'PLN' && expense.amount_gross_pln"
                  class="text-xs text-gray-500"
                >
                  ≈ {{ formatCurrency(expense.amount_gross_pln, 'PLN') }}
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-center">
                <UBadge
                  :color="expense.is_company ? 'info' : 'neutral'"
                  variant="subtle"
                >
                  {{ expense.is_company ? 'Firmowy' : 'Prywatny' }}
                </UBadge>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-center">
                <UBadge
                  :color="expense.is_paid ? 'success' : 'error'"
                  variant="subtle"
                >
                  {{ expense.is_paid ? 'Opłacone' : 'Nieopłacone' }}
                </UBadge>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right text-sm">
                <UDropdownMenu :items="getDropdownItems(expense)">
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
        <div class="flex justify-between items-center text-sm">
          <span class="text-gray-500"
            >Suma ({{ filteredExpenses.length }} pozycji)</span
          >
          <span class="font-bold text-lg">
            {{ formatCurrency(totalAmount) }}
          </span>
        </div>
      </div>
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

interface ExpenseWithCategories extends Expense {
  categories: Category[];
}

const supabase = useSupabaseClient<Database>();
const user = useSupabaseUser();

const expenses = ref<Expense[]>([]);
const expensesWithCategories = ref<ExpenseWithCategories[]>([]);
const loading = ref(true);

// Use filter persistence
const now = new Date();
const firstDay = new Date(now.getFullYear(), now.getMonth(), 1);
const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0);

const { filters: persistedFilters, clearFilters } = useFilterPersistence('wydatki', {
  dateFrom: firstDay.toISOString().split('T')[0],
  dateTo: lastDay.toISOString().split('T')[0],
  paymentStatus: null as string | null,
  companyType: null as string | null,
});

const filters = persistedFilters;

const loadExpenses = async () => {
  if (!user.value) return;

  loading.value = true;
  const { data, error } = await supabase
    .from('expenses')
    .select('*')
    .eq('user_id', user.value.sub)
    .order('issue_date', { ascending: false });

  if (error) {
    console.error('Error loading expenses:', error);
  } else {
    expenses.value = data || [];

    // Load categories for each expense
    const withCategories: ExpenseWithCategories[] = [];
    for (const expense of data || []) {
      const { data: cats } = await supabase
        .from('expense_categories')
        .select('category_id, categories(*)')
        .eq('expense_id', expense.id);

      withCategories.push({
        ...expense,
        categories: (cats || []).map((c) => c.categories).filter(Boolean) as Category[],
      });
    }
    expensesWithCategories.value = withCategories;
  }
  loading.value = false;
};

const filteredExpenses = computed(() => {
  return expensesWithCategories.value.filter((expense) => {
    if (filters.dateFrom && expense.issue_date < filters.dateFrom) return false;
    if (filters.dateTo && expense.issue_date > filters.dateTo) return false;
    if (filters.paymentStatus === 'paid' && !expense.is_paid) return false;
    if (filters.paymentStatus === 'unpaid' && expense.is_paid) return false;
    if (filters.companyType === 'company' && !expense.is_company) return false;
    if (filters.companyType === 'private' && expense.is_company) return false;
    return true;
  });
});

const totalAmount = computed(() => {
  return filteredExpenses.value.reduce(
    (sum, expense) => sum + (expense.amount_gross_pln || expense.amount_gross || 0),
    0
  );
});

const formatDate = (date: string) => {
  return new Date(date).toLocaleDateString('pl-PL');
};

const { formatCurrency: formatCurrencyFn } = useCurrency();

const formatCurrency = (amount: number | null, currencyCode: string = 'PLN') => {
  return formatCurrencyFn(amount, currencyCode);
};

const deleteExpense = async (expense: Expense) => {
  if (!confirm(`Czy na pewno chcesz usunąć wydatek "${expense.title}"?`)) {
    return;
  }

  const { error } = await supabase
    .from('expenses')
    .delete()
    .eq('id', expense.id);

  if (error) {
    console.error('Error deleting expense:', error);
  } else {
    await loadExpenses();
  }
};

const togglePaid = async (expense: Expense) => {
  const { error } = await supabase
    .from('expenses')
    .update({
      is_paid: !expense.is_paid,
      paid_at: !expense.is_paid ? new Date().toISOString().split('T')[0] : null,
    })
    .eq('id', expense.id);

  if (error) {
    console.error('Error updating expense:', error);
  } else {
    await loadExpenses();
  }
};

const getDropdownItems = (expense: Expense) => [
  [
    {
      label: expense.is_paid
        ? 'Oznacz jako nieopłacone'
        : 'Oznacz jako opłacone',
      icon: expense.is_paid
        ? 'i-heroicons-x-circle'
        : 'i-heroicons-check-circle',
      onSelect: () => togglePaid(expense),
    },
    {
      label: 'Edytuj',
      icon: 'i-heroicons-pencil-square',
      to: `/wydatki/${expense.id}`,
    },
    {
      label: 'Usuń',
      icon: 'i-heroicons-trash',
      onSelect: () => deleteExpense(expense),
    },
  ],
];

onMounted(() => {
  loadExpenses();
});
</script>
