-- Migration: Add unique constraint on user_id in company_settings
-- Date: 2025-01-02

-- Add unique constraint on user_id
ALTER TABLE public.company_settings
ADD CONSTRAINT company_settings_user_id_key UNIQUE (user_id);
