<template>
  <div>
    <div class="mb-6 sm:mb-8">
      <UButton
        variant="ghost"
        icon="i-heroicons-arrow-left"
        @click="$router.push('/wydatki')"
        size="sm"
        class="sm:size-md"
      >
        Powrót
      </UButton>
      <h1 class="text-2xl sm:text-3xl font-bold mt-4">Dodaj wydatek</h1>
    </div>

    <UCard class="max-h-[calc(100vh-8rem)] overflow-y-auto overscroll-contain">
      <form class="space-y-4 sm:space-y-6" @submit.prevent="handleSubmit">
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 sm:gap-6">
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

          <UFormField label="Waluta" name="currency_code" required>
            <USelect
              v-model="form.currency_code"
              :items="availableCurrencies"
              @update:model-value="onCurrencyChange"
            />
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
        <div class="border-t border-gray-200 dark:border-gray-700 pt-4 sm:pt-6">
          <h3 class="text-base sm:text-lg font-semibold mb-3 sm:mb-4">Kwoty</h3>

          <!-- Exchange Rate Info -->
          <div v-if="form.currency_code !== 'PLN' && exchangeRate" class="mb-4 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
            <div class="text-xs sm:text-sm">
              <span class="font-medium">Kurs {{ form.currency_code }}/PLN:</span>
              <span class="ml-2">{{ exchangeRate.toFixed(4) }}</span>
              <span class="block sm:inline sm:ml-2 text-gray-500">(z dnia {{ form.issue_date }})</span>
            </div>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            <UFormField :label="`Kwota netto (${form.currency_code})`" name="amount_net">
              <UInput
                v-model="form.amount_net"
                type="number"
                step="0.01"
                placeholder="0.00"
                @input="calculateFromNet"
                @focus="activeField = 'net'"
              />
              <template v-if="form.currency_code !== 'PLN' && amountNetPLN" #hint>
                <span class="text-xs text-gray-500">≈ {{ formatCurrency(amountNetPLN, 'PLN') }}</span>
              </template>
            </UFormField>

            <UFormField :label="`Kwota brutto (${form.currency_code})`" name="amount_gross">
              <UInput
                v-model="form.amount_gross"
                type="number"
                step="0.01"
                placeholder="0.00"
                @input="calculateFromGross"
                @focus="activeField = 'gross'"
              />
              <template v-if="form.currency_code !== 'PLN' && amountGrossPLN" #hint>
                <span class="text-xs text-gray-500">≈ {{ formatCurrency(amountGrossPLN, 'PLN') }}</span>
              </template>
            </UFormField>

            <UFormField :label="`VAT (${form.currency_code})`" name="vat_amount">
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
              :rows="3"
            />
          </UFormField>
        </div>

        <!-- Submit -->
        <div class="flex flex-col sm:flex-row justify-end gap-2 sm:space-x-4 pt-6 sticky bottom-0 bg-white dark:bg-gray-900 -mx-6 px-6 pb-6">
          <UButton
            color="neutral"
            variant="ghost"
            @click="$router.push('/wydatki')"
            class="w-full sm:w-auto"
          >
            Anuluj
          </UButton>
          <UButton type="submit" :loading="saving" class="w-full sm:w-auto"> Zapisz wydatek </UButton>
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

type Category = Database['public']['Tables']['categories']['Row'];

const supabase = useSupabaseClient<Database>();
const user = useSupabaseUser();
const router = useRouter();
const { fromNet, fromGross } = useVat();
const { getExchangeRate, convertToPLN, formatCurrency: formatCurrencyFn, availableCurrencies } = useCurrency();

const categories = ref<Category[]>([]);
const loadingCategories = ref(true);
const saving = ref(false);
const activeField = ref<'net' | 'gross'>('gross');
const exchangeRate = ref<number | null>(null);
const amountNetPLN = ref<number | null>(null);
const amountGrossPLN = ref<number | null>(null);
const vatAmountPLN = ref<number | null>(null);

const form = reactive({
  title: '',
  note: '',
  counterparty: '',
  invoice_number: '',
  issue_date: new Date().toISOString().split('T')[0],
  due_date: '',
  currency_code: 'PLN',
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

const formatCurrency = (amount: number | null, currency: string = form.currency_code) => {
  return formatCurrencyFn(amount, currency);
};

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

const updatePLNAmounts = async () => {
  if (form.currency_code === 'PLN' || !form.issue_date) {
    amountNetPLN.value = form.amount_net;
    amountGrossPLN.value = form.amount_gross;
    vatAmountPLN.value = form.vat_amount;
    exchangeRate.value = 1;
    return;
  }

  try {
    const rate = await getExchangeRate(form.currency_code, form.issue_date);
    exchangeRate.value = rate;

    if (form.amount_net) {
      amountNetPLN.value = Math.round(form.amount_net * rate * 100) / 100;
    }
    if (form.amount_gross) {
      amountGrossPLN.value = Math.round(form.amount_gross * rate * 100) / 100;
    }
    if (form.vat_amount) {
      vatAmountPLN.value = Math.round(form.vat_amount * rate * 100) / 100;
    }
  } catch (error) {
    console.error('Error updating PLN amounts:', error);
  }
};

const onCurrencyChange = () => {
  updatePLNAmounts();
};

const calculateFromNet = () => {
  if (activeField.value !== 'net') return;
  if (form.amount_net === null || form.amount_net === 0) {
    form.amount_gross = null;
    form.vat_amount = 0;
    updatePLNAmounts();
    return;
  }

  const result = fromNet(
    form.amount_net,
    form.vat_rate === -1 ? 0 : form.vat_rate
  );
  form.amount_gross = result.gross;
  form.vat_amount = result.vat;
  updatePLNAmounts();
};

const calculateFromGross = () => {
  if (activeField.value !== 'gross') return;
  if (form.amount_gross === null || form.amount_gross === 0) {
    form.amount_net = null;
    form.vat_amount = 0;
    updatePLNAmounts();
    return;
  }

  const result = fromGross(
    form.amount_gross,
    form.vat_rate === -1 ? 0 : form.vat_rate
  );
  form.amount_net = result.net;
  form.vat_amount = result.vat;
  updatePLNAmounts();
};

watch(() => form.issue_date, () => {
  if (form.currency_code !== 'PLN') {
    updatePLNAmounts();
  }
});

const toggleCategory = (categoryId: string) => {
  const index = form.category_ids.indexOf(categoryId);
  if (index > -1) {
    form.category_ids.splice(index, 1);
  } else {
    form.category_ids.push(categoryId);
  }
};

const handleSubmit = async () => {
  if (!user.value) return;

  saving.value = true;

  try {
    // Insert expense
    const { data: expense, error: expenseError } = await supabase
      .from('expenses')
      .insert({
        user_id: user.value.sub,
        title: form.title,
        note: form.note || null,
        counterparty: form.counterparty || null,
        invoice_number: form.invoice_number || null,
        issue_date: form.issue_date,
        due_date: form.due_date || null,
        currency_code: form.currency_code,
        vat_rate: form.vat_rate === -1 ? 0 : form.vat_rate,
        amount_net: form.amount_net,
        amount_gross: form.amount_gross,
        exchange_rate: exchangeRate.value || 1,
        amount_net_pln: amountNetPLN.value,
        amount_gross_pln: amountGrossPLN.value,
        vat_amount_pln: vatAmountPLN.value,
        is_company: form.is_company,
        deductible_override: form.deductible_override,
        deductible_ratio:
          form.deductible_ratio_percent !== null
            ? form.deductible_ratio_percent / 100
            : null,
        is_paid: form.is_paid,
        paid_at: form.paid_at || null,
      })
      .select()
      .single();

    if (expenseError) throw expenseError;

    // Insert categories
    if (form.category_ids.length > 0) {
      const categoryInserts = form.category_ids.map((categoryId) => ({
        expense_id: expense.id,
        category_id: categoryId,
      }));

      const { error: categoryError } = await supabase
        .from('expense_categories')
        .insert(categoryInserts);

      if (categoryError) throw categoryError;
    }

    router.push('/wydatki');
  } catch (error) {
    console.error('Error saving expense:', error);
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
  loadCategories();
});
</script>
