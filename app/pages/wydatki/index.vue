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
        <UCard v-for="expense in filteredExpenses" :key="expense.id"
               :class="expense.isLoanInstallment ? 'ring-2 ring-blue-200 dark:ring-blue-800' : ''">
          <div class="space-y-3">
            <div class="flex justify-between items-start">
              <div class="flex-1">
                <div class="flex items-center gap-2">
                  <div class="font-medium text-base">{{ expense.title }}</div>
                  <UBadge
                    v-if="expense.isLoanInstallment"
                    color="info"
                    variant="subtle"
                    size="xs"
                  >
                    Kredyt
                  </UBadge>
                </div>
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
              <UDropdownMenu v-if="!expense.isLoanInstallment" :items="getDropdownItems(expense)">
                <UButton
                  color="neutral"
                  variant="ghost"
                  icon="i-heroicons-ellipsis-vertical"
                  size="sm"
                />
              </UDropdownMenu>
              <span v-else class="text-xs text-gray-400 italic">Tylko info</span>
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
                class="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Data
              </th>
              <th
                class="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Tytuł
              </th>
              <th
                class="px-3 py-2 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Kwota
              </th>
              <th
                class="px-3 py-2 text-center text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Status
              </th>
              <th
                class="px-3 py-2 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Akcje
              </th>
            </tr>
          </thead>
          <tbody
            class="bg-white dark:bg-gray-900 divide-y divide-gray-200 dark:divide-gray-700"
          >
            <tr v-for="expense in filteredExpenses" :key="expense.id"
                :class="[
                  'transition-colors',
                  expense.isLoanInstallment
                    ? 'bg-blue-50/50 dark:bg-blue-950/20'
                    : 'hover:bg-gray-50 dark:hover:bg-gray-800/50'
                ]">
              <td class="px-3 py-2 whitespace-nowrap text-sm text-gray-600 dark:text-gray-400">
                {{ formatDate(expense.issue_date) }}
              </td>
              <td class="px-3 py-2 text-sm">
                <div class="flex items-start gap-2">
                  <div class="flex-1 min-w-0">
                    <div class="flex items-center gap-2">
                      <div class="font-medium text-gray-900 dark:text-gray-100">{{ expense.title }}</div>
                      <UBadge
                        v-if="expense.isLoanInstallment"
                        color="info"
                        variant="subtle"
                        size="xs"
                      >
                        Kredyt
                      </UBadge>
                    </div>
                    <div class="flex items-center gap-2 mt-0.5">
                      <span
                        v-if="expense.counterparty"
                        class="text-gray-500 dark:text-gray-400 text-xs"
                      >
                        {{ expense.counterparty }}
                      </span>
                      <span
                        v-if="expense.invoice_number"
                        class="text-gray-500 dark:text-gray-400 text-xs"
                      >
                        • {{ expense.invoice_number }}
                      </span>
                    </div>
                    <div v-if="expense.categories.length > 0" class="flex flex-wrap gap-1 mt-1">
                      <UBadge
                        v-for="cat in expense.categories"
                        :key="cat.id"
                        color="neutral"
                        variant="subtle"
                        size="xs"
                      >
                        <div class="flex items-center gap-1">
                          <div
                            class="w-1.5 h-1.5 rounded-full"
                            :style="{ backgroundColor: cat.color || '#3b82f6' }"
                          />
                          {{ cat.name }}
                        </div>
                      </UBadge>
                    </div>
                  </div>
                </div>
              </td>
              <td
                class="px-3 py-2 whitespace-nowrap text-sm text-right"
              >
                <div class="font-semibold text-gray-900 dark:text-gray-100">{{ formatCurrency(expense.amount_gross, expense.currency_code || 'PLN') }}</div>
                <div
                  v-if="expense.currency_code !== 'PLN' && expense.amount_gross_pln"
                  class="text-xs text-gray-500 dark:text-gray-400"
                >
                  ≈ {{ formatCurrency(expense.amount_gross_pln, 'PLN') }}
                </div>
              </td>
              <td class="px-3 py-2 whitespace-nowrap text-sm">
                <div class="flex flex-col items-center gap-1">
                  <UBadge
                    :color="expense.is_paid ? 'success' : 'error'"
                    variant="subtle"
                    size="xs"
                  >
                    {{ expense.is_paid ? 'Opłacone' : 'Nieopłacone' }}
                  </UBadge>
                  <UBadge
                    :color="expense.is_company ? 'info' : 'neutral'"
                    variant="subtle"
                    size="xs"
                  >
                    {{ expense.is_company ? 'Firmowy' : 'Prywatny' }}
                  </UBadge>
                </div>
              </td>
              <td class="px-3 py-2 whitespace-nowrap text-right text-sm">
                <UDropdownMenu v-if="!expense.isLoanInstallment" :items="getDropdownItems(expense)">
                  <UButton
                    color="neutral"
                    variant="ghost"
                    icon="i-heroicons-ellipsis-vertical"
                    size="xs"
                  />
                </UDropdownMenu>
                <span v-else class="text-xs text-gray-400 italic">Tylko info</span>
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
type Loan = Database['public']['Tables']['loans']['Row'];

interface ExpenseWithCategories extends Expense {
  categories: Category[];
  isLoanInstallment?: boolean;
  loanId?: string;
}

const supabase = useSupabaseClient<Database>();
const user = useSupabaseUser();

const expenses = ref<Expense[]>([]);
const loans = ref<Loan[]>([]);
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

  // Load expenses
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

  // Load loans
  const { data: loansData, error: loansError } = await supabase
    .from('loans')
    .select('*')
    .eq('user_id', user.value.sub);

  if (loansError) {
    console.error('Error loading loans:', loansError);
  } else {
    loans.value = loansData || [];
  }

  loading.value = false;
};

const filteredExpenses = computed(() => {
  const filtered = expensesWithCategories.value.filter((expense) => {
    if (filters.value.dateFrom && expense.issue_date < filters.value.dateFrom) return false;
    if (filters.value.dateTo && expense.issue_date > filters.value.dateTo) return false;
    if (filters.value.paymentStatus === 'paid' && !expense.is_paid) return false;
    if (filters.value.paymentStatus === 'unpaid' && expense.is_paid) return false;
    if (filters.value.companyType === 'company' && !expense.is_company) return false;
    if (filters.value.companyType === 'private' && expense.is_company) return false;
    return true;
  });

  // Add active loan installments for the filtered date range
  const loanInstallments: ExpenseWithCategories[] = [];

  if (filters.value.dateFrom && filters.value.dateTo) {
    const fromDate = new Date(filters.value.dateFrom);
    const toDate = new Date(filters.value.dateTo);

    for (const loan of loans.value) {
      const loanStart = new Date(loan.start_date);
      const loanEnd = new Date(loan.end_date);

      // Check if loan is active during the filtered period
      if (loanStart <= toDate && loanEnd >= fromDate) {
        // Generate installment for the middle of the month range
        const installmentDate = new Date(fromDate.getFullYear(), fromDate.getMonth(), 15);
        const installmentDateStr = installmentDate.toISOString().split('T')[0];

        // Apply filters
        if (filters.value.companyType === 'company' && !loan.is_company) continue;
        if (filters.value.companyType === 'private' && loan.is_company) continue;

        loanInstallments.push({
          id: `loan-${loan.id}-${installmentDateStr}`,
          user_id: loan.user_id,
          title: `${loan.title} - Rata`,
          counterparty: loan.bank_name,
          invoice_number: null,
          amount_gross: loan.monthly_amount,
          amount_gross_pln: loan.monthly_amount,
          amount_net: null,
          amount_net_pln: null,
          vat_amount: null,
          vat_amount_pln: null,
          vat_rate: 0,
          currency_code: 'PLN',
          exchange_rate: null,
          issue_date: installmentDateStr,
          due_date: null,
          paid_at: null,
          is_paid: true, // Assume loans are paid
          is_company: loan.is_company,
          note: null,
          deductible_override: null,
          deductible_ratio: null,
          created_at: loan.created_at,
          updated_at: loan.updated_at,
          categories: [],
          isLoanInstallment: true,
          loanId: loan.id,
        });
      }
    }
  }

  // Combine and sort by date
  return [...filtered, ...loanInstallments].sort((a, b) =>
    b.issue_date.localeCompare(a.issue_date)
  );
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
