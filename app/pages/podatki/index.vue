<template>
  <div>
    <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4 mb-6 sm:mb-8">
      <h1 class="text-2xl sm:text-3xl font-bold">Podatki i zobowiązania</h1>
      <UButton color="neutral" variant="outline" to="/ustawienia" class="w-full sm:w-auto">
        Ustawienia podatkowe
      </UButton>
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
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
      <UCard v-if="userSettings?.vat_active">
        <div class="text-sm text-gray-500 mb-1">VAT do zapłaty</div>
        <div class="text-xl sm:text-2xl font-bold">
          {{ formatCurrency(calculatedTaxes.vat) }}
        </div>
        <div class="text-xs text-gray-500 mt-1">
          Termin: {{ getVATDeadline() }}
        </div>
      </UCard>
      <UCard>
        <div class="text-sm text-gray-500 mb-1">ZUS</div>
        <div class="text-xl sm:text-2xl font-bold">
          {{ formatCurrency(calculatedTaxes.zus) }}
        </div>
        <div class="text-xs text-gray-500 mt-1">
          Termin: {{ getZUSDeadline() }}
        </div>
      </UCard>
      <UCard>
        <div class="text-sm text-gray-500 mb-1">Podatek dochodowy</div>
        <div class="text-xl sm:text-2xl font-bold">
          {{ formatCurrency(calculatedTaxes.income_tax) }}
        </div>
        <div class="text-xs text-gray-500 mt-1">
          Termin: {{ getIncomeTaxDeadline() }}
        </div>
        <div class="text-xs text-gray-400 mt-1">
          {{ getTaxTypeLabel() }}
        </div>
      </UCard>
      <UCard>
        <div class="text-sm text-gray-500 mb-1">Suma zobowiązań</div>
        <div class="text-xl sm:text-2xl font-bold text-red-500">
          {{ formatCurrency(calculatedTaxes.total) }}
        </div>
        <div class="text-xs text-gray-500 mt-1">
          Za
          {{
            formatPeriod(
              selectedYear,
              selectedMonth || currentDate.getMonth() + 1
            )
          }}
        </div>
      </UCard>
    </div>

    <!-- Calculation Details -->
    <UCard class="mb-6">
      <template #header>
        <h3 class="text-base sm:text-lg font-semibold">Szczegóły obliczeń</h3>
      </template>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
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
          <h4 class="font-medium mb-2">ZUS</h4>
          <div class="space-y-1 text-sm">
            <div class="flex justify-between" v-if="zusDetails.social_base > 0">
              <span class="text-gray-500">Składki społeczne:</span>
              <span>{{ formatCurrency(zusDetails.social_total) }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-500">Składka zdrowotna:</span>
              <span>{{ formatCurrency(zusDetails.health) }}</span>
            </div>
            <div
              class="flex justify-between text-xs text-gray-400"
              v-if="userSettings?.zus_health_calculation === 'ryczalt'"
            >
              <span>Przychód roczny:</span>
              <span>{{ formatCurrency(zusDetails.yearly_income) }}</span>
            </div>
            <div class="flex justify-between font-medium pt-1 border-t">
              <span>Do zapłaty:</span>
              <span>{{ formatCurrency(calculatedTaxes.zus) }}</span>
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
            <div
              class="flex justify-between"
              v-if="!userSettings?.income_tax_scheme?.startsWith('ryczalt')"
            >
              <span class="text-gray-500">Koszty:</span>
              <span>{{ formatCurrency(calculationDetails.costs) }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-500">Podstawa opodatkowania:</span>
              <span>{{ formatCurrency(calculationDetails.tax_base) }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-500">Stawka:</span>
              <span
                >{{
                  extractTaxRate(
                    userSettings?.income_tax_scheme || 'ryczalt_12'
                  )
                }}%</span
              >
            </div>
            <div class="flex justify-between font-medium pt-1 border-t">
              <span>Do zapłaty:</span>
              <span>{{ formatCurrency(calculatedTaxes.income_tax) }}</span>
            </div>
          </div>
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
  for (
    let i = currentDate.getFullYear() - 2;
    i <= currentDate.getFullYear() + 1;
    i++
  ) {
    years.push({ label: i.toString(), value: i });
  }
  return years;
});

const incomes = ref<Income[]>([]);
const expenses = ref<Expense[]>([]);
const yearlyIncomes = ref<Income[]>([]);

const extractTaxRate = (taxScheme: string): number => {
  const match = taxScheme.match(/(\d+(?:_\d+)?)/);
  if (!match) return 12;
  return parseFloat(match[1].replace('_', '.'));
};

const calculateYearlyIncome = (): number => {
  // Suma przychodów za cały rok do wybranego miesiąca
  return yearlyIncomes.value.reduce(
    (sum, income) => sum + (income.amount_net || 0),
    0
  );
};

const zusDetails = computed(() => {
  const result = {
    social_base: 0,
    social_pension: 0,
    social_disability: 0,
    social_sickness: 0,
    social_accident: 0,
    social_total: 0,
    health: 0,
    health_base: 0,
    yearly_income: 0,
  };

  if (!userSettings.value) return result;

  // Składki społeczne (stałe miesięcznie)
  const socialBase = userSettings.value.zus_social_base || 0;
  result.social_base = socialBase;

  if (socialBase > 0) {
    result.social_pension = socialBase * 0.1952; // emerytalna
    result.social_disability = socialBase * 0.08; // rentowa
    result.social_sickness = socialBase * 0.0245; // chorobowa
    result.social_accident = socialBase * 0.0167; // wypadkowa
    result.social_total =
      result.social_pension +
      result.social_disability +
      result.social_sickness +
      result.social_accident;
  }

  // Składka zdrowotna
  const yearlyIncome = calculateYearlyIncome();
  result.yearly_income = yearlyIncome;

  if (userSettings.value.zus_health_calculation === 'fixed') {
    result.health = userSettings.value.zus_health_fixed || 0;
  } else if (userSettings.value.zus_health_calculation === 'ryczalt') {
    const averageWage = 8549.18; // 2025

    if (yearlyIncome <= 60000) {
      result.health_base = averageWage * 0.6;
      result.health = result.health_base * 0.09;
    } else if (yearlyIncome <= 300000) {
      result.health_base = averageWage * 1.0;
      result.health = result.health_base * 0.09;
    } else {
      result.health_base = averageWage * 1.8;
      result.health = result.health_base * 0.09;
    }
  }

  return result;
});

const calculateZUS = (): number => {
  return (
    Math.round(
      (zusDetails.value.social_total + zusDetails.value.health) * 100
    ) / 100
  );
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
  const isRyczalt =
    userSettings.value?.income_tax_scheme?.startsWith('ryczalt') ?? true;
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
    result.vat = Math.max(
      0,
      calculationDetails.value.vat_income - calculationDetails.value.vat_expense
    );
  }

  // ZUS calculation
  result.zus = calculateZUS();

  // Income tax
  const taxBase = calculationDetails.value.tax_base;
  const taxRate = extractTaxRate(
    userSettings.value.income_tax_scheme || 'ryczalt_12'
  );
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
    console.log('No settings found, creating defaults');
    // Create default settings
    const defaultSettings = {
      user_id: userId,
      income_tax_scheme: 'ryczalt_12',
      vat_active: true,
      default_vat_rate: 23,
      company_name: null,
      zus_social_base: null,
      zus_health_calculation: 'ryczalt',
      zus_health_fixed: null,
    };

    const { data: created, error: createError } = await supabase
      .from('company_settings')
      .insert(defaultSettings)
      .select()
      .single();

    if (createError) {
      console.error('Error creating settings:', createError);
      // Use defaults anyway
      userSettings.value = {
        ...defaultSettings,
        id: '',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      } as any;
    } else {
      userSettings.value = created;
    }
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

  // Load incomes for the month
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

  // Load yearly incomes (from start of year to selected month)
  const yearStartDate = `${year}-01-01`;
  const { data: yearlyIncomesData, error: yearlyIncomesError } = await supabase
    .from('incomes')
    .select('*')
    .eq('user_id', userId)
    .gte('issue_date', yearStartDate)
    .lt('issue_date', endDate);

  if (yearlyIncomesError) {
    console.error('Error loading yearly incomes:', yearlyIncomesError);
  } else {
    console.log('Loaded yearly incomes:', yearlyIncomesData?.length);
    yearlyIncomes.value = yearlyIncomesData || [];
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
  return `${nextMonth.toString().padStart(2, '0')}.${nextYear}`.replace(
    /^(\d+)\.(\d+)$/,
    '25.$1.$2'
  );
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

watch([selectedYear, selectedMonth], () => {
  loadData();
});

onMounted(async () => {
  await loadSettings();
  await loadData();
});
</script>
