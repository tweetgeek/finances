# 💸 Finances - Personal Finance Management System

A full-featured personal finance management application built with Nuxt 4, Supabase, and Nuxt UI. Track expenses, incomes, VAT calculations, and manage your personal and business finances in one place.

## 🚀 Features

- **Expense Management**: Track expenses with automatic VAT calculations, category assignments, and payment status
- **Income Tracking**: Record income with full VAT support and categorization
- **Smart VAT Calculation**: Automatic net↔gross conversion with configurable VAT rates (23%, 8%, 5%, 0%, exempt)
- **Category System**: Flexible category management with tax deductibility rules and custom ratios
- **Company/Private Split**: Separate business and personal transactions
- **Tax Deduction Rules**: Automatic and manual deductibility calculations per expense
- **Filtering & Search**: Date range filters, payment status, and transaction type filtering
- **n8n Integration**: Webhook API for automation (expenses, incomes, attachments)
- **Secure Authentication**: Supabase Auth with Row Level Security (RLS)
- **Dark Mode**: Full dark mode support with Nuxt UI
- **Responsive Design**: Works on desktop and mobile devices

## 🛠 Tech Stack

- **Framework**: Nuxt 4.1.2 with Vue 3.5
- **UI Library**: Nuxt UI v4.0.0 (TailwindCSS-based)
- **Database**: Supabase (PostgreSQL with RLS)
- **Storage**: Supabase Storage for attachments
- **State Management**: Pinia
- **TypeScript**: Full type safety

## 📋 Prerequisites

- Node.js 18+ and npm
- Supabase account and project

## 🔧 Installation

### 1. Install Dependencies

```bash
npm install
```

### 2. Set Up Supabase

#### Create a Supabase Project
1. Go to [supabase.com](https://supabase.com) and create a new project
2. Wait for the project to be provisioned

#### Run the Database Schema
1. Open the SQL Editor in your Supabase dashboard
2. Copy the contents of `supabase-schema.sql`
3. Run the SQL to create all tables, functions, views, and RLS policies

#### Create Storage Bucket
1. Go to Storage in your Supabase dashboard
2. Create a new bucket named `receipts`
3. Set it as **private** (not public)

#### Create Your User Account
1. Go to Authentication > Users in Supabase dashboard
2. Create a user with your email and password
3. Copy the user's UUID (you'll need it for `.env`)

### 3. Configure Environment Variables

Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

Edit `.env` with your values:

```env
# Get these from Supabase Project Settings > API
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-anon-key
SUPABASE_SERVICE_ROLE=your-service-role-key

# Copy from Authentication > Users in Supabase
OWNER_USER_ID=your-user-uuid

# Generate a random secret for n8n webhooks
WEBHOOK_SECRET=your-random-secret-here
```

### 4. Start Development Server

```bash
npm run dev
```

Visit http://localhost:3000 and log in with your Supabase credentials.

## 📖 Usage

### Managing Expenses

1. Navigate to **Wydatki** (Expenses)
2. Click **Dodaj wydatek** (Add expense)
3. Fill in the form with automatic VAT calculations
4. Assign categories and set deductibility rules

### Managing Incomes

1. Navigate to **Przychody** (Incomes)
2. Add incomes with automatic VAT calculations
3. Mark as company/private

### Categories

1. Navigate to **Kategorie** (Categories)
2. Create categories with deductibility flags and ratios

## 🔌 n8n Webhook Integration

All endpoints require the `X-Webhook-Secret` header.

### Create Expense
```http
POST /api/integrations/n8n/expenses
X-Webhook-Secret: your-secret

{
  "title": "Internet bill",
  "amount_net": 100.0,
  "vat_rate": 23,
  "is_company": true,
  "categories": ["Firma"]
}
```

### Create Income
```http
POST /api/integrations/n8n/incomes
X-Webhook-Secret: your-secret

{
  "title": "Client payment",
  "amount_gross": 1230.0,
  "vat_rate": 23,
  "is_company": true
}
```

### Upload Attachment
```http
POST /api/integrations/n8n/attachments
X-Webhook-Secret: your-secret

{
  "entity_type": "expense",
  "entity_id": "uuid",
  "file_base64": "data:application/pdf;base64,...",
  "filename": "invoice.pdf"
}
```

## 🗂 Project Structure

```
finances/
├── app/pages/          # Routes
├── layouts/            # Layout components
├── composables/        # Reusable logic
├── middleware/         # Auth middleware
├── server/api/         # API endpoints
├── types/              # TypeScript types
└── supabase-schema.sql # Database schema
```

## 🚧 Roadmap

- [ ] Dashboard with charts
- [ ] VAT calculation panel
- [ ] ZUS and PPE tracking
- [ ] Multi-currency support
- [ ] OCR invoice scanning
- [ ] JPK_V7 export

## 📝 License

MIT License
