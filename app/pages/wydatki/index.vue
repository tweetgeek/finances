<template>
  <div>
    <div class="flex justify-between items-center mb-8">
      <h1 class="text-3xl font-bold">Wydatki</h1>
      <UButton @click="$router.push('/wydatki/nowy')">
        Dodaj wydatek
      </UButton>
    </div>

    <!-- Filters -->
    <UCard class="mb-6">
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <UFormGroup label="Od daty">
          <UInput v-model="filters.dateFrom" type="date" />
        </UFormGroup>
        <UFormGroup label="Do daty">
          <UInput v-model="filters.dateTo" type="date" />
        </UFormGroup>
        <UFormGroup label="Status płatności">
          <USelect
            v-model="filters.paymentStatus"
            :options="[
              { label: 'Wszystkie', value: '' },
              { label: 'Opłacone', value: 'paid' },
              { label: 'Nieopłacone', value: 'unpaid' }
            ]"
          />
        </UFormGroup>
        <UFormGroup label="Typ">
          <USelect
            v-model="filters.companyType"
            :options="[
              { label: 'Wszystkie', value: '' },
              { label: 'Firmowe', value: 'company' },
              { label: 'Prywatne', value: 'private' }
            ]"
          />
        </UFormGroup>
      </div>
    </UCard>

    <UCard v-if="loading" class="text-center">
      Ładowanie...
    </UCard>

    <UCard v-else-if="filteredExpenses.length === 0">
      <div class="text-center text-gray-500">
        Brak wydatków. Dodaj pierwszy wydatek.
      </div>
    </UCard>

    <UCard v-else>
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
          <thead class="bg-gray-50 dark:bg-gray-800">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Data
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Tytuł
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Kontrahent
              </th>
              <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                Kwota brutto
              </th>
              <th class="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                Typ
              </th>
              <th class="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                Status
              </th>
              <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                Akcje
              </th>
            </tr>
          </thead>
          <tbody class="bg-white dark:bg-gray-900 divide-y divide-gray-200 dark:divide-gray-700">
            <tr v-for="expense in filteredExpenses" :key="expense.id">
              <td class="px-6 py-4 whitespace-nowrap text-sm">
                {{ formatDate(expense.issue_date) }}
              </td>
              <td class="px-6 py-4 text-sm">
                <div class="font-medium">{{ expense.title }}</div>
                <div v-if="expense.invoice_number" class="text-gray-500 text-xs">
                  {{ expense.invoice_number }}
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                {{ expense.counterparty || '-' }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-right font-medium">
                {{ formatCurrency(expense.amount_gross) }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-center">
                <UBadge :color="expense.is_company ? 'blue' : 'gray'" variant="subtle">
                  {{ expense.is_company ? 'Firmowy' : 'Prywatny' }}
                </UBadge>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-center">
                <UBadge :color="expense.is_paid ? 'green' : 'red'" variant="subtle">
                  {{ expense.is_paid ? 'Opłacone' : 'Nieopłacone' }}
                </UBadge>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right text-sm">
                <UDropdown :items="getDropdownItems(expense)">
                  <UButton
                    color="gray"
                    variant="ghost"
                    icon="i-heroicons-ellipsis-vertical"
                  />
                </UDropdown>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Summary -->
      <div class="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
        <div class="flex justify-between items-center text-sm">
          <span class="text-gray-500">Suma ({{ filteredExpenses.length }} pozycji)</span>
          <span class="font-bold text-lg">
            {{ formatCurrency(totalAmount) }}
          </span>
        </div>
      </div>
    </UCard>
  </div>
</template>

<script setup lang="ts">
import type { Database } from '~/types/database'

definePageMeta({
  middleware: 'auth'
})

type Expense = Database['public']['Tables']['expenses']['Row']

const supabase = useSupabaseClient<Database>()
const user = useSupabaseUser()
const router = useRouter()

const expenses = ref<Expense[]>([])
const loading = ref(true)

const filters = reactive({
  dateFrom: '',
  dateTo: '',
  paymentStatus: '',
  companyType: ''
})

const loadExpenses = async () => {
  if (!user.value) return

  loading.value = true
  const { data, error } = await supabase
    .from('expenses')
    .select('*')
    .eq('user_id', user.value.id)
    .order('issue_date', { ascending: false })

  if (error) {
    console.error('Error loading expenses:', error)
  } else {
    expenses.value = data || []
  }
  loading.value = false
}

const filteredExpenses = computed(() => {
  return expenses.value.filter(expense => {
    if (filters.dateFrom && expense.issue_date < filters.dateFrom) return false
    if (filters.dateTo && expense.issue_date > filters.dateTo) return false
    if (filters.paymentStatus === 'paid' && !expense.is_paid) return false
    if (filters.paymentStatus === 'unpaid' && expense.is_paid) return false
    if (filters.companyType === 'company' && !expense.is_company) return false
    if (filters.companyType === 'private' && expense.is_company) return false
    return true
  })
})

const totalAmount = computed(() => {
  return filteredExpenses.value.reduce((sum, expense) => sum + (expense.amount_gross || 0), 0)
})

const formatDate = (date: string) => {
  return new Date(date).toLocaleDateString('pl-PL')
}

const formatCurrency = (amount: number | null) => {
  if (amount === null) return '-'
  return new Intl.NumberFormat('pl-PL', {
    style: 'currency',
    currency: 'PLN'
  }).format(amount)
}

const deleteExpense = async (expense: Expense) => {
  if (!confirm(`Czy na pewno chcesz usunąć wydatek "${expense.title}"?`)) {
    return
  }

  const { error } = await supabase
    .from('expenses')
    .delete()
    .eq('id', expense.id)

  if (error) {
    console.error('Error deleting expense:', error)
  } else {
    await loadExpenses()
  }
}

const togglePaid = async (expense: Expense) => {
  const { error } = await supabase
    .from('expenses')
    .update({
      is_paid: !expense.is_paid,
      paid_at: !expense.is_paid ? new Date().toISOString().split('T')[0] : null
    })
    .eq('id', expense.id)

  if (error) {
    console.error('Error updating expense:', error)
  } else {
    await loadExpenses()
  }
}

const getDropdownItems = (expense: Expense) => [[
  {
    label: expense.is_paid ? 'Oznacz jako nieopłacone' : 'Oznacz jako opłacone',
    icon: expense.is_paid ? 'i-heroicons-x-circle' : 'i-heroicons-check-circle',
    click: () => togglePaid(expense)
  },
  {
    label: 'Edytuj',
    icon: 'i-heroicons-pencil-square',
    click: () => router.push(`/wydatki/${expense.id}`)
  },
  {
    label: 'Usuń',
    icon: 'i-heroicons-trash',
    click: () => deleteExpense(expense)
  }
]]

onMounted(() => {
  // Set default date range (current month)
  const now = new Date()
  const firstDay = new Date(now.getFullYear(), now.getMonth(), 1)
  const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0)

  filters.dateFrom = firstDay.toISOString().split('T')[0]
  filters.dateTo = lastDay.toISOString().split('T')[0]

  loadExpenses()
})
</script>
