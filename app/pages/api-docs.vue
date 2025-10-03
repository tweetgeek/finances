<template>
  <div>
    <h1 class="text-3xl font-bold mb-8">Dokumentacja API</h1>

    <UCard class="mb-6">
      <template #header>
        <h2 class="text-xl font-semibold">Informacje ogólne</h2>
      </template>

      <div class="space-y-4">
        <div>
          <p class="text-sm text-gray-600 mb-2">
            API oparte na Supabase REST API. Wszystkie endpointy wymagają
            autentykacji Bearer token.
          </p>
          <div class="bg-gray-100 dark:bg-gray-800 p-4 rounded-lg">
            <p class="text-sm font-mono">
              Base URL: {{ window?.location?.origin }}/api
            </p>
            <p class="text-sm font-mono mt-2">
              Headers:
              <br />
              - x-webhook-secret: [WEBHOOK_SECRET]
              <br />
              - Content-Type: application/json
            </p>
          </div>
        </div>
      </div>
    </UCard>

    <!-- Expenses Endpoints -->
    <UCard class="mb-6">
      <template #header>
        <h2 class="text-xl font-semibold">POST /api/expenses</h2>
      </template>

      <div class="space-y-4">
        <p class="text-sm text-gray-600">
          Tworzy nowy wydatek. Automatycznie przypisuje do właściciela (OWNER_USER_ID).
          Kategorie są tworzone automatycznie jeśli nie istnieją.
        </p>

        <div class="bg-gray-100 dark:bg-gray-800 p-3 rounded text-sm">
          <p class="font-semibold mb-2">Request Body (JSON):</p>
          <pre class="text-xs overflow-x-auto">{{
            JSON.stringify(
              {
                title: 'Faktura za hosting (wymagane)',
                counterparty: 'Nazwa firmy (opcjonalne)',
                invoice_number: 'FV/2025/001 (opcjonalne)',
                note: 'Dodatkowe informacje (opcjonalne)',
                issue_date: '2025-01-02 (opcjonalne, domyślnie dzisiaj)',
                due_date: '2025-02-02 (opcjonalne)',
                amount_net: 100.0,
                amount_gross: 123.0,
                vat_rate: 23,
                is_company: true,
                is_paid: false,
                paid_at: null,
                deductible_override: null,
                deductible_ratio: null,
                categories: ['IT', 'Hosting'],
              },
              null,
              2
            )
          }}</pre>
        </div>

        <div class="bg-gray-100 dark:bg-gray-800 p-3 rounded text-sm">
          <p class="font-semibold mb-2">Response 200 (JSON):</p>
          <pre class="text-xs overflow-x-auto">{{
            JSON.stringify(
              {
                success: true,
                expense: {
                  id: 'uuid',
                  user_id: 'uuid',
                  title: 'Faktura za hosting',
                  amount_gross: 123.0,
                  created_at: '2025-01-02T10:00:00Z',
                },
              },
              null,
              2
            )
          }}</pre>
        </div>
      </div>
    </UCard>

    <!-- Incomes Endpoints -->
    <UCard class="mb-6">
      <template #header>
        <h2 class="text-xl font-semibold">POST /api/incomes</h2>
      </template>

      <div class="space-y-4">
        <p class="text-sm text-gray-600">
          Tworzy nowy przychód. Automatycznie przypisuje do właściciela (OWNER_USER_ID).
          Kategorie są tworzone automatycznie jeśli nie istnieją.
        </p>

        <div class="bg-gray-100 dark:bg-gray-800 p-3 rounded text-sm">
          <p class="font-semibold mb-2">Request Body (JSON):</p>
          <pre class="text-xs overflow-x-auto">{{
            JSON.stringify(
              {
                title: 'Faktura sprzedaży (wymagane)',
                counterparty: 'Nazwa klienta (opcjonalne)',
                invoice_number: 'FS/2025/001 (opcjonalne)',
                note: 'Dodatkowe informacje (opcjonalne)',
                issue_date: '2025-01-02 (opcjonalne, domyślnie dzisiaj)',
                amount_net: 1000.0,
                amount_gross: 1230.0,
                vat_rate: 23,
                is_company: true,
                categories: ['Usługi IT', 'Konsultacje'],
              },
              null,
              2
            )
          }}</pre>
        </div>

        <div class="bg-gray-100 dark:bg-gray-800 p-3 rounded text-sm">
          <p class="font-semibold mb-2">Response 200 (JSON):</p>
          <pre class="text-xs overflow-x-auto">{{
            JSON.stringify(
              {
                success: true,
                income: {
                  id: 'uuid',
                  user_id: 'uuid',
                  title: 'Faktura sprzedaży',
                  amount_gross: 1230.0,
                  created_at: '2025-01-02T10:00:00Z',
                },
              },
              null,
              2
            )
          }}</pre>
        </div>
      </div>
    </UCard>

    <!-- Attachments Endpoints -->
    <UCard class="mb-6">
      <template #header>
        <h2 class="text-xl font-semibold">POST /api/attachments</h2>
      </template>

      <div class="space-y-4">
        <p class="text-sm text-gray-600">
          Dodaje załącznik (np. skan faktury) do wydatku lub przychodu. Plik
          wysyłany jako base64.
        </p>

        <div class="bg-gray-100 dark:bg-gray-800 p-3 rounded text-sm">
          <p class="font-semibold mb-2">Request Body (JSON):</p>
          <pre class="text-xs overflow-x-auto">{{
            JSON.stringify(
              {
                entity_type: 'expense lub income (wymagane)',
                entity_id: 'uuid wydatku/przychodu (wymagane)',
                filename: 'faktura.pdf (wymagane)',
                file_base64:
                  'data:application/pdf;base64,JVBERi0xLjQK... (wymagane)',
              },
              null,
              2
            )
          }}</pre>
        </div>

        <div class="bg-gray-100 dark:bg-gray-800 p-3 rounded text-sm">
          <p class="font-semibold mb-2">Response 200 (JSON):</p>
          <pre class="text-xs overflow-x-auto">{{
            JSON.stringify(
              {
                success: true,
                attachment: {
                  id: 'uuid',
                  user_id: 'uuid',
                  entity_type: 'expense',
                  entity_id: 'uuid',
                  file_path: 'path/to/file.pdf',
                  original_filename: 'faktura.pdf',
                  mime_type: 'application/pdf',
                  size_bytes: 12345,
                  created_at: '2025-01-02T10:00:00Z',
                },
              },
              null,
              2
            )
          }}</pre>
        </div>

        <div class="bg-yellow-50 dark:bg-yellow-900/20 p-3 rounded text-sm">
          <p class="font-semibold mb-2 text-yellow-800 dark:text-yellow-200">
            ⚠️ Uwagi:
          </p>
          <ul class="list-disc list-inside space-y-1 text-yellow-700 dark:text-yellow-300 text-xs">
            <li>Plik musi być w formacie base64 (może zawierać data URI)</li>
            <li>Maksymalny rozmiar pliku: zgodny z limitem Supabase Storage</li>
            <li>entity_type: tylko "expense" lub "income"</li>
            <li>entity_id musi istnieć w odpowiedniej tabeli</li>
          </ul>
        </div>
      </div>
    </UCard>

    <!-- Error Responses -->
    <UCard class="mb-6">
      <template #header>
        <h2 class="text-xl font-semibold">Kody błędów</h2>
      </template>

      <div class="space-y-3">
        <div class="bg-red-50 dark:bg-red-900/20 p-3 rounded text-sm">
          <p class="font-semibold text-red-800 dark:text-red-200">401 Unauthorized</p>
          <p class="text-red-700 dark:text-red-300 text-xs mt-1">
            Brak lub nieprawidłowy header x-webhook-secret
          </p>
        </div>

        <div class="bg-red-50 dark:bg-red-900/20 p-3 rounded text-sm">
          <p class="font-semibold text-red-800 dark:text-red-200">400 Bad Request</p>
          <p class="text-red-700 dark:text-red-300 text-xs mt-1">
            Nieprawidłowe dane wejściowe lub brakujące wymagane pola
          </p>
        </div>

        <div class="bg-red-50 dark:bg-red-900/20 p-3 rounded text-sm">
          <p class="font-semibold text-red-800 dark:text-red-200">
            500 Internal Server Error
          </p>
          <p class="text-red-700 dark:text-red-300 text-xs mt-1">
            Błąd serwera lub błędna konfiguracja (np. brak OWNER_USER_ID)
          </p>
        </div>
      </div>
    </UCard>

    <!-- cURL Examples -->
    <UCard>
      <template #header>
        <h2 class="text-xl font-semibold">Przykłady cURL</h2>
      </template>

      <div class="space-y-4">
        <div>
          <p class="font-semibold text-sm mb-2">Dodanie wydatku:</p>
          <div class="bg-gray-900 p-3 rounded text-xs text-green-400 overflow-x-auto">
            <pre>curl -X POST {{ window?.location?.origin }}/api/expenses \
  -H "Content-Type: application/json" \
  -H "x-webhook-secret: YOUR_SECRET" \
  -d '{
    "title": "Hosting",
    "amount_net": 100,
    "amount_gross": 123,
    "vat_rate": 23,
    "is_company": true,
    "categories": ["IT"]
  }'</pre>
          </div>
        </div>

        <div>
          <p class="font-semibold text-sm mb-2">Dodanie przychodu:</p>
          <div class="bg-gray-900 p-3 rounded text-xs text-green-400 overflow-x-auto">
            <pre>curl -X POST {{ window?.location?.origin }}/api/incomes \
  -H "Content-Type: application/json" \
  -H "x-webhook-secret: YOUR_SECRET" \
  -d '{
    "title": "Faktura FS/01/2025",
    "amount_net": 1000,
    "amount_gross": 1230,
    "vat_rate": 23,
    "categories": ["Usługi"]
  }'</pre>
          </div>
        </div>
      </div>
    </UCard>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  middleware: 'auth',
});
</script>
