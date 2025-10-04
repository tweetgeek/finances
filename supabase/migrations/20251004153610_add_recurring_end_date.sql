-- Migration: Add end_date to recurring_expenses
-- Date: 2025-01-02

-- Add end_date column to recurring_expenses
ALTER TABLE public.recurring_expenses
ADD COLUMN IF NOT EXISTS end_date date;
