<template>
  <div
    class="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900 py-12 px-4 sm:px-6 lg:px-8"
  >
    <UCard class="w-full max-w-md">
      <template #header>
        <h2 class="text-2xl font-bold text-center">
          Logowanie do panelu finansowego
        </h2>
      </template>

      <form class="space-y-6" @submit.prevent="handleLogin">
        <UFormField label="Email" name="email" required>
          <UInput
            v-model="email"
            type="email"
            placeholder="your@email.com"
            required
          />
        </UFormField>

        <UFormField label="Hasło" name="password" required>
          <UInput
            v-model="password"
            type="password"
            placeholder="••••••••"
            required
          />
        </UFormField>

        <UButton type="submit" block :loading="loading"> Zaloguj się </UButton>

        <UAlert
          v-if="error"
          color="error"
          variant="soft"
          :title="error"
          :close-button="{
            icon: 'i-heroicons-x-mark-20-solid',
            color: 'error',
            variant: 'link',
          }"
          @close="error = ''"
        />
      </form>
    </UCard>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  layout: false,
});

const supabase = useSupabaseClient();
const email = ref('');
const password = ref('');
const loading = ref(false);
const error = ref('');

const handleLogin = async () => {
  loading.value = true;
  error.value = '';

  try {
    const { error: signInError } = await supabase.auth.signInWithPassword({
      email: email.value,
      password: password.value,
    });

    if (signInError) {
      error.value = signInError.message;
    } else {
      await navigateTo('/');
    }
  } catch (e) {
    error.value = (e as Error).message || 'Wystąpił błąd podczas logowania';
  } finally {
    loading.value = false;
  }
};
</script>
