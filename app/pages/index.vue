<template>
  <div>
    <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4 mb-6 sm:mb-8">
      <h1 class="text-2xl sm:text-3xl font-bold">Dashboard</h1>

      <!-- Month Selector -->
      <div class="flex items-center gap-2">
        <UButton
          icon="i-heroicons-chevron-left"
          color="neutral"
          variant="ghost"
          @click="previousMonth"
        />
        <div class="text-center min-w-[150px]">
          <div class="font-semibold">{{ currentMonthName }}</div>
          <div class="text-xs text-gray-500">{{ currentYear }}</div>
        </div>
        <UButton
          icon="i-heroicons-chevron-right"
          color="neutral"
          variant="ghost"
          @click="nextMonth"
        />
        <UButton
          color="neutral"
          variant="outline"
          @click="goToCurrentMonth"
          size="sm"
        >
          Dziś
        </UButton>
      </div>
    </div>

    <!-- Unpaid Loans Alert -->
    <UAlert
      v-if="unpaidLoans.length > 0"
      color="error"
      variant="subtle"
      class="mb-6"
      icon="i-heroicons-exclamation-triangle"
      title="Nieopłacone kredyty w tym miesiącu"
    >
      <template #description>
        <div class="space-y-1 mt-2">
          <div v-for="loan in unpaidLoans" :key="loan.id" class="text-sm">
            {{ loan.title }} - {{ formatCurrency(loan.monthly_amount) }}
          </div>
        </div>
      </template>
    </UAlert>

    <div v-if="loading" class="text-center py-8">
      <UCard>Ładowanie danych...</UCard>
    </div>

    <div v-else class="space-y-6">
      <!-- Calendar -->
      <UCard>
        <template #header>
          <h2 class="text-lg font-semibold">Kalendarz płatności</h2>
        </template>

        <div class="overflow-x-auto -mx-4 px-4 sm:mx-0 sm:px-0">
          <div class="grid grid-cols-7 gap-1 sm:gap-2 min-w-full">
          <!-- Header -->
          <div v-for="day in daysOfWeek" :key="day" class="text-center text-xs font-semibold text-gray-500 p-1 sm:p-2">
            {{ day }}
          </div>

          <!-- Days -->
          <div
            v-for="day in calendarDays"
            :key="day.date"
            class="min-h-[80px] sm:min-h-[100px] border border-gray-200 dark:border-gray-700 rounded p-1 sm:p-2 relative"
            :class="{
              'bg-gray-50 dark:bg-gray-800': !day.isCurrentMonth,
              'bg-primary-50 dark:bg-primary-900/20': day.isToday,
            }"
          >
            <div class="text-[10px] sm:text-xs font-semibold mb-0.5 sm:mb-1" :class="{ 'text-gray-400': !day.isCurrentMonth }">
              {{ day.dayNumber }}
            </div>
            <div class="space-y-0.5 sm:space-y-1">
              <div
                v-for="(payment, index) in getVisiblePayments(day)"
                :key="payment.id"
                class="text-[9px] sm:text-xs p-0.5 sm:p-1 rounded truncate"
                :class="{
                  'bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300': payment.type === 'expense' && payment.isPaid,
                  'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300': payment.type === 'expense' && !payment.isPaid,
                  'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300': payment.type === 'loan',
                  'bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300': payment.type === 'recurring',
                }"
                :title="payment.title + ' - ' + formatCurrency(payment.amount)"
              >
                {{ payment.title }}
              </div>

              <button
                v-if="hasMorePayments(day)"
                @click="toggleDayExpanded(day.date)"
                class="text-[9px] sm:text-xs text-primary-600 dark:text-primary-400 hover:underline w-full text-left p-0.5 sm:p-1"
              >
                {{ isDayExpanded(day.date)
                  ? 'Zwiń'
                  : `+${day.payments.length - maxVisiblePayments}`
                }}
              </button>
            </div>
          </div>
          </div>
        </div>

        <!-- Legend -->
        <div class="flex flex-wrap gap-4 mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
          <div class="flex items-center gap-2 text-xs">
            <div class="w-4 h-4 rounded bg-green-100 dark:bg-green-900/30"></div>
            <span>Opłacone</span>
          </div>
          <div class="flex items-center gap-2 text-xs">
            <div class="w-4 h-4 rounded bg-red-100 dark:bg-red-900/30"></div>
            <span>Nieopłacone</span>
          </div>
          <div class="flex items-center gap-2 text-xs">
            <div class="w-4 h-4 rounded bg-blue-100 dark:bg-blue-900/30"></div>
            <span>Kredyty</span>
          </div>
          <div class="flex items-center gap-2 text-xs">
            <div class="w-4 h-4 rounded bg-purple-100 dark:bg-purple-900/30"></div>
            <span>Cykliczne</span>
          </div>
        </div>
      </UCard>

      <!-- Charts Row -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Category Breakdown Chart -->
        <UCard>
          <template #header>
            <h2 class="text-lg font-semibold">Wydatki według kategorii</h2>
          </template>
          <div class="h-[300px] flex items-center justify-center">
            <canvas ref="categoryChartRef"></canvas>
          </div>
        </UCard>

        <!-- Tax Pie Chart -->
        <UCard>
          <template #header>
            <h2 class="text-lg font-semibold">Podział podatkowy</h2>
          </template>
          <div class="h-[300px] flex items-center justify-center">
            <canvas ref="taxChartRef"></canvas>
          </div>
        </UCard>
      </div>

      <!-- Combined Expenses Chart -->
      <UCard>
        <template #header>
          <h2 class="text-lg font-semibold">Wszystkie wydatki</h2>
        </template>
        <div class="h-[300px] flex items-center justify-center">
          <canvas ref="expensesChartRef"></canvas>
        </div>
      </UCard>

      <!-- Summary Stats -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <UCard>
          <div class="text-sm text-gray-500">Suma wydatków</div>
          <div class="text-2xl font-bold mt-1">{{ formatCurrency(totalExpenses) }}</div>
        </UCard>
        <UCard>
          <div class="text-sm text-gray-500">Suma przychodów</div>
          <div class="text-2xl font-bold mt-1">{{ formatCurrency(totalIncomes) }}</div>
        </UCard>
        <UCard>
          <div class="text-sm text-gray-500">Bilans</div>
          <div class="text-2xl font-bold mt-1" :class="balance >= 0 ? 'text-green-600' : 'text-red-600'">
            {{ formatCurrency(balance) }}
          </div>
        </UCard>
        <UCard>
          <div class="text-sm text-gray-500">Kredyty (miesiąc)</div>
          <div class="text-2xl font-bold mt-1">{{ formatCurrency(totalLoansMonth) }}</div>
        </UCard>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { Chart, registerables } from 'chart.js';
import type { Database } from '~/types/database';

Chart.register(...registerables);

definePageMeta({
  middleware: 'auth',
});

type Expense = Database['public']['Tables']['expenses']['Row'];
type Income = Database['public']['Tables']['incomes']['Row'];
type Loan = Database['public']['Tables']['loans']['Row'];
type RecurringExpense = Database['public']['Tables']['recurring_expenses']['Row'];
type Category = Database['public']['Tables']['categories']['Row'];

interface CalendarDay {
  date: string;
  dayNumber: number;
  isCurrentMonth: boolean;
  isToday: boolean;
  payments: Payment[];
}

interface Payment {
  id: string;
  title: string;
  amount: number;
  type: 'expense' | 'loan' | 'recurring';
  isPaid?: boolean;
}

const supabase = useSupabaseClient<Database>();
const user = useSupabaseUser();
const { formatCurrency: formatCurrencyFn } = useCurrency();

const loading = ref(true);
const currentDate = ref(new Date());
const expenses = ref<Expense[]>([]);
const incomes = ref<Income[]>([]);
const loans = ref<Loan[]>([]);
const recurringExpenses = ref<RecurringExpense[]>([]);
const categories = ref<Category[]>([]);
const expandedDays = ref<Set<string>>(new Set());
const maxVisiblePayments = 3;

const categoryChartRef = ref<HTMLCanvasElement | null>(null);
const taxChartRef = ref<HTMLCanvasElement | null>(null);
const expensesChartRef = ref<HTMLCanvasElement | null>(null);

let categoryChart: Chart | null = null;
let taxChart: Chart | null = null;
let expensesChart: Chart | null = null;

const daysOfWeek = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'So', 'Nd'];

const currentMonthName = computed(() => {
  return currentDate.value.toLocaleDateString('pl-PL', { month: 'long' });
});

const currentYear = computed(() => {
  return currentDate.value.getFullYear();
});

const currentMonth = computed(() => {
  return currentDate.value.getMonth();
});

const formatCurrency = (amount: number | null) => {
  return formatCurrencyFn(amount, 'PLN');
};

const previousMonth = () => {
  currentDate.value = new Date(currentDate.value.getFullYear(), currentDate.value.getMonth() - 1, 1);
  loadData();
};

const nextMonth = () => {
  currentDate.value = new Date(currentDate.value.getFullYear(), currentDate.value.getMonth() + 1, 1);
  loadData();
};

const goToCurrentMonth = () => {
  currentDate.value = new Date();
  loadData();
};

const getVisiblePayments = (day: CalendarDay) => {
  if (isDayExpanded(day.date) || day.payments.length <= maxVisiblePayments) {
    return day.payments;
  }
  return day.payments.slice(0, maxVisiblePayments);
};

const hasMorePayments = (day: CalendarDay) => {
  return day.payments.length > maxVisiblePayments;
};

const isDayExpanded = (date: string) => {
  return expandedDays.value.has(date);
};

const toggleDayExpanded = (date: string) => {
  if (expandedDays.value.has(date)) {
    expandedDays.value.delete(date);
  } else {
    expandedDays.value.add(date);
  }
};

const calendarDays = computed(() => {
  const year = currentDate.value.getFullYear();
  const month = currentDate.value.getMonth();

  const firstDay = new Date(year, month, 1);
  const lastDay = new Date(year, month + 1, 0);

  const firstDayOfWeek = firstDay.getDay() === 0 ? 6 : firstDay.getDay() - 1;

  const days: CalendarDay[] = [];

  // Previous month days
  const prevMonthLastDay = new Date(year, month, 0).getDate();
  for (let i = firstDayOfWeek - 1; i >= 0; i--) {
    const date = new Date(year, month - 1, prevMonthLastDay - i);
    days.push(createCalendarDay(date, false));
  }

  // Current month days
  for (let i = 1; i <= lastDay.getDate(); i++) {
    const date = new Date(year, month, i);
    days.push(createCalendarDay(date, true));
  }

  // Next month days
  const remainingDays = 42 - days.length; // 6 weeks
  for (let i = 1; i <= remainingDays; i++) {
    const date = new Date(year, month + 1, i);
    days.push(createCalendarDay(date, false));
  }

  return days;
});

const createCalendarDay = (date: Date, isCurrentMonth: boolean): CalendarDay => {
  const today = new Date();
  const isToday = date.toDateString() === today.toDateString();
  const dateStr = date.toISOString().split('T')[0];

  const payments: Payment[] = [];

  // Add expenses
  expenses.value.forEach(expense => {
    if (expense.issue_date === dateStr) {
      payments.push({
        id: expense.id,
        title: expense.title,
        amount: expense.amount_gross || 0,
        type: 'expense',
        isPaid: expense.is_paid,
      });
    }
  });

  // Add loans (if day matches)
  loans.value.forEach(loan => {
    const loanDate = new Date(loan.start_date);
    const dayOfMonth = loanDate.getDate();
    if (date.getDate() === dayOfMonth && date >= new Date(loan.start_date) && date <= new Date(loan.end_date)) {
      payments.push({
        id: loan.id,
        title: loan.title,
        amount: Number(loan.monthly_amount),
        type: 'loan',
      });
    }
  });

  return {
    date: dateStr,
    dayNumber: date.getDate(),
    isCurrentMonth,
    isToday,
    payments,
  };
};

const unpaidLoans = computed(() => {
  const year = currentDate.value.getFullYear();
  const month = currentDate.value.getMonth();

  return loans.value.filter(loan => {
    const startDate = new Date(loan.start_date);
    const endDate = new Date(loan.end_date);
    const currentMonth = new Date(year, month, 1);

    return currentMonth >= startDate && currentMonth <= endDate;
  });
});

const totalExpenses = computed(() => {
  return expenses.value.reduce((sum, exp) => sum + (exp.amount_gross_pln || exp.amount_gross || 0), 0);
});

const totalIncomes = computed(() => {
  return incomes.value.reduce((sum, inc) => sum + (inc.amount_gross_pln || inc.amount_gross || 0), 0);
});

const balance = computed(() => {
  return totalIncomes.value - totalExpenses.value;
});

const totalLoansMonth = computed(() => {
  return unpaidLoans.value.reduce((sum, loan) => sum + Number(loan.monthly_amount), 0);
});

const loadData = async () => {
  if (!user.value) return;

  loading.value = true;
  expandedDays.value.clear();

  const year = currentDate.value.getFullYear();
  const month = currentDate.value.getMonth();
  const firstDay = new Date(year, month, 1).toISOString().split('T')[0];
  const lastDay = new Date(year, month + 1, 0).toISOString().split('T')[0];

  // Load expenses
  const { data: expensesData } = await supabase
    .from('expenses')
    .select('*')
    .eq('user_id', user.value.sub)
    .gte('issue_date', firstDay)
    .lte('issue_date', lastDay)
    .order('issue_date', { ascending: true });

  expenses.value = expensesData || [];

  // Load incomes
  const { data: incomesData } = await supabase
    .from('incomes')
    .select('*')
    .eq('user_id', user.value.sub)
    .gte('issue_date', firstDay)
    .lte('issue_date', lastDay)
    .order('issue_date', { ascending: true });

  incomes.value = incomesData || [];

  // Load loans
  const { data: loansData } = await supabase
    .from('loans')
    .select('*')
    .eq('user_id', user.value.sub)
    .lte('start_date', lastDay)
    .gte('end_date', firstDay);

  loans.value = loansData || [];

  // Load categories
  const { data: categoriesData } = await supabase
    .from('categories')
    .select('*')
    .eq('user_id', user.value.sub);

  categories.value = categoriesData || [];

  loading.value = false;

  await nextTick();
  renderCharts();
};

const renderCharts = async () => {
  if (!user.value) return;

  // Destroy existing charts
  if (categoryChart) categoryChart.destroy();
  if (taxChart) taxChart.destroy();
  if (expensesChart) expensesChart.destroy();

  await nextTick();

  // Category Chart
  if (categoryChartRef.value) {
    const categoryData = await getCategoryData();
    categoryChart = new Chart(categoryChartRef.value, {
      type: 'doughnut',
      data: categoryData,
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom',
          },
        },
      },
    });
  }

  // Tax Chart
  if (taxChartRef.value) {
    const taxData = getTaxData();
    taxChart = new Chart(taxChartRef.value, {
      type: 'pie',
      data: taxData,
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom',
          },
        },
      },
    });
  }

  // Expenses Chart
  if (expensesChartRef.value) {
    const expensesData = getExpensesData();
    expensesChart = new Chart(expensesChartRef.value, {
      type: 'doughnut',
      data: expensesData,
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom',
          },
        },
      },
    });
  }
};

const getCategoryData = async () => {
  const categoryMap = new Map<string, number>();

  for (const expense of expenses.value) {
    const { data: expenseCategories } = await supabase
      .from('expense_categories')
      .select('category_id, categories(*)')
      .eq('expense_id', expense.id);

    if (expenseCategories && expenseCategories.length > 0) {
      expenseCategories.forEach(ec => {
        const cat = ec.categories as unknown as Category;
        if (cat) {
          const current = categoryMap.get(cat.name) || 0;
          categoryMap.set(cat.name, current + (expense.amount_gross_pln || expense.amount_gross || 0));
        }
      });
    } else {
      const current = categoryMap.get('Bez kategorii') || 0;
      categoryMap.set('Bez kategorii', current + (expense.amount_gross_pln || expense.amount_gross || 0));
    }
  }

  const labels = Array.from(categoryMap.keys());
  const data = Array.from(categoryMap.values());
  const colors = generateColors(labels.length);

  return {
    labels,
    datasets: [{
      data,
      backgroundColor: colors,
    }],
  };
};

const getTaxData = () => {
  const companyExpenses = expenses.value.filter(e => e.is_company).reduce((sum, e) => sum + (e.amount_gross_pln || e.amount_gross || 0), 0);
  const privateExpenses = expenses.value.filter(e => !e.is_company).reduce((sum, e) => sum + (e.amount_gross_pln || e.amount_gross || 0), 0);

  return {
    labels: ['Firmowe', 'Prywatne'],
    datasets: [{
      data: [companyExpenses, privateExpenses],
      backgroundColor: ['#3b82f6', '#6b7280'],
    }],
  };
};

const getExpensesData = () => {
  const regularExpenses = expenses.value.reduce((sum, e) => sum + (e.amount_gross_pln || e.amount_gross || 0), 0);
  const loansTotal = totalLoansMonth.value;

  return {
    labels: ['Wydatki bieżące', 'Kredyty'],
    datasets: [{
      data: [regularExpenses, loansTotal],
      backgroundColor: ['#ef4444', '#f59e0b'],
    }],
  };
};

const generateColors = (count: number) => {
  const colors = [
    '#3b82f6', '#ef4444', '#10b981', '#f59e0b', '#8b5cf6',
    '#ec4899', '#06b6d4', '#84cc16', '#f97316', '#6366f1',
  ];

  return Array.from({ length: count }, (_, i) => colors[i % colors.length]);
};

onMounted(() => {
  loadData();
});

onUnmounted(() => {
  if (categoryChart) categoryChart.destroy();
  if (taxChart) taxChart.destroy();
  if (expensesChart) expensesChart.destroy();
});
</script>
