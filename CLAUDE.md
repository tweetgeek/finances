# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Nuxt 4 application with Nuxt UI components, Supabase integration, and TypeScript. The project is in early stages with minimal custom code beyond the base setup.

## Common Commands

```bash
# Install dependencies
npm install

# Start development server (http://localhost:3000)
npm run dev

# Build for production
npm run build

# Preview production build locally
npm run preview

# Generate static site
npm run generate
```

## Technology Stack

- **Framework**: Nuxt 4.1.2 with Vue 3.5
- **UI Library**: Nuxt UI v4.0.0 (TailwindCSS-based)
- **Database**: Supabase (@supabase/supabase-js)
- **Image Optimization**: @nuxt/image
- **Linting**: ESLint with @nuxt/eslint
- **Testing**: @nuxt/test-utils

## Project Structure

- `app/` - Application source code
  - `app.vue` - Root component wrapping pages with UApp
  - `assets/css/main.css` - Global styles importing Tailwind and Nuxt UI
- `public/` - Static assets served at root
- `nuxt.config.ts` - Nuxt configuration
- `.env` - Environment variables (Supabase credentials)

## Configuration

### Environment Variables

Required in `.env`:
- `SUPABASE_URL` - Supabase project URL
- `SUPABASE_PUBLISHABLE_KEY` - Supabase public API key

These are exposed via `runtimeConfig.public` in nuxt.config.ts.

### Modules

Enabled modules (nuxt.config.ts:6):
- `@nuxt/eslint` - ESLint integration
- `@nuxt/image` - Image optimization
- `@nuxt/test-utils` - Testing utilities
- `@nuxt/ui` - UI component library

## Development Notes

- The application uses Nuxt's auto-import features for components and composables
- Nuxt UI components are available globally without explicit imports
- TypeScript configuration references are managed by Nuxt in `.nuxt/` directory
- ESLint config extends from `.nuxt/eslint.config.mjs`
