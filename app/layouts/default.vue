<template>
  <UApp>
    <div class="min-h-screen bg-gray-50 dark:bg-gray-900">
      <header
        class="bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700"
      >
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between items-center h-16">
            <!-- Mobile menu button -->
            <UButton
              class="md:hidden"
              color="neutral"
              variant="ghost"
              icon="i-heroicons-bars-3"
              @click="mobileMenuOpen = true"
            />

            <!-- Desktop navigation -->
            <nav class="hidden md:flex space-x-8">
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

            <div class="flex items-center space-x-2 sm:space-x-4">
              <UColorModeButton />
              <UButton
                v-if="user"
                color="primary"
                variant="ghost"
                @click="handleLogout"
                class="hidden sm:block"
              >
                Wyloguj
              </UButton>
              <UButton
                v-if="user"
                color="primary"
                variant="ghost"
                icon="i-heroicons-arrow-right-on-rectangle"
                @click="handleLogout"
                class="sm:hidden"
              />
            </div>
          </div>
        </div>
      </header>

      <!-- Mobile menu drawer -->
      <UDrawer v-model:open="mobileMenuOpen" side="left">
        <template #content>
          <div class="p-4">
            <div class="flex items-center justify-between mb-6">
              <h2 class="text-lg font-semibold">Menu</h2>
              <UButton
                color="neutral"
                variant="ghost"
                icon="i-heroicons-x-mark"
                @click="mobileMenuOpen = false"
              />
            </div>
            <nav class="space-y-2">
              <NuxtLink
                to="/"
                class="flex items-center px-4 py-3 text-sm font-medium rounded-lg"
                active-class="bg-primary-500 text-white"
                inactive-class="text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-800"
                @click="mobileMenuOpen = false"
              >
                Dashboard
              </NuxtLink>
              <NuxtLink
                to="/wydatki"
                class="flex items-center px-4 py-3 text-sm font-medium rounded-lg"
                active-class="bg-primary-500 text-white"
                inactive-class="text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-800"
                @click="mobileMenuOpen = false"
              >
                Wydatki
              </NuxtLink>
              <NuxtLink
                to="/przychody"
                class="flex items-center px-4 py-3 text-sm font-medium rounded-lg"
                active-class="bg-primary-500 text-white"
                inactive-class="text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-800"
                @click="mobileMenuOpen = false"
              >
                Przychody
              </NuxtLink>
              <NuxtLink
                to="/podatki"
                class="flex items-center px-4 py-3 text-sm font-medium rounded-lg"
                active-class="bg-primary-500 text-white"
                inactive-class="text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-800"
                @click="mobileMenuOpen = false"
              >
                Podatki
              </NuxtLink>
              <NuxtLink
                to="/kategorie"
                class="flex items-center px-4 py-3 text-sm font-medium rounded-lg"
                active-class="bg-primary-500 text-white"
                inactive-class="text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-800"
                @click="mobileMenuOpen = false"
              >
                Kategorie
              </NuxtLink>
            </nav>
          </div>
        </template>
      </UDrawer>

      <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-8">
        <NuxtPage />
      </main>
    </div>
  </UApp>
</template>

<script setup lang="ts">
const user = useSupabaseUser();
const supabase = useSupabaseClient();
const mobileMenuOpen = ref(false);

const handleLogout = async () => {
  await supabase.auth.signOut();
  navigateTo('/login');
};
</script>
