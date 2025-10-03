<template>
  <div>
    <h1 class="text-2xl sm:text-3xl font-bold mb-6 sm:mb-8">Ustawienia</h1>

    <UCard v-if="loading" class="text-center"> Ładowanie... </UCard>

    <div v-else class="space-y-4 sm:space-y-6">
      <!-- Tax Settings -->
      <UCard>
        <template #header>
          <h2 class="text-lg sm:text-xl font-semibold">Ustawienia podatkowe</h2>
        </template>

        <div class="space-y-4">
          <UFormField label="Forma opodatkowania" required>
            <USelect
              v-model="settings.tax_type"
              :items="taxTypeOptions"
              @update:model-value="updateSettings"
            />
          </UFormField>

          <UFormField label="Stawka podatku">
            <UInput
              :model-value="settings.tax_rate + '%'"
              disabled
              placeholder="Automatycznie z formy opodatkowania"
            />
          </UFormField>

          <UFormField>
            <UCheckbox
              v-model="settings.vat_enabled"
              label="Płatnik VAT"
              @update:model-value="updateSettings"
            />
          </UFormField>

          <UFormField v-if="settings.vat_enabled" label="Stawka VAT domyślna">
            <USelect
              v-model="settings.vat_rate"
              :items="vatRates"
              @update:model-value="updateSettings"
            />
          </UFormField>
        </div>
      </UCard>

      <!-- ZUS Settings -->
      <UCard>
        <template #header>
          <h2 class="text-lg sm:text-xl font-semibold">Ustawienia ZUS</h2>
        </template>

        <div class="space-y-4">
          <UFormField label="Podstawa składek społecznych (miesięcznie)" help="Minimalna podstawa ZUS 2025: 5 203,80 zł">
            <UInput
              v-model="settings.zus_social_base"
              type="number"
              step="0.01"
              placeholder="5203.80"
              @blur="updateSettings"
            />
          </UFormField>

          <UFormField label="Sposób liczenia składki zdrowotnej">
            <USelect
              v-model="settings.zus_health_calculation"
              :items="zusHealthCalculationOptions"
              @update:model-value="updateSettings"
            />
          </UFormField>

          <UFormField
            v-if="settings.zus_health_calculation === 'fixed'"
            label="Składka zdrowotna (stała kwota miesięcznie)"
          >
            <UInput
              v-model="settings.zus_health_fixed"
              type="number"
              step="0.01"
              placeholder="461.66"
              @blur="updateSettings"
            />
          </UFormField>

          <div v-if="settings.zus_health_calculation === 'ryczalt'" class="text-sm text-gray-500">
            <p class="mb-2">Składka zdrowotna będzie liczona automatycznie na podstawie przychodów:</p>
            <ul class="list-disc list-inside space-y-1">
              <li>do 60 000 zł rocznie: 461,66 zł/mc</li>
              <li>60 000 - 300 000 zł rocznie: 769,43 zł/mc</li>
              <li>powyżej 300 000 zł rocznie: 1 384,97 zł/mc</li>
            </ul>
          </div>
        </div>
      </UCard>

      <!-- Business Info -->
      <UCard>
        <template #header>
          <h2 class="text-xl font-semibold">Dane firmy</h2>
        </template>

        <div class="space-y-4">
          <UFormField label="Nazwa firmy">
            <UInput
              v-model="settings.company_name"
              placeholder="Nazwa firmy"
              @blur="updateSettings"
            />
          </UFormField>
        </div>
      </UCard>

      <div v-if="saveStatus" class="text-sm text-green-600">
        Ustawienia zapisane automatycznie
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Database } from '~/types/database';

definePageMeta({
  middleware: 'auth',
});

type CompanySettings = Database['public']['Tables']['company_settings']['Row'];

const supabase = useSupabaseClient<Database>();
const user = useSupabaseUser();

const loading = ref(true);
const saveStatus = ref(false);

const settings = reactive({
  tax_type: 'ryczalt_12' as string,
  tax_rate: 12,
  zus_amount: 0,
  zus_social_base: null as number | null,
  zus_health_calculation: 'ryczalt' as string,
  zus_health_fixed: null as number | null,
  vat_enabled: true,
  vat_rate: 23,
  company_name: '',
});

const taxTypeOptions = [
  { label: 'Ryczałt 2%', value: 'ryczalt_2' },
  { label: 'Ryczałt 3%', value: 'ryczalt_3' },
  { label: 'Ryczałt 5.5%', value: 'ryczalt_5_5' },
  { label: 'Ryczałt 8.5%', value: 'ryczalt_8_5' },
  { label: 'Ryczałt 10%', value: 'ryczalt_10' },
  { label: 'Ryczałt 12%', value: 'ryczalt_12' },
  { label: 'Ryczałt 12.5%', value: 'ryczalt_12_5' },
  { label: 'Ryczałt 14%', value: 'ryczalt_14' },
  { label: 'Ryczałt 15%', value: 'ryczalt_15' },
  { label: 'Ryczałt 17%', value: 'ryczalt_17' },
  { label: 'Podatek liniowy 19%', value: 'liniowy_19' },
  { label: 'Skala podatkowa', value: 'skala' },
];

const vatRates = [
  { label: '23%', value: 23 },
  { label: '8%', value: 8 },
  { label: '5%', value: 5 },
  { label: '0%', value: 0 },
];

const zusHealthCalculationOptions = [
  { label: 'Ryczałt (zależna od przychodów)', value: 'ryczalt' },
  { label: 'Stała kwota', value: 'fixed' },
];

const extractTaxRate = (taxType: string): number => {
  const match = taxType.match(/(\d+(?:_\d+)?)/);
  if (!match) return 12;
  return parseFloat(match[1].replace('_', '.'));
};

const loadSettings = async () => {
  if (!user.value) {
    console.log('No user found');
    return;
  }

  console.log('Loading settings for user:', user.value.id || user.value.sub);
  loading.value = true;

  const { data, error } = await supabase
    .from('company_settings')
    .select('*')
    .eq('user_id', user.value.id || user.value.sub)
    .single();

  if (error && error.code !== 'PGRST116') {
    console.error('Error loading settings:', error);
    console.error('Error details:', JSON.stringify(error, null, 2));
  } else if (data) {
    console.log('Settings loaded:', data);
    Object.assign(settings, {
      tax_type: data.income_tax_scheme || 'ryczalt_12',
      tax_rate: extractTaxRate(data.income_tax_scheme || 'ryczalt_12'),
      zus_amount: 0,
      zus_social_base: data.zus_social_base,
      zus_health_calculation: data.zus_health_calculation || 'ryczalt',
      zus_health_fixed: data.zus_health_fixed,
      vat_enabled: data.vat_active ?? true,
      vat_rate: data.default_vat_rate || 23,
      company_name: data.company_name || '',
    });
  } else {
    console.log('No settings found, using defaults');
  }
  loading.value = false;
};

let saveTimeout: ReturnType<typeof setTimeout> | null = null;

const updateSettings = async () => {
  if (!user.value) return;

  // Debounce saving
  if (saveTimeout) {
    clearTimeout(saveTimeout);
  }

  saveTimeout = setTimeout(async () => {
    const settingsData = {
      user_id: user.value!.id || user.value!.sub,
      income_tax_scheme: settings.tax_type,
      vat_active: settings.vat_enabled,
      default_vat_rate: settings.vat_rate,
      company_name: settings.company_name || null,
      zus_social_base: settings.zus_social_base || null,
      zus_health_calculation: settings.zus_health_calculation,
      zus_health_fixed: settings.zus_health_fixed || null,
    };

    console.log('Saving settings:', settingsData);

    const { error } = await supabase
      .from('company_settings')
      .upsert(settingsData, { onConflict: 'user_id' });

    if (error) {
      console.error('Error saving settings:', error);
      console.error('Error details:', JSON.stringify(error, null, 2));
    } else {
      console.log('Settings saved successfully');
      settings.tax_rate = extractTaxRate(settings.tax_type);
      saveStatus.value = true;
      setTimeout(() => {
        saveStatus.value = false;
      }, 2000);
    }
  }, 500);
};

watch(
  () => settings.tax_type,
  (newType) => {
    settings.tax_rate = extractTaxRate(newType);
  }
);

onMounted(() => {
  loadSettings();
});
</script>
