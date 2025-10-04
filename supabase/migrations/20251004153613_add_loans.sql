-- Loans table
create table if not exists public.loans (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  bank_name text not null,
  loan_purpose text not null, -- e.g., 'dom', 'samochód', 'komputer'
  is_company boolean not null default false,
  monthly_amount numeric(12,2) not null,
  start_date date not null,
  end_date date not null,
  last_generated_date date,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint valid_dates check (end_date > start_date)
);

create index on public.loans(user_id);
create index on public.loans(is_active);
create index on public.loans(start_date);
create index on public.loans(end_date);

-- RLS Policies for Loans
alter table public.loans enable row level security;

create policy "owner can read loans" on public.loans for select using (auth.uid() = user_id);
create policy "owner can insert loans" on public.loans for insert with check (auth.uid() = user_id);
create policy "owner can update loans" on public.loans for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "owner can delete loans" on public.loans for delete using (auth.uid() = user_id);
