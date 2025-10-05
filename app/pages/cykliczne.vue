<template>
  <div>
    <div class="flex justify-between items-center mb-8">
      <h1 class="text-3xl font-bold">Cykliczne wydatki</h1>
      <UButton @click="showAddModal = true">
        Dodaj cykliczny wydatek
      </UButton>
    </div>

    <UCard v-if="loading" class="text-center py-8">
      Ładowanie...
    </UCard>

    <UCard v-else-if="recurringExpensesWithCategories.length === 0">
      <div class="text-center py-8">
        <p class="text-gray-500 mb-4">Brak zdefiniowanych cyklicznych wydatków.</p>
        <UButton @click="showAddModal = true">
          Dodaj pierwszy cykliczny wydatek
        </UButton>
      </div>
    </UCard>

    <UCard v-else>
      <div class="space-y-2">
        <div
          v-for="recurring in recurringExpensesWithCategories"
          :key="recurring.id"
          class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-800 rounded-lg"
        >
          <div class="flex-1">
            <div class="font-medium">{{ recurring.title }}</div>
            <div class="text-sm text-gray-500">
              {{
                formatCurrency(
                  recurring.amount_gross,
                  recurring.currency_code || 'PLN'
                )
              }}
              •
              {{ formatFrequency(recurring.frequency) }}
              <span v-if="recurring.day_of_month">
                • {{ recurring.day_of_month }} dzień miesiąca
              </span>
            </div>
            <div v-if="recurring.end_date" class="text-xs text-gray-400 mt-1">
              Do: {{ formatDate(recurring.end_date) }}
            </div>
            <div
              v-if="recurring.categories.length > 0"
              class="flex flex-wrap gap-1 mt-2"
            >
              <UBadge
                v-for="cat in recurring.categories"
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

          <div class="max-h-[70vh] overflow-y-auto overscroll-contain px-6">
            <form class="space-y-4 py-4" @submit.prevent="saveRecurring">
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
              <UFormField
                :label="`Kwota netto (${recurringForm.currency_code})`"
                name="amount_net"
              >
                <UInput
                  v-model="recurringForm.amount_net"
                  type="number"
                  step="0.01"
                />
              </UFormField>

              <UFormField
                :label="`Kwota brutto (${recurringForm.currency_code})`"
                name="amount_gross"
              >
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

            <UFormField label="Data zakończenia" name="end_date">
              <UInput
                v-model="recurringForm.end_date"
                type="date"
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
                    :model-value="
                      recurringForm.selectedCategories.some(
                        (c) => c.id === category.id
                      )
                    "
                    @update:model-value="
                      (checked) => toggleCategory(category, checked)
                    "
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

            <div class="flex flex-col sm:flex-row justify-end gap-2 pt-4 sticky bottom-0 bg-white dark:bg-gray-900 -mx-6 px-6 pb-4">
              <UButton
                type="button"
                color="neutral"
                variant="ghost"
                @click="showAddModal = false"
                class="w-full sm:w-auto"
              >
                Anuluj
              </UButton>
              <UButton type="submit" :loading="saving" class="w-full sm:w-auto"> Zapisz </UButton>
            </div>
          </form>
          </div>
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

type RecurringExpense =
  Database['public']['Tables']['recurring_expenses']['Row'];
type Category = Database['public']['Tables']['categories']['Row'];

interface RecurringSuggestion extends RecurringExpense {
  categories: Category[];
}

const supabase = useSupabaseClient<Database>();
const user = useSupabaseUser();
const {
  formatCurrency: formatCurrencyFn,
  availableCurrencies,
} = useCurrency();

const recurringExpensesWithCategories = ref<RecurringSuggestion[]>([]);
const loading = ref(true);
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
  end_date: null as string | null,
  selectedCategories: [] as Category[],
});

const formatCurrency = (amount: number | null, currency: string = 'PLN') => {
  return formatCurrencyFn(amount, currency);
};

const loadRecurringExpenses = async () => {
  if (!user.value) return;

  loading.value = true;

  const { data, error } = await supabase
    .from('recurring_expenses')
    .select('*')
    .eq('user_id', user.value.sub)
    .order('day_of_month', { ascending: true });

  if (error) {
    console.error('Error loading recurring expenses:', error);
  } else {
    // Load categories for each recurring expense
    const withCategories: RecurringSuggestion[] = [];
    for (const rec of data || []) {
      const { data: cats } = await supabase
        .from('recurring_expense_categories')
        .select('category_id, categories(*)')
        .eq('recurring_expense_id', rec.id);

      withCategories.push({
        ...rec,
        categories: (cats || [])
          .map((c) => c.categories)
          .filter(Boolean) as Category[],
      });
    }
    recurringExpensesWithCategories.value = withCategories;
  }

  loading.value = false;
};

const toggleRecurring = async (recurring: RecurringExpense) => {
  await supabase
    .from('recurring_expenses')
    .update({ is_active: !recurring.is_active })
    .eq('id', recurring.id);

  await loadRecurringExpenses();
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
    end_date: recurring.end_date || null,
    selectedCategories: selectedCats,
  });
  showAddModal.value = true;
};

const deleteRecurring = async (recurring: RecurringExpense) => {
  if (!confirm(`Czy na pewno chcesz usunąć "${recurring.title}"?`)) return;

  await supabase.from('recurring_expenses').delete().eq('id', recurring.id);

  await loadRecurringExpenses();
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
          end_date: recurringForm.end_date || null,
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
          end_date: recurringForm.end_date || null,
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

      await supabase
        .from('recurring_expense_categories')
        .insert(categoryInserts);
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
      end_date: null,
      selectedCategories: [],
    });

    await loadRecurringExpenses();
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
    if (!recurringForm.selectedCategories.some((c) => c.id === category.id)) {
      recurringForm.selectedCategories.push(category);
    }
  } else {
    recurringForm.selectedCategories = recurringForm.selectedCategories.filter(
      (c) => c.id !== category.id
    );
  }
};

onMounted(() => {
  loadCategories();
  loadRecurringExpenses();
});
</script>
