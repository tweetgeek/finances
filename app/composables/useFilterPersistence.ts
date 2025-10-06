import { ref, watch, onMounted } from 'vue'

interface FilterState {
  [key: string]: any
}

export const useFilterPersistence = (viewKey: string, defaultFilters: FilterState) => {
  const storageKey = `filters_${viewKey}`

  // Initialize filters with default values
  const filters = ref<FilterState>({ ...defaultFilters })

  // Load filters from localStorage
  const loadFilters = () => {
    if (typeof window === 'undefined') return

    try {
      const stored = localStorage.getItem(storageKey)
      if (stored) {
        const parsed = JSON.parse(stored)
        // Merge stored filters with defaults to handle new filter fields
        filters.value = { ...defaultFilters, ...parsed }
      }
    } catch (error) {
      console.error('Error loading filters from localStorage:', error)
    }
  }

  // Save filters to localStorage
  const saveFilters = () => {
    if (typeof window === 'undefined') return

    try {
      localStorage.setItem(storageKey, JSON.stringify(filters.value))
    } catch (error) {
      console.error('Error saving filters to localStorage:', error)
    }
  }

  // Clear filters and reset to defaults
  const clearFilters = () => {
    if (typeof window === 'undefined') return

    try {
      localStorage.removeItem(storageKey)
      filters.value = { ...defaultFilters }
    } catch (error) {
      console.error('Error clearing filters from localStorage:', error)
    }
  }

  // Watch for filter changes and save automatically
  watch(
    filters,
    () => {
      saveFilters()
    },
    { deep: true }
  )

  // Load filters on mount
  onMounted(() => {
    loadFilters()
  })

  return {
    filters,
    clearFilters,
    loadFilters,
    saveFilters,
  }
}
