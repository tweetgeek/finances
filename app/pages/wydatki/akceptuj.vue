<template>
  <div>
    <div class="flex justify-between items-center mb-8">
      <div>
        <h1 class="text-3xl font-bold">Panel akceptacji wydatków</h1>
        <p class="text-gray-500 mt-2">
          Tutaj znajdziesz sugestie powtarzających się wydatków do szybkiego
          dodania
        </p>
      </div>
      <UButton @click="$router.push('/wydatki')"> Powrót do listy </UButton>
    </div>

    <!-- Suggestions Section -->
    <UCard v-if="loading" class="mb-6">
      <div class="text-center py-8">Ładowanie sugestii...</div>
    </UCard>

    <div v-else-if="suggestions.length === 0" class="mb-6">
      <UCard>
        <div class="text-center py-8">
          <div class="text-gray-500 mb-4">
            Brak sugestii wydatków do zaakceptowania.
          </div>
          <UButton @click="$router.push('/wydatki/cykliczne')">
            Zarządzaj cyklicznymi wydatkami
          </UButton>
        </div>
      </UCard>
    </div>

    <div v-else class="space-y-4 mb-6">
      <UCard
        v-for="suggestion in suggestions"
        :key="suggestion.id"
        class="hover:shadow-lg transition-shadow"
      >
        <div class="flex items-start justify-between">
          <div class="flex-1">
            <div class="flex items-start gap-4">
              <div class="flex-1">
                <h3 class="text-lg font-semibold">{{ suggestion.title }}</h3>
                <p v-if="suggestion.counterparty" class="text-gray-500 text-sm">
                  {{ suggestion.counterparty }}
                </p>
                <div class="flex flex-wrap gap-2 mt-2">
                  <UBadge
                    v-for="cat in suggestion.categories"
                    :key="cat.id"
                    color="neutral"
                    variant="subtle"
                  >
                    <div class="flex items-center gap-1">
                      <div
                        class="w-2 h-2 rounded-full"
                        :style="{ backgroundColor: cat.color || '#3b82f6' }"
                      />
                      {{ cat.name }}
                    </div>
                  </UBadge>
                  <UBadge
                    :color="suggestion.is_company ? 'info' : 'neutral'"
                    variant="subtle"
                  >
                    {{ suggestion.is_company ? 'Firmowy' : 'Prywatny' }}
                  </UBadge>
                </div>
              </div>
              <div class="text-right">
                <div class="text-2xl font-bold">
                  {{ formatCurrency(suggestion.amount_gross, suggestion.currency_code || 'PLN') }}
                </div>
                <div class="text-sm text-gray-500">
                  Netto: {{ formatCurrency(suggestion.amount_net, suggestion.currency_code || 'PLN') }}
                </div>
                <div class="text-xs text-gray-400">
                  VAT {{ suggestion.vat_rate }}%
                </div>
              </div>
            </div>
            <div v-if="suggestion.note" class="mt-3 text-sm text-gray-600">
              {{ suggestion.note }}
            </div>
            <div class="mt-3 text-xs text-gray-400">
              Ostatnio dodane:
              {{
                suggestion.last_generated_date
                  ? formatDate(suggestion.last_generated_date)
                  : 'Nigdy'
              }}
              • Cykl: {{ formatFrequency(suggestion.frequency) }}
            </div>
          </div>
        </div>
        <div class="flex gap-2 mt-4 pt-4 border-t border-gray-200">
          <UButton
            :loading="acceptingIds.includes(suggestion.id)"
            color="primary"
            class="flex-1"
            @click="acceptSuggestion(suggestion)"
          >
            Dodaj wydatek
          </UButton>
          <UButton
            color="neutral"
            variant="ghost"
            @click="skipSuggestion(suggestion)"
          >
            Pomiń
          </UButton>
          <UButton
            color="neutral"
            variant="outline"
            @click="editBeforeAccept(suggestion)"
          >
            Edytuj i dodaj
          </UButton>
        </div>
      </UCard>
    </div>

    <!-- Recurring Expenses Management -->
    <UCard>
      <div class="flex justify-between items-center mb-4">
        <h2 class="text-xl font-semibold">Cykliczne wydatki</h2>
        <UButton size="sm" @click="showAddModal = true">
          Dodaj cykliczny wydatek
        </UButton>
      </div>

      <div v-if="recurringExpenses.length === 0" class="text-center py-4">
        <p class="text-gray-500">Brak zdefiniowanych cyklicznych wydatków.</p>
      </div>

      <div v-else class="space-y-2">
        <div
          v-for="recurring in recurringExpenses"
          :key="recurring.id"
          class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-800 rounded-lg"
        >
          <div class="flex-1">
            <div class="font-medium">{{ recurring.title }}</div>
            <div class="text-sm text-gray-500">
              {{ formatCurrency(recurring.amount_gross, recurring.currency_code || 'PLN') }} •
              {{ formatFrequency(recurring.frequency) }}
            </div>
          </div>
          <div class="flex items-center gap-2">
            <USwitch
              :model-value="recurring.is_active"
              @update:model-value="toggleRecurring(recurring)"
            />
            <UButton
              color="neutral"
              variant="ghost"
              icon="i-heroicons-pencil-square"
              size="sm"
              @click="editRecurring(recurring)"
            />
            <UButton
              color="neutral"
              variant="ghost"
              icon="i-heroicons-trash"
              size="sm"
              @click="deleteRecurring(recurring)"
            />
          </div>
        </div>
      </div>
    </UCard>

    <!-- Add/Edit Modal -->
    <UModal v-model:open="showAddModal">
      <template #content>
        <UCard>
          <template #header>
            <h3 class="text-lg font-semibold">
              {{ editingRecurring ? 'Edytuj' : 'Dodaj' }} cykliczny wydatek
            </h3>
          </template>

          <form class="space-y-4" @submit.prevent="saveRecurring">
          <UFormField label="Tytuł" name="title" required>
            <UInput v-model="recurringForm.title" required />
          </UFormField>

          <UFormField label="Kontrahent" name="counterparty">
            <UInput v-model="recurringForm.counterparty" />
          </UFormField>

          <UFormField label="Waluta" name="currency_code">
            <USelect
              v-model="recurringForm.currency_code"
              :items="availableCurrencies"
            />
          </UFormField>

          <div class="grid grid-cols-2 gap-4">
            <UFormField :label="`Kwota netto (${recurringForm.currency_code})`" name="amount_net">
              <UInput
                v-model="recurringForm.amount_net"
                type="number"
                step="0.01"
              />
            </UFormField>

            <UFormField :label="`Kwota brutto (${recurringForm.currency_code})`" name="amount_gross">
              <UInput
                v-model="recurringForm.amount_gross"
                type="number"
                step="0.01"
              />
            </UFormField>
          </div>

          <UFormField label="Stawka VAT" name="vat_rate">
            <USelect
              v-model="recurringForm.vat_rate"
              :items="[
                { label: '23%', value: 23 },
                { label: '8%', value: 8 },
                { label: '5%', value: 5 },
                { label: '0%', value: 0 },
              ]"
            />
          </UFormField>

          <UFormField label="Częstotliwość" name="frequency">
            <USelect
              v-model="recurringForm.frequency"
              :items="[
                { label: 'Miesięcznie', value: 'monthly' },
                { label: 'Kwartalnie', value: 'quarterly' },
                { label: 'Rocznie', value: 'yearly' },
              ]"
            />
          </UFormField>

          <UFormField label="Dzień miesiąca" name="day_of_month">
            <UInput
              v-model="recurringForm.day_of_month"
              type="number"
              min="1"
              max="31"
            />
          </UFormField>

          <UFormField label="Kategorie" name="categories">
            <div class="space-y-2">
              <div
                v-for="category in categories"
                :key="category.id"
                class="flex items-center gap-2"
              >
                <UCheckbox
                  :model-value="recurringForm.selectedCategories.some(c => c.id === category.id)"
                  @update:model-value="(checked) => toggleCategory(category, checked)"
                />
                <div class="flex items-center gap-2">
                  <div
                    class="w-3 h-3 rounded-full"
                    :style="{ backgroundColor: category.color || '#3b82f6' }"
                  />
                  <span>{{ category.name }}</span>
                </div>
              </div>
            </div>
          </UFormField>

          <UFormField label="Wydatek firmowy" name="is_company">
            <USwitch v-model="recurringForm.is_company" />
          </UFormField>

          <UFormField label="Notatka" name="note">
            <UTextarea v-model="recurringForm.note" rows="2" />
          </UFormField>

            <div class="flex justify-end gap-2 pt-4">
              <UButton
                type="button"
                color="neutral"
                variant="ghost"
                @click="showAddModal = false"
              >
                Anuluj
              </UButton>
              <UButton type="submit" :loading="saving"> Zapisz </UButton>
            </div>
          </form>
        </UCard>
      </template>
    </UModal>
  </div>
</template>

<script setup lang="ts">
import type { Database } from '~/types/database';

definePageMeta({
  middleware: 'auth',
});

type RecurringExpense = Database['public']['Tables']['recurring_expenses']['Row'];
type Category = Database['public']['Tables']['categories']['Row'];

interface RecurringSuggestion extends RecurringExpense {
  categories: Category[];
}

const supabase = useSupabaseClient<Database>();
const user = useSupabaseUser();
const router = useRouter();
const { getExchangeRate, formatCurrency: formatCurrencyFn, availableCurrencies } = useCurrency();

const suggestions = ref<RecurringSuggestion[]>([]);
const recurringExpenses = ref<RecurringExpense[]>([]);
const loading = ref(true);
const acceptingIds = ref<string[]>([]);
const showAddModal = ref(false);
const editingRecurring = ref<RecurringExpense | null>(null);
const saving = ref(false);

const categories = ref<Category[]>([]);

const recurringForm = reactive({
  title: '',
  counterparty: '',
  currency_code: 'PLN',
  amount_net: null as number | null,
  amount_gross: null as number | null,
  vat_rate: 23,
  frequency: 'monthly' as 'monthly' | 'quarterly' | 'yearly',
  day_of_month: 1,
  is_company: false,
  note: '',
  selectedCategories: [] as Category[],
});

const formatCurrency = (amount: number | null, currency: string = 'PLN') => {
  return formatCurrencyFn(amount, currency);
};

const loadSuggestions = async () => {
  if (!user.value) return;

  loading.value = true;

  // Load active recurring expenses that need to be generated
  const { data: recurring, error } = await supabase
    .from('recurring_expenses')
    .select('*')
    .eq('user_id', user.value.sub)
    .eq('is_active', true);

  if (error) {
    console.error('Error loading recurring expenses:', error);
    loading.value = false;
    return;
  }

  // Filter to get only those that should be suggested
  const today = new Date();
  const suggestionsList: RecurringSuggestion[] = [];

  for (const rec of recurring || []) {
    const shouldSuggest = await checkIfShouldSuggest(rec, today);
    if (shouldSuggest) {
      // Load categories for this recurring expense
      const { data: cats } = await supabase
        .from('recurring_expense_categories')
        .select('category_id, categories(*)')
        .eq('recurring_expense_id', rec.id);

      suggestionsList.push({
        ...rec,
        categories: (cats || []).map((c) => c.categories).filter(Boolean) as Category[],
      });
    }
  }

  suggestions.value = suggestionsList;
  loading.value = false;
};

const checkIfShouldSuggest = async (
  recurring: RecurringExpense,
  today: Date
): Promise<boolean> => {
  // If never generated, suggest it
  if (!recurring.last_generated_date) return true;

  const lastGenerated = new Date(recurring.last_generated_date);
  const monthsDiff =
    (today.getFullYear() - lastGenerated.getFullYear()) * 12 +
    (today.getMonth() - lastGenerated.getMonth());

  // Check based on frequency
  switch (recurring.frequency) {
    case 'monthly':
      // Suggest if it's been more than 3 weeks or next month
      return monthsDiff >= 1;
    case 'quarterly':
      return monthsDiff >= 3;
    case 'yearly':
      return monthsDiff >= 12;
    default:
      return false;
  }
};

const loadRecurringExpenses = async () => {
  if (!user.value) return;

  const { data, error } = await supabase
    .from('recurring_expenses')
    .select('*')
    .eq('user_id', user.value.sub)
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error loading recurring expenses:', error);
  } else {
    recurringExpenses.value = data || [];
  }
};

const acceptSuggestion = async (suggestion: RecurringSuggestion) => {
  if (!user.value) return;

  acceptingIds.value.push(suggestion.id);

  try {
    const today = new Date().toISOString().split('T')[0];
    const currencyCode = suggestion.currency_code || 'PLN';

    // Get exchange rate if not PLN
    let exchangeRate = 1;
    let amountNetPLN = suggestion.amount_net;
    let amountGrossPLN = suggestion.amount_gross;
    let vatAmountPLN = (suggestion.amount_gross || 0) - (suggestion.amount_net || 0);

    if (currencyCode !== 'PLN') {
      exchangeRate = await getExchangeRate(currencyCode, today);
      amountNetPLN = suggestion.amount_net ? Math.round(suggestion.amount_net * exchangeRate * 100) / 100 : null;
      amountGrossPLN = suggestion.amount_gross ? Math.round(suggestion.amount_gross * exchangeRate * 100) / 100 : null;
      vatAmountPLN = amountGrossPLN && amountNetPLN ? amountGrossPLN - amountNetPLN : 0;
    }

    // Create the expense
    const { data: expense, error: expenseError } = await supabase
      .from('expenses')
      .insert({
        user_id: user.value.sub,
        title: suggestion.title,
        counterparty: suggestion.counterparty,
        currency_code: currencyCode,
        amount_net: suggestion.amount_net,
        amount_gross: suggestion.amount_gross,
        exchange_rate: exchangeRate,
        amount_net_pln: amountNetPLN,
        amount_gross_pln: amountGrossPLN,
        vat_amount_pln: vatAmountPLN,
        vat_rate: suggestion.vat_rate,
        is_company: suggestion.is_company,
        deductible_override: suggestion.deductible_override,
        deductible_ratio: suggestion.deductible_ratio,
        note: suggestion.note,
        issue_date: today,
        is_paid: false,
      })
      .select()
      .single();

    if (expenseError) throw expenseError;

    // Add categories
    if (suggestion.categories.length > 0) {
      const categoryInserts = suggestion.categories.map((cat) => ({
        expense_id: expense.id,
        category_id: cat.id,
      }));

      await supabase.from('expense_categories').insert(categoryInserts);
    }

    // Update last_generated_date
    await supabase
      .from('recurring_expenses')
      .update({ last_generated_date: new Date().toISOString().split('T')[0] })
      .eq('id', suggestion.id);

    // Refresh suggestions
    await loadSuggestions();
  } catch (error) {
    console.error('Error accepting suggestion:', error);
  } finally {
    acceptingIds.value = acceptingIds.value.filter((id) => id !== suggestion.id);
  }
};

const skipSuggestion = async (suggestion: RecurringSuggestion) => {
  // Update last_generated_date to skip for now
  await supabase
    .from('recurring_expenses')
    .update({ last_generated_date: new Date().toISOString().split('T')[0] })
    .eq('id', suggestion.id);

  await loadSuggestions();
};

const editBeforeAccept = (suggestion: RecurringSuggestion) => {
  // Navigate to new expense form with pre-filled data
  router.push({
    path: '/wydatki/nowy',
    query: {
      title: suggestion.title,
      counterparty: suggestion.counterparty || '',
      amount_net: suggestion.amount_net?.toString() || '',
      amount_gross: suggestion.amount_gross?.toString() || '',
      vat_rate: suggestion.vat_rate.toString(),
      is_company: suggestion.is_company.toString(),
    },
  });
};

const toggleRecurring = async (recurring: RecurringExpense) => {
  await supabase
    .from('recurring_expenses')
    .update({ is_active: !recurring.is_active })
    .eq('id', recurring.id);

  await loadRecurringExpenses();
  await loadSuggestions();
};

const editRecurring = async (recurring: RecurringExpense) => {
  editingRecurring.value = recurring;

  // Load categories for this recurring expense
  const { data: cats } = await supabase
    .from('recurring_expense_categories')
    .select('category_id, categories(*)')
    .eq('recurring_expense_id', recurring.id);

  const selectedCats = (cats || [])
    .map((c) => c.categories)
    .filter(Boolean) as Category[];

  Object.assign(recurringForm, {
    title: recurring.title,
    counterparty: recurring.counterparty || '',
    currency_code: recurring.currency_code || 'PLN',
    amount_net: recurring.amount_net,
    amount_gross: recurring.amount_gross,
    vat_rate: recurring.vat_rate,
    frequency: recurring.frequency,
    day_of_month: recurring.day_of_month || 1,
    is_company: recurring.is_company,
    note: recurring.note || '',
    selectedCategories: selectedCats,
  });
  showAddModal.value = true;
};

const deleteRecurring = async (recurring: RecurringExpense) => {
  if (!confirm(`Czy na pewno chcesz usunąć "${recurring.title}"?`)) return;

  await supabase.from('recurring_expenses').delete().eq('id', recurring.id);

  await loadRecurringExpenses();
  await loadSuggestions();
};

const saveRecurring = async () => {
  if (!user.value) return;

  saving.value = true;

  try {
    let recurringId: string;

    if (editingRecurring.value) {
      // Update existing
      recurringId = editingRecurring.value.id;
      await supabase
        .from('recurring_expenses')
        .update({
          title: recurringForm.title,
          counterparty: recurringForm.counterparty || null,
          currency_code: recurringForm.currency_code,
          amount_net: recurringForm.amount_net,
          amount_gross: recurringForm.amount_gross,
          vat_rate: recurringForm.vat_rate,
          frequency: recurringForm.frequency,
          day_of_month: recurringForm.day_of_month,
          is_company: recurringForm.is_company,
          note: recurringForm.note || null,
        })
        .eq('id', editingRecurring.value.id);

      // Delete existing categories
      await supabase
        .from('recurring_expense_categories')
        .delete()
        .eq('recurring_expense_id', recurringId);
    } else {
      // Create new
      const { data, error } = await supabase
        .from('recurring_expenses')
        .insert({
          user_id: user.value.sub,
          title: recurringForm.title,
          counterparty: recurringForm.counterparty || null,
          currency_code: recurringForm.currency_code,
          amount_net: recurringForm.amount_net,
          amount_gross: recurringForm.amount_gross,
          vat_rate: recurringForm.vat_rate,
          frequency: recurringForm.frequency,
          day_of_month: recurringForm.day_of_month,
          is_company: recurringForm.is_company,
          note: recurringForm.note || null,
          is_active: true,
        })
        .select()
        .single();

      if (error) throw error;
      recurringId = data.id;
    }

    // Add categories
    if (recurringForm.selectedCategories.length > 0) {
      const categoryInserts = recurringForm.selectedCategories.map((cat) => ({
        recurring_expense_id: recurringId,
        category_id: cat.id,
      }));

      await supabase.from('recurring_expense_categories').insert(categoryInserts);
    }

    showAddModal.value = false;
    editingRecurring.value = null;
    Object.assign(recurringForm, {
      title: '',
      counterparty: '',
      currency_code: 'PLN',
      amount_net: null,
      amount_gross: null,
      vat_rate: 23,
      frequency: 'monthly',
      day_of_month: 1,
      is_company: false,
      note: '',
      selectedCategories: [],
    });

    await loadRecurringExpenses();
    await loadSuggestions();
  } catch (error) {
    console.error('Error saving recurring expense:', error);
  } finally {
    saving.value = false;
  }
};

const formatDate = (date: string) => {
  return new Date(date).toLocaleDateString('pl-PL');
};

const formatFrequency = (frequency: string) => {
  const map: Record<string, string> = {
    monthly: 'Miesięcznie',
    quarterly: 'Kwartalnie',
    yearly: 'Rocznie',
  };
  return map[frequency] || frequency;
};

const loadCategories = async () => {
  if (!user.value) return;

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
};

const toggleCategory = (category: Category, checked: boolean) => {
  if (checked) {
    if (!recurringForm.selectedCategories.some(c => c.id === category.id)) {
      recurringForm.selectedCategories.push(category);
    }
  } else {
    recurringForm.selectedCategories = recurringForm.selectedCategories.filter(
      c => c.id !== category.id
    );
  }
};

onMounted(() => {
  loadCategories();
  loadSuggestions();
  loadRecurringExpenses();
});
</script>
