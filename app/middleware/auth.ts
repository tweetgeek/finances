export default defineNuxtRouteMiddleware(() => {
  const user = useSupabaseUser()

  // If user is not logged in, redirect to login
  if (!user.value) {
    return navigateTo('/login')
  }
})
