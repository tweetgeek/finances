# 📝 Setup Guide - Finance Management System

Complete step-by-step guide to set up your personal finance management system.

## 🎯 Overview

This guide will walk you through:
1. Setting up Supabase (database & auth)
2. Configuring the application
3. Creating your first user
4. Adding default categories
5. Testing the system

**Estimated time**: 15-20 minutes

---

## Step 1: Create Supabase Project

### 1.1 Sign Up for Supabase

1. Go to [https://supabase.com](https://supabase.com)
2. Click "Start your project"
3. Sign up with GitHub, Google, or email
4. Verify your email if required

### 1.2 Create New Project

1. Click "New Project"
2. Select your organization (or create one)
3. Fill in project details:
   - **Name**: `finances` (or your preferred name)
   - **Database Password**: Generate a strong password (save it!)
   - **Region**: Choose closest to you
   - **Pricing Plan**: Free tier is sufficient for personal use
4. Click "Create new project"
5. Wait 2-3 minutes for provisioning

### 1.3 Get API Credentials

Once your project is ready:

1. Go to **Project Settings** (gear icon in sidebar)
2. Click **API** in the left menu
3. Copy these values (you'll need them for `.env`):
   - **Project URL** (e.g., `https://abcdefg.supabase.co`)
   - **anon public** key (long string starting with `eyJ...`)
   - **service_role** key (long string, keep this secret!)

**⚠️ Important**: Never commit your `service_role` key to git or share it publicly.

---

## Step 2: Set Up Database

### 2.1 Open SQL Editor

1. In your Supabase dashboard, click **SQL Editor** in the sidebar
2. Click **New query**

### 2.2 Run Schema Script

1. Open `supabase-schema.sql` from this repository
2. Copy the entire contents
3. Paste into the Supabase SQL Editor
4. Click **Run** (or press Cmd/Ctrl + Enter)

You should see a success message like:
```
Success. No rows returned
```

This creates:
- All tables (expenses, incomes, categories, etc.)
- Database functions for VAT calculations
- Views for deductibility calculations
- Row Level Security (RLS) policies
- Indexes for performance

### 2.3 Verify Tables

1. Click **Table Editor** in the sidebar
2. You should see these tables:
   - `attachments`
   - `categories`
   - `company_settings`
   - `expense_categories`
   - `expenses`
   - `income_categories`
   - `incomes`
   - `obligations`

---

## Step 3: Create Storage Bucket

### 3.1 Create Receipts Bucket

1. Click **Storage** in the Supabase sidebar
2. Click **New bucket**
3. Fill in:
   - **Name**: `receipts`
   - **Public bucket**: **OFF** (keep it private)
4. Click **Create bucket**

### 3.2 Configure Storage Policies

The storage policies are automatically handled by RLS, but you can verify:

1. Click on the `receipts` bucket
2. Go to **Policies** tab
3. You should see policies that allow owner access only

---

## Step 4: Create Your User Account

### 4.1 Create User

1. Click **Authentication** in the Supabase sidebar
2. Click **Users** tab
3. Click **Add user** (top right)
4. Choose **Create user**:
   - **Email**: Your email address
   - **Password**: Create a strong password (you'll use this to log in)
   - **Email Confirm**: Toggle OFF (so you can log in immediately)
5. Click **Create user**

### 4.2 Copy User UUID

1. Find your newly created user in the list
2. Click on the user
3. Copy the **UUID** (looks like: `123e4567-e89b-12d3-a456-426614174000`)
4. Save this UUID - you'll need it for `.env`

---

## Step 5: Configure Application

### 5.1 Clone Repository (if not done)

```bash
cd /path/to/your/projects
git clone <your-repo-url>
cd finances
```

### 5.2 Install Dependencies

```bash
npm install
```

This will install all required packages:
- Nuxt 4 and dependencies
- Supabase client
- Nuxt UI
- Pinia, VueUse, Zod, Chart.js

### 5.3 Create Environment File

```bash
cp .env.example .env
```

### 5.4 Edit `.env` File

Open `.env` in your editor and fill in the values:

```env
# From Supabase Project Settings > API
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... (anon key)
SUPABASE_SERVICE_ROLE=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... (service_role key)

# From Authentication > Users (your user UUID)
OWNER_USER_ID=123e4567-e89b-12d3-a456-426614174000

# Generate a random secret (for n8n webhooks)
WEBHOOK_SECRET=change-this-to-random-string-min-32-chars
```

**Generate a secure webhook secret**:
```bash
# On macOS/Linux
openssl rand -hex 32

# Or use online generator
# https://www.random.org/strings/
```

---

## Step 6: Add Default Categories (Optional)

### 6.1 Prepare SQL

1. Open `supabase-schema.sql`
2. Scroll to the bottom
3. Find the commented section with default categories:

```sql
-- Default Categories (run this AFTER creating your user)
-- Replace 'YOUR_USER_ID' with actual UUID from auth.users
/*
insert into public.categories (user_id, name, color, is_deductible_in_company, default_deductible_ratio) values
  ('YOUR_USER_ID', 'Firma', '#3b82f6', true, 1.000),
  ...
*/
```

### 6.2 Run Categories SQL

1. Copy the `insert` statement
2. Replace `YOUR_USER_ID` with your actual user UUID (from Step 4.2)
3. Uncomment (remove `/*` and `*/`)
4. Go to Supabase SQL Editor
5. Create **New query**
6. Paste the modified SQL
7. Click **Run**

You should now have 5 default categories:
- **Firma** (Company) - 100% deductible
- **Subskrypcja** (Subscription) - 100% deductible
- **Samochód** (Car) - 50% deductible
- **Kredyt** (Credit) - Not deductible
- **Zdrowie** (Health) - Not deductible

---

## Step 7: Start the Application

### 7.1 Start Dev Server

```bash
npm run dev
```

You should see:
```
Nuxt 4.1.2 with Nitro 2.x.x

  ➜ Local:   http://localhost:3000/
  ➜ Network: use --host to expose
```

### 7.2 Open in Browser

1. Open [http://localhost:3000](http://localhost:3000)
2. You should see the login page

### 7.3 Log In

1. Enter your email (from Step 4.1)
2. Enter your password (from Step 4.1)
3. Click **Zaloguj się** (Log in)
4. You should be redirected to the Dashboard

---

## Step 8: Test the System

### 8.1 Test Categories

1. Click **Kategorie** in the navigation
2. You should see your default categories (if you added them)
3. Try creating a new category:
   - Name: "Test"
   - Color: Pick any color
   - Odliczalna: Toggle ON
   - Proporcja: 100%
   - Click **Dodaj**
4. Verify the category appears in the list

### 8.2 Test Expenses

1. Click **Wydatki** in the navigation
2. Click **Dodaj wydatek**
3. Fill in a test expense:
   - Tytuł: "Test expense"
   - Kwota brutto: 123.00
   - Stawka VAT: 23%
   - Observe how netto and VAT are calculated automatically
4. Select a category
5. Mark as "Wydatek firmowy" (company expense)
6. Click **Zapisz wydatek**
7. Verify it appears in the expenses list

### 8.3 Test Incomes

1. Click **Przychody** in the navigation
2. Click **Dodaj przychód**
3. Fill in a test income:
   - Tytuł: "Test income"
   - Kwota brutto: 1230.00
   - Stawka VAT: 23%
   - Mark as "Przychód firmowy"
4. Click **Dodaj**
5. Verify it appears in the incomes list
6. Check the VAT summary at the bottom

### 8.4 Test Filtering

1. Go back to **Wydatki**
2. Try the filters:
   - Change date range
   - Filter by payment status
   - Filter by type (firmowe/prywatne)
3. Verify the list updates correctly

---

## Step 9: Test n8n Webhooks (Optional)

### 9.1 Using curl

Test the expense webhook:

```bash
curl -X POST http://localhost:3000/api/integrations/n8n/expenses \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: your-secret-from-env" \
  -d '{
    "title": "Webhook test expense",
    "amount_net": 100.0,
    "vat_rate": 23,
    "is_company": true,
    "categories": ["Firma"]
  }'
```

Expected response:
```json
{
  "success": true,
  "expense": { ... }
}
```

### 9.2 Using Postman or Insomnia

1. Create a new POST request
2. URL: `http://localhost:3000/api/integrations/n8n/expenses`
3. Headers:
   - `Content-Type: application/json`
   - `X-Webhook-Secret: your-secret`
4. Body (raw JSON):
```json
{
  "title": "Test from Postman",
  "amount_gross": 123.00,
  "vat_rate": 23,
  "is_company": true
}
```
5. Send request
6. Check Wydatki page to see the new expense

---

## 🎉 Setup Complete!

You now have a fully functional personal finance management system!

## Next Steps

### Customize Categories

Create categories that match your spending:
- Utilities (electricity, water, gas)
- Groceries
- Transport
- Entertainment
- etc.

Set deductibility rules for business categories.

### Import Historical Data

If you have existing financial data:
1. Use the n8n webhooks to automate import
2. Or manually enter transactions through the UI

### Set Up Automation

Connect n8n workflows to:
- Parse email invoices
- Import bank transactions
- Generate monthly reports

### Configure Company Settings

(Future feature - currently in roadmap)

---

## 🔧 Troubleshooting

### "Invalid login credentials" error

- Double-check email and password
- Verify user was created in Supabase Authentication
- Make sure "Email Confirm" was toggled OFF when creating user

### "RLS policy error" when creating records

- Verify `OWNER_USER_ID` in `.env` matches your user UUID exactly
- Check that RLS policies were created (re-run schema if needed)
- Restart dev server after changing `.env`

### Categories/expenses not showing

- Check browser console for errors (F12)
- Verify user is logged in (check Supabase auth state)
- Ensure tables were created properly (check Table Editor)

### Webhook returns 401 Unauthorized

- Verify `X-Webhook-Secret` header matches `.env` value exactly
- Check that `.env` is loaded (restart server)
- Ensure no extra spaces in secret value

### Dev server won't start

- Delete `node_modules` and `.nuxt` folders
- Run `npm install` again
- Check for port conflicts (kill any process using port 3000)

### Cannot upload attachments

- Verify `receipts` bucket exists in Storage
- Check that bucket is private (not public)
- Ensure storage policies are set correctly

---

## 📚 Additional Resources

- [Nuxt 4 Documentation](https://nuxt.com/docs)
- [Nuxt UI Documentation](https://ui.nuxt.com)
- [Supabase Documentation](https://supabase.com/docs)
- [n8n Documentation](https://docs.n8n.io)

---

## 💬 Need Help?

- Check the main README.md for API documentation
- Review CLAUDE.md for project structure
- Open an issue in the repository
- Check Supabase logs in dashboard > Logs

---

**Last updated**: 2025-10-01
