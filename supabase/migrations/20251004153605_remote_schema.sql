


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."compute_amounts"("p_amount_net" numeric, "p_amount_gross" numeric, "p_vat_rate" numeric) RETURNS TABLE("amount_net" numeric, "amount_gross" numeric, "vat_amount" numeric)
    LANGUAGE "plpgsql"
    AS $$
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


ALTER FUNCTION "public"."compute_amounts"("p_amount_net" numeric, "p_amount_gross" numeric, "p_vat_rate" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."expenses_normalize_amounts"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
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


ALTER FUNCTION "public"."expenses_normalize_amounts"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."incomes_normalize_amounts"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  if NEW.vat_rate = -1 then NEW.vat_rate := 0; end if;
  select amount_net, amount_gross, vat_amount
    into NEW.amount_net, NEW.amount_gross, NEW.vat_amount
  from public.compute_amounts(NEW.amount_net, NEW.amount_gross, NEW.vat_rate);
  NEW.updated_at := now();
  return NEW;
end;$$;


ALTER FUNCTION "public"."incomes_normalize_amounts"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."attachments" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "entity_type" "text" NOT NULL,
    "entity_id" "uuid" NOT NULL,
    "file_path" "text" NOT NULL,
    "original_filename" "text",
    "mime_type" "text",
    "size_bytes" bigint,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "attachments_entity_type_check" CHECK (("entity_type" = ANY (ARRAY['expense'::"text", 'income'::"text"])))
);


ALTER TABLE "public"."attachments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."categories" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "color" "text",
    "is_deductible_in_company" boolean DEFAULT false NOT NULL,
    "default_deductible_ratio" numeric(4,3) DEFAULT 1.000 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."company_settings" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "company_name" "text",
    "vat_active" boolean DEFAULT true NOT NULL,
    "income_tax_scheme" "text" DEFAULT 'ryczalt_12'::"text" NOT NULL,
    "default_vat_rate" numeric(5,2) DEFAULT 23.00 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "zus_social_base" numeric(12,2),
    "zus_health_calculation" "text" DEFAULT 'ryczalt'::"text" NOT NULL,
    "zus_health_fixed" numeric(12,2),
    CONSTRAINT "company_settings_zus_health_calculation_check" CHECK (("zus_health_calculation" = ANY (ARRAY['ryczalt'::"text", 'fixed'::"text"])))
);


ALTER TABLE "public"."company_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."expense_categories" (
    "expense_id" "uuid" NOT NULL,
    "category_id" "uuid" NOT NULL
);


ALTER TABLE "public"."expense_categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."expenses" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "note" "text",
    "currency_code" character(3) DEFAULT 'PLN'::"bpchar" NOT NULL,
    "amount_net" numeric(12,2),
    "amount_gross" numeric(12,2),
    "vat_amount" numeric(12,2),
    "vat_rate" numeric(5,2) DEFAULT 23.00 NOT NULL,
    "is_company" boolean DEFAULT false NOT NULL,
    "deductible_override" boolean,
    "deductible_ratio" numeric(4,3),
    "is_paid" boolean DEFAULT false NOT NULL,
    "issue_date" "date" DEFAULT CURRENT_DATE NOT NULL,
    "due_date" "date",
    "paid_at" "date",
    "invoice_number" "text",
    "counterparty" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "exchange_rate" numeric(10,4) DEFAULT 1.0,
    "amount_net_pln" numeric(12,2),
    "amount_gross_pln" numeric(12,2),
    "vat_amount_pln" numeric(12,2)
);


ALTER TABLE "public"."expenses" OWNER TO "postgres";


COMMENT ON COLUMN "public"."expenses"."exchange_rate" IS 'Exchange rate from currency_code to PLN at issue_date';



COMMENT ON COLUMN "public"."expenses"."amount_net_pln" IS 'Amount net converted to PLN using exchange_rate';



COMMENT ON COLUMN "public"."expenses"."amount_gross_pln" IS 'Amount gross converted to PLN using exchange_rate';



COMMENT ON COLUMN "public"."expenses"."vat_amount_pln" IS 'VAT amount converted to PLN using exchange_rate';



CREATE OR REPLACE VIEW "public"."expenses_with_deductible" AS
 SELECT "id",
    "user_id",
    "title",
    "note",
    "currency_code",
    "amount_net",
    "amount_gross",
    "vat_amount",
    "vat_rate",
    "is_company",
    "deductible_override",
    "deductible_ratio",
    "is_paid",
    "issue_date",
    "due_date",
    "paid_at",
    "invoice_number",
    "counterparty",
    "created_at",
    "updated_at",
    ("is_company" AND
        CASE
            WHEN ("deductible_override" IS TRUE) THEN (COALESCE("deductible_ratio", 1.0) > (0)::numeric)
            WHEN ("deductible_override" IS FALSE) THEN false
            ELSE (EXISTS ( SELECT 1
               FROM ("public"."expense_categories" "ec"
                 JOIN "public"."categories" "c" ON (("c"."id" = "ec"."category_id")))
              WHERE (("ec"."expense_id" = "e"."id") AND ("c"."is_deductible_in_company" = true))))
        END) AS "deductible_from_categories",
    COALESCE("deductible_ratio", ( SELECT "max"("c"."default_deductible_ratio") AS "max"
           FROM ("public"."expense_categories" "ec"
             JOIN "public"."categories" "c" ON (("c"."id" = "ec"."category_id")))
          WHERE ("ec"."expense_id" = "e"."id")), 1.0) AS "effective_deductible_ratio"
   FROM "public"."expenses" "e";


ALTER VIEW "public"."expenses_with_deductible" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."income_categories" (
    "income_id" "uuid" NOT NULL,
    "category_id" "uuid" NOT NULL
);


ALTER TABLE "public"."income_categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."incomes" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "note" "text",
    "currency_code" character(3) DEFAULT 'PLN'::"bpchar" NOT NULL,
    "amount_net" numeric(12,2),
    "amount_gross" numeric(12,2),
    "vat_amount" numeric(12,2),
    "vat_rate" numeric(5,2) DEFAULT 23.00 NOT NULL,
    "is_company" boolean DEFAULT false NOT NULL,
    "issue_date" "date" DEFAULT CURRENT_DATE NOT NULL,
    "invoice_number" "text",
    "counterparty" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "exchange_rate" numeric(10,4) DEFAULT 1.0,
    "amount_net_pln" numeric(12,2),
    "amount_gross_pln" numeric(12,2),
    "vat_amount_pln" numeric(12,2)
);


ALTER TABLE "public"."incomes" OWNER TO "postgres";


COMMENT ON COLUMN "public"."incomes"."exchange_rate" IS 'Exchange rate from currency_code to PLN at issue_date';



COMMENT ON COLUMN "public"."incomes"."amount_net_pln" IS 'Amount net converted to PLN using exchange_rate';



COMMENT ON COLUMN "public"."incomes"."amount_gross_pln" IS 'Amount gross converted to PLN using exchange_rate';



COMMENT ON COLUMN "public"."incomes"."vat_amount_pln" IS 'VAT amount converted to PLN using exchange_rate';



CREATE TABLE IF NOT EXISTS "public"."loans" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "bank_name" "text" NOT NULL,
    "loan_purpose" "text" NOT NULL,
    "is_company" boolean DEFAULT false NOT NULL,
    "monthly_amount" numeric(12,2) NOT NULL,
    "start_date" "date" NOT NULL,
    "end_date" "date" NOT NULL,
    "last_generated_date" "date",
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "valid_dates" CHECK (("end_date" > "start_date"))
);


ALTER TABLE "public"."loans" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."obligations" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "kind" "text" NOT NULL,
    "title" "text" NOT NULL,
    "amount" numeric(12,2) NOT NULL,
    "due_date" "date" NOT NULL,
    "is_paid" boolean DEFAULT false NOT NULL,
    "paid_at" "date",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "obligations_kind_check" CHECK (("kind" = ANY (ARRAY['VAT'::"text", 'ZUS'::"text", 'PPE'::"text", 'OTHER'::"text"])))
);


ALTER TABLE "public"."obligations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."recurring_expense_categories" (
    "recurring_expense_id" "uuid" NOT NULL,
    "category_id" "uuid" NOT NULL
);


ALTER TABLE "public"."recurring_expense_categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."recurring_expenses" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "counterparty" "text",
    "amount_net" numeric(12,2),
    "amount_gross" numeric(12,2),
    "vat_rate" numeric(5,2) DEFAULT 23.00 NOT NULL,
    "is_company" boolean DEFAULT false NOT NULL,
    "deductible_override" boolean,
    "deductible_ratio" numeric(4,3),
    "note" "text",
    "frequency" "text" DEFAULT 'monthly'::"text" NOT NULL,
    "day_of_month" integer,
    "is_active" boolean DEFAULT true NOT NULL,
    "last_generated_date" "date",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "currency_code" character(3) DEFAULT 'PLN'::"bpchar",
    "end_date" "date",
    CONSTRAINT "recurring_expenses_day_of_month_check" CHECK ((("day_of_month" >= 1) AND ("day_of_month" <= 31))),
    CONSTRAINT "recurring_expenses_frequency_check" CHECK (("frequency" = ANY (ARRAY['monthly'::"text", 'quarterly'::"text", 'yearly'::"text"])))
);


ALTER TABLE "public"."recurring_expenses" OWNER TO "postgres";


ALTER TABLE ONLY "public"."attachments"
    ADD CONSTRAINT "attachments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_user_id_name_key" UNIQUE ("user_id", "name");



ALTER TABLE ONLY "public"."company_settings"
    ADD CONSTRAINT "company_settings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."company_settings"
    ADD CONSTRAINT "company_settings_user_id_key" UNIQUE ("user_id");



ALTER TABLE ONLY "public"."expense_categories"
    ADD CONSTRAINT "expense_categories_pkey" PRIMARY KEY ("expense_id", "category_id");



ALTER TABLE ONLY "public"."expenses"
    ADD CONSTRAINT "expenses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."income_categories"
    ADD CONSTRAINT "income_categories_pkey" PRIMARY KEY ("income_id", "category_id");



ALTER TABLE ONLY "public"."incomes"
    ADD CONSTRAINT "incomes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."loans"
    ADD CONSTRAINT "loans_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."obligations"
    ADD CONSTRAINT "obligations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."recurring_expense_categories"
    ADD CONSTRAINT "recurring_expense_categories_pkey" PRIMARY KEY ("recurring_expense_id", "category_id");



ALTER TABLE ONLY "public"."recurring_expenses"
    ADD CONSTRAINT "recurring_expenses_pkey" PRIMARY KEY ("id");



CREATE INDEX "attachments_entity_type_entity_id_idx" ON "public"."attachments" USING "btree" ("entity_type", "entity_id");



CREATE INDEX "attachments_user_id_idx" ON "public"."attachments" USING "btree" ("user_id");



CREATE INDEX "categories_user_id_idx" ON "public"."categories" USING "btree" ("user_id");



CREATE INDEX "company_settings_user_id_idx" ON "public"."company_settings" USING "btree" ("user_id");



CREATE INDEX "expense_categories_category_id_idx" ON "public"."expense_categories" USING "btree" ("category_id");



CREATE INDEX "expenses_due_date_idx" ON "public"."expenses" USING "btree" ("due_date");



CREATE INDEX "expenses_is_paid_idx" ON "public"."expenses" USING "btree" ("is_paid");



CREATE INDEX "expenses_issue_date_idx" ON "public"."expenses" USING "btree" ("issue_date");



CREATE INDEX "expenses_user_id_idx" ON "public"."expenses" USING "btree" ("user_id");



CREATE INDEX "idx_expenses_currency" ON "public"."expenses" USING "btree" ("currency_code");



CREATE INDEX "idx_incomes_currency" ON "public"."incomes" USING "btree" ("currency_code");



CREATE INDEX "income_categories_category_id_idx" ON "public"."income_categories" USING "btree" ("category_id");



CREATE INDEX "incomes_issue_date_idx" ON "public"."incomes" USING "btree" ("issue_date");



CREATE INDEX "incomes_user_id_idx" ON "public"."incomes" USING "btree" ("user_id");



CREATE INDEX "loans_end_date_idx" ON "public"."loans" USING "btree" ("end_date");



CREATE INDEX "loans_is_active_idx" ON "public"."loans" USING "btree" ("is_active");



CREATE INDEX "loans_start_date_idx" ON "public"."loans" USING "btree" ("start_date");



CREATE INDEX "loans_user_id_idx" ON "public"."loans" USING "btree" ("user_id");



CREATE INDEX "obligations_due_date_idx" ON "public"."obligations" USING "btree" ("due_date");



CREATE INDEX "obligations_user_id_idx" ON "public"."obligations" USING "btree" ("user_id");



CREATE INDEX "recurring_expense_categories_category_id_idx" ON "public"."recurring_expense_categories" USING "btree" ("category_id");



CREATE INDEX "recurring_expenses_is_active_idx" ON "public"."recurring_expenses" USING "btree" ("is_active");



CREATE INDEX "recurring_expenses_user_id_idx" ON "public"."recurring_expenses" USING "btree" ("user_id");



CREATE OR REPLACE TRIGGER "trg_expenses_compute" BEFORE INSERT OR UPDATE ON "public"."expenses" FOR EACH ROW EXECUTE FUNCTION "public"."expenses_normalize_amounts"();



CREATE OR REPLACE TRIGGER "trg_incomes_compute" BEFORE INSERT OR UPDATE ON "public"."incomes" FOR EACH ROW EXECUTE FUNCTION "public"."incomes_normalize_amounts"();



ALTER TABLE ONLY "public"."attachments"
    ADD CONSTRAINT "attachments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."company_settings"
    ADD CONSTRAINT "company_settings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."expense_categories"
    ADD CONSTRAINT "expense_categories_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."expense_categories"
    ADD CONSTRAINT "expense_categories_expense_id_fkey" FOREIGN KEY ("expense_id") REFERENCES "public"."expenses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."expenses"
    ADD CONSTRAINT "expenses_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."income_categories"
    ADD CONSTRAINT "income_categories_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."income_categories"
    ADD CONSTRAINT "income_categories_income_id_fkey" FOREIGN KEY ("income_id") REFERENCES "public"."incomes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."incomes"
    ADD CONSTRAINT "incomes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."loans"
    ADD CONSTRAINT "loans_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."obligations"
    ADD CONSTRAINT "obligations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recurring_expense_categories"
    ADD CONSTRAINT "recurring_expense_categories_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recurring_expense_categories"
    ADD CONSTRAINT "recurring_expense_categories_recurring_expense_id_fkey" FOREIGN KEY ("recurring_expense_id") REFERENCES "public"."recurring_expenses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recurring_expenses"
    ADD CONSTRAINT "recurring_expenses_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE "public"."attachments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."categories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."company_settings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."expense_categories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."expenses" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."income_categories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."incomes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."loans" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."obligations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "owner can delete attachments" ON "public"."attachments" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can delete categories" ON "public"."categories" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can delete expense_categories" ON "public"."expense_categories" FOR DELETE USING (("auth"."uid"() = ( SELECT "e"."user_id"
   FROM "public"."expenses" "e"
  WHERE ("e"."id" = "expense_categories"."expense_id"))));



CREATE POLICY "owner can delete expenses" ON "public"."expenses" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can delete income_categories" ON "public"."income_categories" FOR DELETE USING (("auth"."uid"() = ( SELECT "i"."user_id"
   FROM "public"."incomes" "i"
  WHERE ("i"."id" = "income_categories"."income_id"))));



CREATE POLICY "owner can delete incomes" ON "public"."incomes" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can delete loans" ON "public"."loans" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can delete obligations" ON "public"."obligations" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can delete recurring_expense_categories" ON "public"."recurring_expense_categories" FOR DELETE USING (("auth"."uid"() = ( SELECT "r"."user_id"
   FROM "public"."recurring_expenses" "r"
  WHERE ("r"."id" = "recurring_expense_categories"."recurring_expense_id"))));



CREATE POLICY "owner can delete recurring_expenses" ON "public"."recurring_expenses" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can delete settings" ON "public"."company_settings" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can insert attachments" ON "public"."attachments" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can insert categories" ON "public"."categories" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can insert expense_categories" ON "public"."expense_categories" FOR INSERT WITH CHECK (("auth"."uid"() = ( SELECT "e"."user_id"
   FROM "public"."expenses" "e"
  WHERE ("e"."id" = "expense_categories"."expense_id"))));



CREATE POLICY "owner can insert expenses" ON "public"."expenses" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can insert income_categories" ON "public"."income_categories" FOR INSERT WITH CHECK (("auth"."uid"() = ( SELECT "i"."user_id"
   FROM "public"."incomes" "i"
  WHERE ("i"."id" = "income_categories"."income_id"))));



CREATE POLICY "owner can insert incomes" ON "public"."incomes" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can insert loans" ON "public"."loans" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can insert obligations" ON "public"."obligations" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can insert recurring_expense_categories" ON "public"."recurring_expense_categories" FOR INSERT WITH CHECK (("auth"."uid"() = ( SELECT "r"."user_id"
   FROM "public"."recurring_expenses" "r"
  WHERE ("r"."id" = "recurring_expense_categories"."recurring_expense_id"))));



CREATE POLICY "owner can insert recurring_expenses" ON "public"."recurring_expenses" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can insert settings" ON "public"."company_settings" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can read attachments" ON "public"."attachments" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can read categories" ON "public"."categories" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can read expense_categories" ON "public"."expense_categories" FOR SELECT USING (("auth"."uid"() = ( SELECT "e"."user_id"
   FROM "public"."expenses" "e"
  WHERE ("e"."id" = "expense_categories"."expense_id"))));



CREATE POLICY "owner can read expenses" ON "public"."expenses" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can read income_categories" ON "public"."income_categories" FOR SELECT USING (("auth"."uid"() = ( SELECT "i"."user_id"
   FROM "public"."incomes" "i"
  WHERE ("i"."id" = "income_categories"."income_id"))));



CREATE POLICY "owner can read incomes" ON "public"."incomes" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can read loans" ON "public"."loans" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can read obligations" ON "public"."obligations" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can read recurring_expense_categories" ON "public"."recurring_expense_categories" FOR SELECT USING (("auth"."uid"() = ( SELECT "r"."user_id"
   FROM "public"."recurring_expenses" "r"
  WHERE ("r"."id" = "recurring_expense_categories"."recurring_expense_id"))));



CREATE POLICY "owner can read recurring_expenses" ON "public"."recurring_expenses" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can read settings" ON "public"."company_settings" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can update attachments" ON "public"."attachments" FOR UPDATE USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can update categories" ON "public"."categories" FOR UPDATE USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can update expense_categories" ON "public"."expense_categories" FOR UPDATE USING (("auth"."uid"() = ( SELECT "e"."user_id"
   FROM "public"."expenses" "e"
  WHERE ("e"."id" = "expense_categories"."expense_id")))) WITH CHECK (("auth"."uid"() = ( SELECT "e"."user_id"
   FROM "public"."expenses" "e"
  WHERE ("e"."id" = "expense_categories"."expense_id"))));



CREATE POLICY "owner can update expenses" ON "public"."expenses" FOR UPDATE USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can update income_categories" ON "public"."income_categories" FOR UPDATE USING (("auth"."uid"() = ( SELECT "i"."user_id"
   FROM "public"."incomes" "i"
  WHERE ("i"."id" = "income_categories"."income_id")))) WITH CHECK (("auth"."uid"() = ( SELECT "i"."user_id"
   FROM "public"."incomes" "i"
  WHERE ("i"."id" = "income_categories"."income_id"))));



CREATE POLICY "owner can update incomes" ON "public"."incomes" FOR UPDATE USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can update loans" ON "public"."loans" FOR UPDATE USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can update obligations" ON "public"."obligations" FOR UPDATE USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can update recurring_expense_categories" ON "public"."recurring_expense_categories" FOR UPDATE USING (("auth"."uid"() = ( SELECT "r"."user_id"
   FROM "public"."recurring_expenses" "r"
  WHERE ("r"."id" = "recurring_expense_categories"."recurring_expense_id")))) WITH CHECK (("auth"."uid"() = ( SELECT "r"."user_id"
   FROM "public"."recurring_expenses" "r"
  WHERE ("r"."id" = "recurring_expense_categories"."recurring_expense_id"))));



CREATE POLICY "owner can update recurring_expenses" ON "public"."recurring_expenses" FOR UPDATE USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "owner can update settings" ON "public"."company_settings" FOR UPDATE USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."recurring_expense_categories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."recurring_expenses" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

























































































































































GRANT ALL ON FUNCTION "public"."compute_amounts"("p_amount_net" numeric, "p_amount_gross" numeric, "p_vat_rate" numeric) TO "anon";
GRANT ALL ON FUNCTION "public"."compute_amounts"("p_amount_net" numeric, "p_amount_gross" numeric, "p_vat_rate" numeric) TO "authenticated";
GRANT ALL ON FUNCTION "public"."compute_amounts"("p_amount_net" numeric, "p_amount_gross" numeric, "p_vat_rate" numeric) TO "service_role";



GRANT ALL ON FUNCTION "public"."expenses_normalize_amounts"() TO "anon";
GRANT ALL ON FUNCTION "public"."expenses_normalize_amounts"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."expenses_normalize_amounts"() TO "service_role";



GRANT ALL ON FUNCTION "public"."incomes_normalize_amounts"() TO "anon";
GRANT ALL ON FUNCTION "public"."incomes_normalize_amounts"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."incomes_normalize_amounts"() TO "service_role";


















GRANT ALL ON TABLE "public"."attachments" TO "anon";
GRANT ALL ON TABLE "public"."attachments" TO "authenticated";
GRANT ALL ON TABLE "public"."attachments" TO "service_role";



GRANT ALL ON TABLE "public"."categories" TO "anon";
GRANT ALL ON TABLE "public"."categories" TO "authenticated";
GRANT ALL ON TABLE "public"."categories" TO "service_role";



GRANT ALL ON TABLE "public"."company_settings" TO "anon";
GRANT ALL ON TABLE "public"."company_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."company_settings" TO "service_role";



GRANT ALL ON TABLE "public"."expense_categories" TO "anon";
GRANT ALL ON TABLE "public"."expense_categories" TO "authenticated";
GRANT ALL ON TABLE "public"."expense_categories" TO "service_role";



GRANT ALL ON TABLE "public"."expenses" TO "anon";
GRANT ALL ON TABLE "public"."expenses" TO "authenticated";
GRANT ALL ON TABLE "public"."expenses" TO "service_role";



GRANT ALL ON TABLE "public"."expenses_with_deductible" TO "anon";
GRANT ALL ON TABLE "public"."expenses_with_deductible" TO "authenticated";
GRANT ALL ON TABLE "public"."expenses_with_deductible" TO "service_role";



GRANT ALL ON TABLE "public"."income_categories" TO "anon";
GRANT ALL ON TABLE "public"."income_categories" TO "authenticated";
GRANT ALL ON TABLE "public"."income_categories" TO "service_role";



GRANT ALL ON TABLE "public"."incomes" TO "anon";
GRANT ALL ON TABLE "public"."incomes" TO "authenticated";
GRANT ALL ON TABLE "public"."incomes" TO "service_role";



GRANT ALL ON TABLE "public"."loans" TO "anon";
GRANT ALL ON TABLE "public"."loans" TO "authenticated";
GRANT ALL ON TABLE "public"."loans" TO "service_role";



GRANT ALL ON TABLE "public"."obligations" TO "anon";
GRANT ALL ON TABLE "public"."obligations" TO "authenticated";
GRANT ALL ON TABLE "public"."obligations" TO "service_role";



GRANT ALL ON TABLE "public"."recurring_expense_categories" TO "anon";
GRANT ALL ON TABLE "public"."recurring_expense_categories" TO "authenticated";
GRANT ALL ON TABLE "public"."recurring_expense_categories" TO "service_role";



GRANT ALL ON TABLE "public"."recurring_expenses" TO "anon";
GRANT ALL ON TABLE "public"."recurring_expenses" TO "authenticated";
GRANT ALL ON TABLE "public"."recurring_expenses" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































RESET ALL;
