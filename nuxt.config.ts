// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },

  modules: [
    '@nuxt/eslint',
    '@nuxt/image',
    '@nuxt/test-utils',
    '@nuxt/ui',
    '@nuxtjs/supabase',
    '@pinia/nuxt',
    '@vueuse/nuxt',
  ],
  css: ['~/assets/css/main.css'],
  runtimeConfig: {
    WEBHOOK_SECRET: process.env.WEBHOOK_SECRET,
    SUPABASE_SERVICE_ROLE: process.env.SUPABASE_SERVICE_ROLE,
    OWNER_USER_ID: process.env.OWNER_USER_ID,
    public: {
      supabaseUrl: process.env.SUPABASE_URL,
      supabaseKey: process.env.SUPABASE_KEY,
    },
  },
  supabase: {
    redirect: false,
  },
});
