-- Migration: Add ZUS settings to company_settings
-- Date: 2025-01-02

-- Add ZUS columns to company_settings
ALTER TABLE public.company_settings
ADD COLUMN IF NOT EXISTS zus_social_base numeric(12,2),
ADD COLUMN IF NOT EXISTS zus_health_calculation text NOT NULL DEFAULT 'ryczalt',
ADD COLUMN IF NOT EXISTS zus_health_fixed numeric(12,2);

-- Add constraint for zus_health_calculation
ALTER TABLE public.company_settings
ADD CONSTRAINT company_settings_zus_health_calculation_check
CHECK (zus_health_calculation IN ('ryczalt', 'fixed'));
