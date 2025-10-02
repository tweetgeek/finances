<template>
  <div>
    <div class="flex justify-between items-center mb-8">
      <h1 class="text-3xl font-bold">Podatki i zobowiązania</h1>
      <div class="flex gap-2">
        <UButton
          color="neutral"
          variant="outline"
          to="/ustawienia"
        >
          Ustawienia podatkowe
        </UButton>
      </div>
    </div>

    <!-- Period selector -->
    <UCard class="mb-6">
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <UFormField label="Rok">
          <USelect
            v-model="selectedYear"
            :items="availableYears"
            @update:model-value="loadTaxes"
          />
        </UFormField>
        <UFormField label="Miesiąc">
          <USelect
            v-model="selectedMonth"
            :items="months"
            @update:model-value="loadTaxes"
          />
        </UFormField>
        <UFormField label="Typ">
          <USelect
            v-model="filters.type"
            placeholder="Wszystkie"
            :items="taxTypes"
          />
        </UFormField>
      </div>
    </UCard>

    <!-- Summary Cards -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
      <UCard v-if="userSettings?.vat_active">
        <div class="text-sm text-gray-500 mb-1">VAT do zapłaty</div>
        <div class="text-2xl font-bold">{{ formatCurrency(calculatedTaxes.vat) }}</div>
        <div class="text-xs text-gray-500 mt-1">
          Termin: {{ getVATDeadline() }}
        </div>
      </UCard>
      <UCard>
        <div class="text-sm text-gray-500 mb-1">ZUS</div>
        <div class="text-2xl font-bold">{{ formatCurrency(calculatedTaxes.zus) }}</div>
        <div class="text-xs text-gray-500 mt-1">
          Termin: {{ getZUSDeadline() }}
        </div>
      </UCard>
      <UCard>
        <div class="text-sm text-gray-500 mb-1">Podatek dochodowy</div>
        <div class="text-2xl font-bold">{{ formatCurrency(calculatedTaxes.income_tax) }}</div>
        <div class="text-xs text-gray-500 mt-1">
          Termin: {{ getIncomeTaxDeadline() }}
        </div>
        <div class="text-xs text-gray-400 mt-1">
          {{ getTaxTypeLabel() }}
        </div>
      </UCard>
      <UCard>
        <div class="text-sm text-gray-500 mb-1">Suma zobowiązań</div>
        <div class="text-2xl font-bold text-red-500">{{ formatCurrency(calculatedTaxes.total) }}</div>
        <div class="text-xs text-gray-500 mt-1">
          Za {{ formatPeriod(selectedYear, selectedMonth || currentDate.getMonth() + 1) }}
        </div>
      </UCard>
    </div>

    <!-- Calculation Details -->
    <UCard class="mb-6">
      <template #header>
        <h3 class="text-lg font-semibold">Szczegóły obliczeń</h3>
      </template>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div v-if="userSettings?.vat_active">
          <h4 class="font-medium mb-2">VAT</h4>
          <div class="space-y-1 text-sm">
            <div class="flex justify-between">
              <span class="text-gray-500">VAT należny (sprzedaż):</span>
              <span>{{ formatCurrency(calculationDetails.vat_income) }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-500">VAT naliczony (zakupy):</span>
              <span>{{ formatCurrency(calculationDetails.vat_expense) }}</span>
            </div>
            <div class="flex justify-between font-medium pt-1 border-t">
              <span>Do zapłaty:</span>
              <span>{{ formatCurrency(calculatedTaxes.vat) }}</span>
            </div>
          </div>
        </div>

        <div>
          <h4 class="font-medium mb-2">Podatek dochodowy</h4>
          <div class="space-y-1 text-sm">
            <div class="flex justify-between">
              <span class="text-gray-500">Przychód:</span>
              <span>{{ formatCurrency(calculationDetails.income) }}</span>
            </div>
            <div class="flex justify-between" v-if="!userSettings?.income_tax_scheme?.startsWith('ryczalt')">
              <span class="text-gray-500">Koszty:</span>
              <span>{{ formatCurrency(calculationDetails.costs) }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-500">Podstawa opodatkowania:</span>
              <span>{{ formatCurrency(calculationDetails.tax_base) }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-500">Stawka:</span>
              <span>{{ extractTaxRate(userSettings?.income_tax_scheme || 'ryczalt_12') }}%</span>
            </div>
            <div class="flex justify-between font-medium pt-1 border-t">
              <span>Do zapłaty:</span>
              <span>{{ formatCurrency(calculatedTaxes.income_tax) }}</span>
            </div>
          </div>
        </div>
      </div>
    </UCard>

    <UCard v-if="loading" class="text-center"> Ładowanie... </UCard>

    <UCard v-else-if="filteredTaxes.length === 0">
      <div class="text-center text-gray-500">
        Brak zobowiązań w tym okresie. Dodaj pierwsze zobowiązanie.
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
                Typ
              </th>
              <th
                class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Okres
              </th>
              <th
                class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Termin płatności
              </th>
              <th
                class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Kwota
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
            <tr v-if="userSettings?.vat_active && calculatedTaxes.vat > 0">
              <td class="px-6 py-4 whitespace-nowrap text-sm">
                <UBadge color="primary" variant="subtle">VAT</UBadge>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm">
                {{ formatPeriod(selectedYear, selectedMonth || currentDate.getMonth() + 1) }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm">
                {{ getVATDeadline() }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-right font-medium">
                {{ formatCurrency(calculatedTaxes.vat) }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-center">
                <UBadge color="warning" variant="subtle">
                  Do zapłaty
                </UBadge>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right text-sm">
                -
              </td>
            </tr>
            <tr v-if="calculatedTaxes.zus > 0">
              <td class="px-6 py-4 whitespace-nowrap text-sm">
                <UBadge color="info" variant="subtle">ZUS</UBadge>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm">
                {{ formatPeriod(selectedYear, selectedMonth || currentDate.getMonth() + 1) }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm">
                {{ getZUSDeadline() }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-right font-medium">
                {{ formatCurrency(calculatedTaxes.zus) }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-center">
                <UBadge color="warning" variant="subtle">
                  Do zapłaty
                </UBadge>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right text-sm">
                -
              </td>
            </tr>
            <tr v-if="calculatedTaxes.income_tax > 0">
              <td class="px-6 py-4 whitespace-nowrap text-sm">
                <UBadge color="warning" variant="subtle">Podatek dochodowy</UBadge>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm">
                {{ formatPeriod(selectedYear, selectedMonth || currentDate.getMonth() + 1) }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm">
                {{ getIncomeTaxDeadline() }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-right font-medium">
                {{ formatCurrency(calculatedTaxes.income_tax) }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-center">
                <UBadge color="warning" variant="subtle">
                  Do zapłaty
                </UBadge>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right text-sm">
                -
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Summary -->
      <div class="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
        <div class="flex justify-between items-center text-sm">
          <span class="text-gray-500">Suma zobowiązań za okres</span>
          <span class="font-bold text-lg text-red-500">
            {{ formatCurrency(calculatedTaxes.total) }}
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

type CompanySettings = Database['public']['Tables']['company_settings']['Row'];
type Income = Database['public']['Tables']['incomes']['Row'];
type Expense = Database['public']['Tables']['expenses']['Row'];

const supabase = useSupabaseClient<Database>();
const user = useSupabaseUser();

const loading = ref(true);
const userSettings = ref<CompanySettings | null>(null);

const currentDate = new Date();
const selectedYear = ref(currentDate.getFullYear());
const selectedMonth = ref<number | null>(currentDate.getMonth() + 1);

const filters = reactive({
  type: null as string | null,
});

const months = [
  { label: 'Styczeń', value: 1 },
  { label: 'Luty', value: 2 },
  { label: 'Marzec', value: 3 },
  { label: 'Kwiecień', value: 4 },
  { label: 'Maj', value: 5 },
  { label: 'Czerwiec', value: 6 },
  { label: 'Lipiec', value: 7 },
  { label: 'Sierpień', value: 8 },
  { label: 'Wrzesień', value: 9 },
  { label: 'Październik', value: 10 },
  { label: 'Listopad', value: 11 },
  { label: 'Grudzień', value: 12 },
];

const availableYears = computed(() => {
  const years = [];
  for (let i = currentDate.getFullYear() - 2; i <= currentDate.getFullYear() + 1; i++) {
    years.push({ label: i.toString(), value: i });
  }
  return years;
});

const incomes = ref<Income[]>([]);
const expenses = ref<Expense[]>([]);

const extractTaxRate = (taxScheme: string): number => {
  const match = taxScheme.match(/(\d+(?:_\d+)?)/);
  if (!match) return 12;
  return parseFloat(match[1].replace('_', '.'));
};

const calculationDetails = computed(() => {
  const result = {
    income: 0,
    costs: 0,
    tax_base: 0,
    vat_income: 0,
    vat_expense: 0,
  };

  // Sum incomes
  incomes.value.forEach((income) => {
    result.income += income.amount_net || 0;
    result.vat_income += income.vat_amount || 0;
  });

  // Sum expenses (only company expenses for costs)
  expenses.value.forEach((expense) => {
    if (expense.is_company) {
      result.costs += expense.amount_net || 0;
    }
    if (userSettings.value?.vat_active) {
      result.vat_expense += expense.vat_amount || 0;
    }
  });

  // Calculate tax base
  const isRyczalt = userSettings.value?.income_tax_scheme?.startsWith('ryczalt') ?? true;
  if (isRyczalt) {
    result.tax_base = result.income;
  } else {
    result.tax_base = result.income - result.costs;
  }

  return result;
});

const calculatedTaxes = computed(() => {
  const result = {
    vat: 0,
    zus: 0,
    income_tax: 0,
    total: 0,
  };

  if (!userSettings.value) return result;

  // VAT calculation
  if (userSettings.value.vat_active) {
    result.vat = Math.max(0, calculationDetails.value.vat_income - calculationDetails.value.vat_expense);
  }

  // ZUS - hardcoded for now, TODO: make configurable
  result.zus = 0;

  // Income tax
  const taxBase = calculationDetails.value.tax_base;
  const taxRate = extractTaxRate(userSettings.value.income_tax_scheme || 'ryczalt_12');
  result.income_tax = Math.max(0, (taxBase * taxRate) / 100);

  // Total
  result.total = result.vat + result.zus + result.income_tax;

  return result;
});

const loadSettings = async () => {
  if (!user.value) return;

  const userId = user.value.id || user.value.sub;
  console.log('Loading settings for user:', userId);

  const { data, error } = await supabase
    .from('company_settings')
    .select('*')
    .eq('user_id', userId)
    .single();

  if (error && error.code !== 'PGRST116') {
    console.error('Error loading settings:', error);
  } else if (data) {
    console.log('Settings loaded:', data);
    userSettings.value = data;
  } else {
    console.log('No settings found, using defaults');
    // Default settings
    userSettings.value = {
      id: '',
      user_id: userId,
      income_tax_scheme: 'ryczalt_12',
      vat_active: true,
      default_vat_rate: 23,
      company_name: null,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
  }
};

const loadData = async () => {
  if (!user.value) return;

  loading.value = true;

  const userId = user.value.id || user.value.sub;
  const month = selectedMonth.value || currentDate.getMonth() + 1;
  const year = selectedYear.value;

  const startDate = `${year}-${month.toString().padStart(2, '0')}-01`;
  const endDate =
    month === 12
      ? `${year + 1}-01-01`
      : `${year}-${(month + 1).toString().padStart(2, '0')}-01`;

  console.log('Loading data for period:', startDate, 'to', endDate);

  // Load incomes
  const { data: incomesData, error: incomesError } = await supabase
    .from('incomes')
    .select('*')
    .eq('user_id', userId)
    .gte('issue_date', startDate)
    .lt('issue_date', endDate);

  if (incomesError) {
    console.error('Error loading incomes:', incomesError);
  } else {
    console.log('Loaded incomes:', incomesData?.length);
    incomes.value = incomesData || [];
  }

  // Load expenses
  const { data: expensesData, error: expensesError } = await supabase
    .from('expenses')
    .select('*')
    .eq('user_id', userId)
    .gte('issue_date', startDate)
    .lt('issue_date', endDate);

  if (expensesError) {
    console.error('Error loading expenses:', expensesError);
  } else {
    console.log('Loaded expenses:', expensesData?.length);
    expenses.value = expensesData || [];
  }

  loading.value = false;
};

const formatDate = (date: string) => {
  return new Date(date).toLocaleDateString('pl-PL');
};

const formatPeriod = (year: number, month: number) => {
  const monthLabel = months.find((m) => m.value === month)?.label || month;
  return `${monthLabel} ${year}`;
};

const formatCurrency = (amount: number | null) => {
  if (amount === null) return '-';
  return new Intl.NumberFormat('pl-PL', {
    style: 'currency',
    currency: 'PLN',
  }).format(amount);
};

const getVATDeadline = () => {
  const month = selectedMonth.value || currentDate.getMonth() + 1;
  const year = selectedYear.value;
  const nextMonth = month === 12 ? 1 : month + 1;
  const nextYear = month === 12 ? year + 1 : year;
  return `${nextMonth.toString().padStart(2, '0')}.${nextYear}`.replace(/^(\d+)\.(\d+)$/, '25.$1.$2');
};

const getZUSDeadline = () => {
  const month = selectedMonth.value || currentDate.getMonth() + 1;
  const year = selectedYear.value;
  const nextMonth = month === 12 ? 1 : month + 1;
  const nextYear = month === 12 ? year + 1 : year;
  return `20.${nextMonth.toString().padStart(2, '0')}.${nextYear}`;
};

const getIncomeTaxDeadline = () => {
  const month = selectedMonth.value || currentDate.getMonth() + 1;
  const year = selectedYear.value;
  const nextMonth = month === 12 ? 1 : month + 1;
  const nextYear = month === 12 ? year + 1 : year;
  return `20.${nextMonth.toString().padStart(2, '0')}.${nextYear}`;
};

const getTaxTypeLabel = () => {
  if (!userSettings.value) return '';

  const scheme = userSettings.value.income_tax_scheme || 'ryczalt_12';
  const rate = extractTaxRate(scheme);

  if (scheme.startsWith('ryczalt')) {
    return `Ryczałt ${rate}%`;
  } else if (scheme.startsWith('liniowy')) {
    return 'Podatek liniowy 19%';
  } else if (scheme === 'skala') {
    return 'Skala podatkowa';
  }
  return '';
};

const filteredTaxes = computed(() => {
  return [];
});

watch([selectedYear, selectedMonth], () => {
  loadData();
});

onMounted(async () => {
  await loadSettings();
  await loadData();
});
</script>
