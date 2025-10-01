<template>
  <UApp>
    <div class="min-h-screen bg-gray-50 dark:bg-gray-900">
      <header
        class="bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700"
      >
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between items-center h-16">
            <nav class="flex space-x-8">
              <NuxtLink
                to="/"
                class="inline-flex items-center px-1 pt-1 text-sm font-medium"
                active-class="border-b-2 border-primary-500 text-gray-900 dark:text-white"
                inactive-class="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
              >
                Dashboard
              </NuxtLink>
              <NuxtLink
                to="/wydatki"
                class="inline-flex items-center px-1 pt-1 text-sm font-medium"
                active-class="border-b-2 border-primary-500 text-gray-900 dark:text-white"
                inactive-class="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
              >
                Wydatki
              </NuxtLink>
              <NuxtLink
                to="/przychody"
                class="inline-flex items-center px-1 pt-1 text-sm font-medium"
                active-class="border-b-2 border-primary-500 text-gray-900 dark:text-white"
                inactive-class="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
              >
                Przychody
              </NuxtLink>
              <NuxtLink
                to="/podatki"
                class="inline-flex items-center px-1 pt-1 text-sm font-medium"
                active-class="border-b-2 border-primary-500 text-gray-900 dark:text-white"
                inactive-class="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
              >
                Podatki
              </NuxtLink>
              <NuxtLink
                to="/kategorie"
                class="inline-flex items-center px-1 pt-1 text-sm font-medium"
                active-class="border-b-2 border-primary-500 text-gray-900 dark:text-white"
                inactive-class="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
              >
                Kategorie
              </NuxtLink>
            </nav>

            <div class="flex items-center space-x-4">
              <UColorModeButton />
              <UButton
                v-if="user"
                color="primary"
                variant="ghost"
                @click="handleLogout"
              >
                Wyloguj
              </UButton>
            </div>
          </div>
        </div>
      </header>

      <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <NuxtPage />
      </main>
    </div>
  </UApp>
</template>

<script setup lang="ts">
const user = useSupabaseUser();
const supabase = useSupabaseClient();

const handleLogout = async () => {
  await supabase.auth.signOut();
  navigateTo('/login');
};
</script>
