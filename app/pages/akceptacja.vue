<template>
  <div>
    <div class="mb-8">
      <h1 class="text-3xl font-bold">Panel akceptacji wydatków</h1>
      <p class="text-gray-500 mt-2">
        Tutaj znajdziesz sugestie powtarzających się wydatków do szybkiego dodania
      </p>
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
          <UButton @click="$router.push('/cykliczne')">
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
                  {{
                    formatCurrency(
                      suggestion.amount_gross,
                      suggestion.currency_code || 'PLN'
                    )
                  }}
                </div>
                <div class="text-sm text-gray-500">
                  Netto:
                  {{
                    formatCurrency(
                      suggestion.amount_net,
                      suggestion.currency_code || 'PLN'
                    )
                  }}
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
  </div>
</template>

<script setup lang="ts">
import type { Database } from '~/types/database';

definePageMeta({
  middleware: 'auth',
});

type RecurringExpense =
  Database['public']['Tables']['recurring_expenses']['Row'];
type Category = Database['public']['Tables']['categories']['Row'];

interface RecurringSuggestion extends RecurringExpense {
  categories: Category[];
}

const supabase = useSupabaseClient<Database>();
const user = useSupabaseUser();
const router = useRouter();
const {
  getExchangeRate,
  formatCurrency: formatCurrencyFn,
} = useCurrency();

const suggestions = ref<RecurringSuggestion[]>([]);
const loading = ref(true);
const acceptingIds = ref<string[]>([]);

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
    .eq('is_active', true)
    .order('day_of_month', { ascending: true });

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
        categories: (cats || [])
          .map((c) => c.categories)
          .filter(Boolean) as Category[],
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
  // Check if end_date has passed
  if (recurring.end_date) {
    const endDate = new Date(recurring.end_date);
    if (today > endDate) return false;
  }

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
    let vatAmountPLN =
      (suggestion.amount_gross || 0) - (suggestion.amount_net || 0);

    if (currencyCode !== 'PLN') {
      exchangeRate = await getExchangeRate(currencyCode, today);
      amountNetPLN = suggestion.amount_net
        ? Math.round(suggestion.amount_net * exchangeRate * 100) / 100
        : null;
      amountGrossPLN = suggestion.amount_gross
        ? Math.round(suggestion.amount_gross * exchangeRate * 100) / 100
        : null;
      vatAmountPLN =
        amountGrossPLN && amountNetPLN ? amountGrossPLN - amountNetPLN : 0;
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
    acceptingIds.value = acceptingIds.value.filter(
      (id) => id !== suggestion.id
    );
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

onMounted(() => {
  loadSuggestions();
});
</script>
