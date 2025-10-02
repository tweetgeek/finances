-- Extensions
create extension if not exists "uuid-ossp";
create extension if not exists pgcrypto;

-- Company Settings
create table if not exists public.company_settings (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  company_name text,
  vat_active boolean not null default true,
  income_tax_scheme text not null default 'ryczalt_12',
  default_vat_rate numeric(5,2) not null default 23.00,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index on public.company_settings(user_id);

-- Categories
create table if not exists public.categories (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  color text,
  is_deductible_in_company boolean not null default false,
  default_deductible_ratio numeric(4,3) not null default 1.000,
  created_at timestamptz not null default now(),
  unique (user_id, name)
);
create index on public.categories(user_id);

-- VAT Computation Helper
create or replace function public.compute_amounts(
  p_amount_net numeric,
  p_amount_gross numeric,
  p_vat_rate numeric
) returns table(amount_net numeric, amount_gross numeric, vat_amount numeric) language plpgsql as $$
begin
  if p_vat_rate is null then p_vat_rate := 0; end if;

  if p_amount_net is not null and p_amount_gross is null then
    amount_net := round(p_amount_net::numeric, 2);
    amount_gross := round((p_amount_net * (1 + p_vat_rate/100))::numeric, 2);
    vat_amount := amount_gross - amount_net;
  elsif p_amount_gross is not null and p_amount_net is null then
    amount_gross := round(p_amount_gross::numeric, 2);
    amount_net := round((p_amount_gross / (1 + p_vat_rate/100))::numeric, 2);
    vat_amount := amount_gross - amount_net;
  elsif p_amount_net is not null and p_amount_gross is not null then
    amount_net := round(p_amount_net::numeric, 2);
    amount_gross := round(p_amount_gross::numeric, 2);
    vat_amount := round((amount_gross - amount_net)::numeric, 2);
  else
    raise exception 'Provide at least net or gross';
  end if;
  return next;
end;$$;

-- Expenses
create table if not exists public.expenses (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  note text,
  currency_code char(3) not null default 'PLN',
  amount_net numeric(12,2),
  amount_gross numeric(12,2),
  vat_amount numeric(12,2),
  vat_rate numeric(5,2) not null default 23.00,
  is_company boolean not null default false,
  deductible_override boolean,
  deductible_ratio numeric(4,3),
  is_paid boolean not null default false,
  issue_date date not null default current_date,
  due_date date,
  paid_at date,
  invoice_number text,
  counterparty text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index on public.expenses(user_id);
create index on public.expenses(issue_date);
create index on public.expenses(due_date);
create index on public.expenses(is_paid);

-- Expenses Amount Normalization
create or replace function public.expenses_normalize_amounts() returns trigger language plpgsql as $$
begin
  if NEW.vat_rate = -1 then
    NEW.vat_rate := 0;
  end if;
  select amount_net, amount_gross, vat_amount
    into NEW.amount_net, NEW.amount_gross, NEW.vat_amount
  from public.compute_amounts(NEW.amount_net, NEW.amount_gross, NEW.vat_rate);
  NEW.updated_at := now();
  return NEW;
end;$$;

create trigger trg_expenses_compute before insert or update on public.expenses
for each row execute function public.expenses_normalize_amounts();

-- Incomes
create table if not exists public.incomes (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  note text,
  currency_code char(3) not null default 'PLN',
  amount_net numeric(12,2),
  amount_gross numeric(12,2),
  vat_amount numeric(12,2),
  vat_rate numeric(5,2) not null default 23.00,
  is_company boolean not null default false,
  issue_date date not null default current_date,
  invoice_number text,
  counterparty text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index on public.incomes(user_id);
create index on public.incomes(issue_date);

-- Incomes Amount Normalization
create or replace function public.incomes_normalize_amounts() returns trigger language plpgsql as $$
begin
  if NEW.vat_rate = -1 then NEW.vat_rate := 0; end if;
  select amount_net, amount_gross, vat_amount
    into NEW.amount_net, NEW.amount_gross, NEW.vat_amount
  from public.compute_amounts(NEW.amount_net, NEW.amount_gross, NEW.vat_rate);
  NEW.updated_at := now();
  return NEW;
end;$$;

create trigger trg_incomes_compute before insert or update on public.incomes
for each row execute function public.incomes_normalize_amounts();

-- Expense Categories (M:N)
create table if not exists public.expense_categories (
  expense_id uuid references public.expenses(id) on delete cascade,
  category_id uuid references public.categories(id) on delete cascade,
  primary key (expense_id, category_id)
);
create index on public.expense_categories(category_id);

-- Income Categories (M:N)
create table if not exists public.income_categories (
  income_id uuid references public.incomes(id) on delete cascade,
  category_id uuid references public.categories(id) on delete cascade,
  primary key (income_id, category_id)
);
create index on public.income_categories(category_id);

-- Attachments
create table if not exists public.attachments (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  entity_type text not null check (entity_type in ('expense','income')),
  entity_id uuid not null,
  file_path text not null,
  original_filename text,
  mime_type text,
  size_bytes bigint,
  created_at timestamptz not null default now()
);
create index on public.attachments(user_id);
create index on public.attachments(entity_type, entity_id);

-- Obligations (VAT, ZUS, PPE)
create table if not exists public.obligations (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('VAT','ZUS','PPE','OTHER')),
  title text not null,
  amount numeric(12,2) not null,
  due_date date not null,
  is_paid boolean not null default false,
  paid_at date,
  created_at timestamptz not null default now()
);
create index on public.obligations(user_id);
create index on public.obligations(due_date);

-- View: Expenses with Deductible Calculation
create or replace view public.expenses_with_deductible as
select e.*,
       (e.is_company and (
          case
            when e.deductible_override is true then coalesce(e.deductible_ratio, 1.0) > 0
            when e.deductible_override is false then false
            else exists (
              select 1 from expense_categories ec
              join categories c on c.id = ec.category_id
              where ec.expense_id = e.id and c.is_deductible_in_company = true
            )
          end
       )) as deductible_from_categories,
       coalesce(e.deductible_ratio,
                (select max(c.default_deductible_ratio) from expense_categories ec join categories c on c.id = ec.category_id where ec.expense_id = e.id),
                1.0) as effective_deductible_ratio
from expenses e;

-- RLS Policies
alter table public.company_settings enable row level security;
alter table public.categories enable row level security;
alter table public.expenses enable row level security;
alter table public.incomes enable row level security;
alter table public.expense_categories enable row level security;
alter table public.income_categories enable row level security;
alter table public.attachments enable row level security;
alter table public.obligations enable row level security;

-- Categories Policies
create policy "owner can read categories" on public.categories for select using (auth.uid() = user_id);
create policy "owner can insert categories" on public.categories for insert with check (auth.uid() = user_id);
create policy "owner can update categories" on public.categories for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "owner can delete categories" on public.categories for delete using (auth.uid() = user_id);

-- Company Settings Policies
create policy "owner can read settings" on public.company_settings for select using (auth.uid() = user_id);
create policy "owner can insert settings" on public.company_settings for insert with check (auth.uid() = user_id);
create policy "owner can update settings" on public.company_settings for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "owner can delete settings" on public.company_settings for delete using (auth.uid() = user_id);

-- Expenses Policies
create policy "owner can read expenses" on public.expenses for select using (auth.uid() = user_id);
create policy "owner can insert expenses" on public.expenses for insert with check (auth.uid() = user_id);
create policy "owner can update expenses" on public.expenses for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "owner can delete expenses" on public.expenses for delete using (auth.uid() = user_id);

-- Incomes Policies
create policy "owner can read incomes" on public.incomes for select using (auth.uid() = user_id);
create policy "owner can insert incomes" on public.incomes for insert with check (auth.uid() = user_id);
create policy "owner can update incomes" on public.incomes for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "owner can delete incomes" on public.incomes for delete using (auth.uid() = user_id);

-- Expense Categories Policies
create policy "owner can read expense_categories" on public.expense_categories for select using (
  auth.uid() = (select user_id from expenses e where e.id = expense_id)
);
create policy "owner can insert expense_categories" on public.expense_categories for insert with check (
  auth.uid() = (select user_id from expenses e where e.id = expense_id)
);
create policy "owner can update expense_categories" on public.expense_categories for update using (
  auth.uid() = (select user_id from expenses e where e.id = expense_id)
) with check (
  auth.uid() = (select user_id from expenses e where e.id = expense_id)
);
create policy "owner can delete expense_categories" on public.expense_categories for delete using (
  auth.uid() = (select user_id from expenses e where e.id = expense_id)
);

-- Income Categories Policies
create policy "owner can read income_categories" on public.income_categories for select using (
  auth.uid() = (select user_id from incomes i where i.id = income_id)
);
create policy "owner can insert income_categories" on public.income_categories for insert with check (
  auth.uid() = (select user_id from incomes i where i.id = income_id)
);
create policy "owner can update income_categories" on public.income_categories for update using (
  auth.uid() = (select user_id from incomes i where i.id = income_id)
) with check (
  auth.uid() = (select user_id from incomes i where i.id = income_id)
);
create policy "owner can delete income_categories" on public.income_categories for delete using (
  auth.uid() = (select user_id from incomes i where i.id = income_id)
);

-- Attachments Policies
create policy "owner can read attachments" on public.attachments for select using (auth.uid() = user_id);
create policy "owner can insert attachments" on public.attachments for insert with check (auth.uid() = user_id);
create policy "owner can update attachments" on public.attachments for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "owner can delete attachments" on public.attachments for delete using (auth.uid() = user_id);

-- Obligations Policies
create policy "owner can read obligations" on public.obligations for select using (auth.uid() = user_id);
create policy "owner can insert obligations" on public.obligations for insert with check (auth.uid() = user_id);
create policy "owner can update obligations" on public.obligations for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "owner can delete obligations" on public.obligations for delete using (auth.uid() = user_id);

-- Recurring Expense Templates
create table if not exists public.recurring_expenses (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  counterparty text,
  amount_net numeric(12,2),
  amount_gross numeric(12,2),
  vat_rate numeric(5,2) not null default 23.00,
  is_company boolean not null default false,
  deductible_override boolean,
  deductible_ratio numeric(4,3),
  note text,
  frequency text not null check (frequency in ('monthly', 'quarterly', 'yearly')) default 'monthly',
  day_of_month int check (day_of_month between 1 and 31),
  is_active boolean not null default true,
  last_generated_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index on public.recurring_expenses(user_id);
create index on public.recurring_expenses(is_active);

-- Recurring Expense Categories (M:N)
create table if not exists public.recurring_expense_categories (
  recurring_expense_id uuid references public.recurring_expenses(id) on delete cascade,
  category_id uuid references public.categories(id) on delete cascade,
  primary key (recurring_expense_id, category_id)
);
create index on public.recurring_expense_categories(category_id);

-- RLS Policies for Recurring Expenses
alter table public.recurring_expenses enable row level security;
alter table public.recurring_expense_categories enable row level security;

create policy "owner can read recurring_expenses" on public.recurring_expenses for select using (auth.uid() = user_id);
create policy "owner can insert recurring_expenses" on public.recurring_expenses for insert with check (auth.uid() = user_id);
create policy "owner can update recurring_expenses" on public.recurring_expenses for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "owner can delete recurring_expenses" on public.recurring_expenses for delete using (auth.uid() = user_id);

create policy "owner can read recurring_expense_categories" on public.recurring_expense_categories for select using (
  auth.uid() = (select user_id from recurring_expenses r where r.id = recurring_expense_id)
);
create policy "owner can insert recurring_expense_categories" on public.recurring_expense_categories for insert with check (
  auth.uid() = (select user_id from recurring_expenses r where r.id = recurring_expense_id)
);
create policy "owner can update recurring_expense_categories" on public.recurring_expense_categories for update using (
  auth.uid() = (select user_id from recurring_expenses r where r.id = recurring_expense_id)
) with check (
  auth.uid() = (select user_id from recurring_expenses r where r.id = recurring_expense_id)
);
create policy "owner can delete recurring_expense_categories" on public.recurring_expense_categories for delete using (
  auth.uid() = (select user_id from recurring_expenses r where r.id = recurring_expense_id)
);

-- Default Categories (run this AFTER creating your user)
-- Replace 'YOUR_USER_ID' with actual UUID from auth.users
/*
insert into public.categories (user_id, name, color, is_deductible_in_company, default_deductible_ratio) values
  ('2b05900f-22f2-4429-84b4-3b94b521490c', 'Firma', '#3b82f6', true, 1.000),
  ('2b05900f-22f2-4429-84b4-3b94b521490c', 'Subskrypcja', '#8b5cf6', true, 1.000),
  ('2b05900f-22f2-4429-84b4-3b94b521490c', 'Samochód', '#ef4444', true, 0.500),
  ('2b05900f-22f2-4429-84b4-3b94b521490c', 'Kredyt', '#f59e0b', false, 0.000),
  ('2b05900f-22f2-4429-84b4-3b94b521490c', 'Zdrowie', '#10b981', false, 0.000);


  -- Recurring Expenses from CSV
-- Note: Replace 'YOUR_USER_ID' with actual user UUID

-- 1Password
INSERT INTO public.recurring_expenses (user_id, title, counterparty, amount_gross, vat_rate, is_company, frequency, day_of_month, is_active, note)
VALUES ('2b05900f-22f2-4429-84b4-3b94b521490c', '1Password', '1Password', 4.91, 0, true, 'monthly', 5, true, 'currency: USD, profile: Firmowe, category: Bezpieczeństwo');

-- Xbox Game Pass
INSERT INTO public.recurring_expenses (user_id, title, counterparty, amount_gross, vat_rate, is_company, frequency, day_of_month, is_active, note)
VALUES ('2b05900f-22f2-4429-84b4-3b94b521490c', 'Xbox Game Pass', 'Xbox Game Pass', 39.99, 0, false, 'monthly', 2, true, 'currency: PLN, profile: Prywatne, category: Gry');

-- ChatGPT Plus
INSERT INTO public.recurring_expenses (user_id, title, counterparty, amount_gross, vat_rate, is_company, frequency, day_of_month, is_active, note)
VALUES ('2b05900f-22f2-4429-84b4-3b94b521490c', 'ChatGPT Plus', 'ChatGPT Plus', 20.00, 0, false, 'monthly', 27, true, 'currency: USD, profile: Prywatne, category: AI service');

-- Dropbox
INSERT INTO public.recurring_expenses (user_id, title, counterparty, amount_gross, vat_rate, is_company, frequency, day_of_month, is_active, note)
VALUES ('2b05900f-22f2-4429-84b4-3b94b521490c', 'Dropbox', 'Dropbox', 11.99, 0, false, 'monthly', 22, true, 'currency: EUR, profile: Prywatne, category: Przechowywanie w chmurze');

-- Netflix Rodzice
INSERT INTO public.recurring_expenses (user_id, title, counterparty, amount_gross, vat_rate, is_company, frequency, day_of_month, is_active, note)
VALUES ('2b05900f-22f2-4429-84b4-3b94b521490c', 'Netflix Rodzice', 'Netflix', 33.00, 0, false, 'monthly', 16, true, 'currency: PLN, profile: Prywatne, category: Video & TV');

-- Windsurf
INSERT INTO public.recurring_expenses (user_id, title, counterparty, amount_gross, vat_rate, is_company, frequency, day_of_month, is_active, note)
VALUES ('2b05900f-22f2-4429-84b4-3b94b521490c', 'Windsurf', 'Windsurf', 15.00, 0, false, 'monthly', 17, true, 'currency: USD, profile: Prywatne, category: Rozwój');

-- YouTube Premium
INSERT INTO public.recurring_expenses (user_id, title, counterparty, amount_gross, vat_rate, is_company, frequency, day_of_month, is_active, note)
VALUES ('2b05900f-22f2-4429-84b4-3b94b521490c', 'YouTube Premium', 'YouTube Premium', 38.99, 0, false, 'monthly', 13, true, 'currency: PLN, profile: Prywatne, category: Rozrywka');

-- Apple iCloud
INSERT INTO public.recurring_expenses (user_id, title, counterparty, amount_gross, vat_rate, is_company, frequency, day_of_month, is_active, note)
VALUES ('2b05900f-22f2-4429-84b4-3b94b521490c', 'Apple iCloud', 'Apple iCloud', 49.99, 0, false, 'monthly', 8, true, 'currency: PLN, profile: Prywatne, category: Przechowywanie w chmurze');

-- Disney Plus
INSERT INTO public.recurring_expenses (user_id, title, counterparty, amount_gross, vat_rate, is_company, frequency, day_of_month, is_active, note)
VALUES ('2b05900f-22f2-4429-84b4-3b94b521490c', 'Disney Plus', 'Disney Plus', 29.99, 0, false, 'monthly', 28, true, 'currency: PLN, profile: Prywatne, category: Video & TV');

-- Amazon Prime
INSERT INTO public.recurring_expenses (user_id, title, counterparty, amount_gross, vat_rate, is_company, frequency, day_of_month, is_active, note)
VALUES ('2b05900f-22f2-4429-84b4-3b94b521490c', 'Amazon Prime', 'Amazon Prime', 10.99, 0, false, 'yearly', 16, true, 'currency: PLN, profile: Prywatne, category: Zakupy');

-- Spotify
INSERT INTO public.recurring_expenses (user_id, title, counterparty, amount_gross, vat_rate, is_company, frequency, day_of_month, is_active, note)
VALUES ('2b05900f-22f2-4429-84b4-3b94b521490c', 'Spotify', 'Spotify', 37.99, 0, false, 'monthly', 22, true, 'currency: PLN, profile: Prywatne, category: Muzyka');

-- HBO Max
INSERT INTO public.recurring_expenses (user_id, title, counterparty, amount_gross, vat_rate, is_company, frequency, day_of_month, is_active, note)
VALUES ('2b05900f-22f2-4429-84b4-3b94b521490c', 'HBO Max', 'HBO Max', 19.99, 0, false, 'monthly', 18, true, 'currency: PLN, profile: Prywatne, category: Video & TV');

-- Netflix
INSERT INTO public.recurring_expenses (user_id, title, counterparty, amount_gross, vat_rate, is_company, frequency, day_of_month, is_active, note)
VALUES ('2b05900f-22f2-4429-84b4-3b94b521490c', 'Netflix', 'Netflix', 49.00, 0, false, 'monthly', 17, true, 'currency: PLN, profile: Prywatne, category: Video & TV');

-- TVN Player
INSERT INTO public.recurring_expenses (user_id, title, counterparty, amount_gross, vat_rate, is_company, frequency, day_of_month, is_active, note)
VALUES ('2b05900f-22f2-4429-84b4-3b94b521490c', 'TVN Player', 'TVN Player', 20.00, 0, false, 'monthly', 10, true, 'currency: PLN, profile: Prywatne');

-- AliorBank Monitor
INSERT INTO public.recurring_expenses (user_id, title, counterparty, amount_gross, vat_rate, is_company, frequency, day_of_month, is_active, note)
VALUES ('2b05900f-22f2-4429-84b4-3b94b521490c', 'AliorBank Monitor', 'AliorBank', 342.91, 0, false, 'monthly', 16, true, 'currency: PLN, category: Kredyty, endDate: 2025-12-16');

-- AliorBank Odkurzacz
INSERT INTO public.recurring_expenses (user_id, title, counterparty, amount_gross, vat_rate, is_company, frequency, day_of_month, is_active, note)
VALUES ('2b05900f-22f2-4429-84b4-3b94b521490c', 'AliorBank Odkurzacz', 'AliorBank', 471.86, 0, false, 'monthly', 7, true, 'currency: PLN, category: Kredyty, endDate: 2025-11-07');

-- Apple Developer
INSERT INTO public.recurring_expenses (user_id, title, counterparty, amount_gross, vat_rate, is_company, frequency, day_of_month, is_active, note)
VALUES ('2b05900f-22f2-4429-84b4-3b94b521490c', 'Apple Developer', 'Apple', 99.00, 0, false, 'yearly', 5, true, 'currency: USD, profile: Prywatne, category: Przechowywanie w chmurze');
*/
