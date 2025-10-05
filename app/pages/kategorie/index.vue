<template>
  <div>
    <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4 mb-6 sm:mb-8">
      <h1 class="text-2xl sm:text-3xl font-bold">Kategorie</h1>
      <UButton @click="openCreateModal" class="w-full sm:w-auto"> Dodaj kategorię </UButton>
    </div>

    <UCard v-if="loading" class="text-center"> Ładowanie... </UCard>

    <UCard v-else-if="categories.length === 0">
      <div class="text-center text-gray-500">
        Brak kategorii. Dodaj pierwszą kategorię, aby rozpocząć.
      </div>
    </UCard>

    <div v-else class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
      <UCard v-for="category in categories" :key="category.id">
        <div class="flex items-start justify-between">
          <div class="flex items-center space-x-3">
            <div
              class="w-4 h-4 rounded-full"
              :style="{ backgroundColor: category.color || '#3b82f6' }"
            />
            <div>
              <h3 class="font-semibold">{{ category.name }}</h3>
              <div class="text-sm text-gray-500 space-y-1 mt-1">
                <div v-if="category.is_deductible_in_company">
                  Odliczalna:
                  {{ (category.default_deductible_ratio * 100).toFixed(0) }}%
                </div>
                <div v-else class="text-gray-400">Nieodliczalna</div>
              </div>
            </div>
          </div>

          <UDropdownMenu :items="getDropdownItems(category)">
            <UButton
              color="neutral"
              variant="ghost"
              icon="i-heroicons-ellipsis-vertical"
            />
          </UDropdownMenu>
        </div>
      </UCard>
    </div>

    <UModal
      v-model:open="isModalOpen"
      :title="editingCategory ? 'Edytuj kategorię' : 'Dodaj kategorię'"
    >
      <template #content>
        <div class="max-h-[80vh] overflow-y-auto overscroll-contain">
          <form class="space-y-4 p-4" @submit.prevent="handleSubmit">
          <UFormField label="Nazwa" name="name" required>
            <UInput
              v-model="form.name"
              placeholder="Nazwa kategorii"
              required
            />
          </UFormField>

          <UFormField label="Kolor" name="color">
            <UColorPicker v-model="form.color" />
          </UFormField>

          <UFormField label="Odliczalna w firmie" name="is_deductible">
            <USwitch v-model="form.is_deductible_in_company" />
          </UFormField>

          <UFormField
            v-if="form.is_deductible_in_company"
            label="Proporcja odliczenia (%)"
            name="ratio"
          >
            <UInput
              v-model="form.deductible_ratio_percent"
              type="number"
              min="0"
              max="100"
              step="1"
            />
          </UFormField>

          <div class="flex flex-col sm:flex-row justify-end gap-2 sm:space-x-2 sticky bottom-0 bg-white dark:bg-gray-900 pt-4 -mb-4 pb-4">
            <UButton color="neutral" variant="ghost" @click="closeModal" class="w-full sm:w-auto">
              Anuluj
            </UButton>
            <UButton type="submit" :loading="saving" class="w-full sm:w-auto">
              {{ editingCategory ? 'Zapisz' : 'Dodaj' }}
            </UButton>
          </div>
        </form>
        </div>
      </template>
    </UModal>
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

console.log({ user });

const categories = ref<Category[]>([]);
const loading = ref(true);
const isModalOpen = ref(false);
const editingCategory = ref<Category | null>(null);
const saving = ref(false);

const form = reactive({
  name: '',
  color: '#3b82f6',
  is_deductible_in_company: false,
  deductible_ratio_percent: 100,
});

const loadCategories = async () => {
  if (!user.value) return;

  loading.value = true;
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
  loading.value = false;
};

const openCreateModal = () => {
  editingCategory.value = null;
  form.name = '';
  form.color = '#3b82f6';
  form.is_deductible_in_company = false;
  form.deductible_ratio_percent = 100;
  isModalOpen.value = true;
};

const openEditModal = (category: Category) => {
  editingCategory.value = category;
  form.name = category.name;
  form.color = category.color || '#3b82f6';
  form.is_deductible_in_company = category.is_deductible_in_company;
  form.deductible_ratio_percent = Math.round(
    category.default_deductible_ratio * 100
  );
  isModalOpen.value = true;
};

const closeModal = () => {
  isModalOpen.value = false;
  editingCategory.value = null;
};

const handleSubmit = async () => {
  if (!user.value) return;

  saving.value = true;

  const categoryData = {
    name: form.name,
    color: form.color,
    is_deductible_in_company: form.is_deductible_in_company,
    default_deductible_ratio: form.deductible_ratio_percent / 100,
    user_id: user.value.sub,
  };

  if (editingCategory.value) {
    const { error } = await supabase
      .from('categories')
      .update(categoryData)
      .eq('id', editingCategory.value.id);

    if (error) {
      console.error('Error updating category:', error);
    } else {
      await loadCategories();
      closeModal();
    }
  } else {
    const { error } = await supabase.from('categories').insert(categoryData);

    if (error) {
      console.error('Error creating category:', error);
    } else {
      await loadCategories();
      closeModal();
    }
  }

  saving.value = false;
};

const deleteCategory = async (category: Category) => {
  if (!confirm(`Czy na pewno chcesz usunąć kategorię "${category.name}"?`)) {
    return;
  }

  const { error } = await supabase
    .from('categories')
    .delete()
    .eq('id', category.id);

  if (error) {
    console.error('Error deleting category:', error);
  } else {
    await loadCategories();
  }
};

const getDropdownItems = (category: Category) => [
  [
    {
      label: 'Edytuj',
      icon: 'i-heroicons-pencil-square',
      onSelect: () => openEditModal(category),
    },
    {
      label: 'Usuń',
      icon: 'i-heroicons-trash',
      onSelect: () => deleteCategory(category),
    },
  ],
];

onMounted(() => {
  loadCategories();
});
</script>
