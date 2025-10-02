-- Add currency exchange rate columns to expenses
ALTER TABLE public.expenses
ADD COLUMN IF NOT EXISTS exchange_rate numeric(10,4) default 1.0,
ADD COLUMN IF NOT EXISTS amount_net_pln numeric(12,2),
ADD COLUMN IF NOT EXISTS amount_gross_pln numeric(12,2),
ADD COLUMN IF NOT EXISTS vat_amount_pln numeric(12,2);

-- Add currency exchange rate columns to incomes
ALTER TABLE public.incomes
ADD COLUMN IF NOT EXISTS exchange_rate numeric(10,4) default 1.0,
ADD COLUMN IF NOT EXISTS amount_net_pln numeric(12,2),
ADD COLUMN IF NOT EXISTS amount_gross_pln numeric(12,2),
ADD COLUMN IF NOT EXISTS vat_amount_pln numeric(12,2);

-- Add currency_code to recurring_expenses if not exists
ALTER TABLE public.recurring_expenses
ADD COLUMN IF NOT EXISTS currency_code char(3) default 'PLN';

-- Update existing records to have PLN amounts equal to original amounts
UPDATE public.expenses
SET
  amount_net_pln = amount_net,
  amount_gross_pln = amount_gross,
  vat_amount_pln = vat_amount,
  exchange_rate = 1.0
WHERE currency_code = 'PLN' AND amount_net_pln IS NULL;

UPDATE public.incomes
SET
  amount_net_pln = amount_net,
  amount_gross_pln = amount_gross,
  vat_amount_pln = vat_amount,
  exchange_rate = 1.0
WHERE currency_code = 'PLN' AND amount_net_pln IS NULL;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_expenses_currency ON public.expenses(currency_code);
CREATE INDEX IF NOT EXISTS idx_incomes_currency ON public.incomes(currency_code);

COMMENT ON COLUMN public.expenses.exchange_rate IS 'Exchange rate from currency_code to PLN at issue_date';
COMMENT ON COLUMN public.expenses.amount_net_pln IS 'Amount net converted to PLN using exchange_rate';
COMMENT ON COLUMN public.expenses.amount_gross_pln IS 'Amount gross converted to PLN using exchange_rate';
COMMENT ON COLUMN public.expenses.vat_amount_pln IS 'VAT amount converted to PLN using exchange_rate';

COMMENT ON COLUMN public.incomes.exchange_rate IS 'Exchange rate from currency_code to PLN at issue_date';
COMMENT ON COLUMN public.incomes.amount_net_pln IS 'Amount net converted to PLN using exchange_rate';
COMMENT ON COLUMN public.incomes.amount_gross_pln IS 'Amount gross converted to PLN using exchange_rate';
COMMENT ON COLUMN public.incomes.vat_amount_pln IS 'VAT amount converted to PLN using exchange_rate';
