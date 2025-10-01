export interface Database {
  public: {
    Tables: {
      categories: {
        Row: {
          id: string
          user_id: string
          name: string
          color: string | null
          is_deductible_in_company: boolean
          default_deductible_ratio: number
          created_at: string
        }
        Insert: {
          id?: string
          user_id: string
          name: string
          color?: string | null
          is_deductible_in_company?: boolean
          default_deductible_ratio?: number
          created_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          name?: string
          color?: string | null
          is_deductible_in_company?: boolean
          default_deductible_ratio?: number
          created_at?: string
        }
      }
      expenses: {
        Row: {
          id: string
          user_id: string
          title: string
          note: string | null
          currency_code: string
          amount_net: number | null
          amount_gross: number | null
          vat_amount: number | null
          vat_rate: number
          is_company: boolean
          deductible_override: boolean | null
          deductible_ratio: number | null
          is_paid: boolean
          issue_date: string
          due_date: string | null
          paid_at: string | null
          invoice_number: string | null
          counterparty: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          title: string
          note?: string | null
          currency_code?: string
          amount_net?: number | null
          amount_gross?: number | null
          vat_amount?: number | null
          vat_rate?: number
          is_company?: boolean
          deductible_override?: boolean | null
          deductible_ratio?: number | null
          is_paid?: boolean
          issue_date?: string
          due_date?: string | null
          paid_at?: string | null
          invoice_number?: string | null
          counterparty?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          title?: string
          note?: string | null
          currency_code?: string
          amount_net?: number | null
          amount_gross?: number | null
          vat_amount?: number | null
          vat_rate?: number
          is_company?: boolean
          deductible_override?: boolean | null
          deductible_ratio?: number | null
          is_paid?: boolean
          issue_date?: string
          due_date?: string | null
          paid_at?: string | null
          invoice_number?: string | null
          counterparty?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      incomes: {
        Row: {
          id: string
          user_id: string
          title: string
          note: string | null
          currency_code: string
          amount_net: number | null
          amount_gross: number | null
          vat_amount: number | null
          vat_rate: number
          is_company: boolean
          issue_date: string
          invoice_number: string | null
          counterparty: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          title: string
          note?: string | null
          currency_code?: string
          amount_net?: number | null
          amount_gross?: number | null
          vat_amount?: number | null
          vat_rate?: number
          is_company?: boolean
          issue_date?: string
          invoice_number?: string | null
          counterparty?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          title?: string
          note?: string | null
          currency_code?: string
          amount_net?: number | null
          amount_gross?: number | null
          vat_amount?: number | null
          vat_rate?: number
          is_company?: boolean
          issue_date?: string
          invoice_number?: string | null
          counterparty?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      expense_categories: {
        Row: {
          expense_id: string
          category_id: string
        }
        Insert: {
          expense_id: string
          category_id: string
        }
        Update: {
          expense_id?: string
          category_id?: string
        }
      }
      income_categories: {
        Row: {
          income_id: string
          category_id: string
        }
        Insert: {
          income_id: string
          category_id: string
        }
        Update: {
          income_id?: string
          category_id?: string
        }
      }
      attachments: {
        Row: {
          id: string
          user_id: string
          entity_type: 'expense' | 'income'
          entity_id: string
          file_path: string
          original_filename: string | null
          mime_type: string | null
          size_bytes: number | null
          created_at: string
        }
        Insert: {
          id?: string
          user_id: string
          entity_type: 'expense' | 'income'
          entity_id: string
          file_path: string
          original_filename?: string | null
          mime_type?: string | null
          size_bytes?: number | null
          created_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          entity_type?: 'expense' | 'income'
          entity_id?: string
          file_path?: string
          original_filename?: string | null
          mime_type?: string | null
          size_bytes?: number | null
          created_at?: string
        }
      }
      obligations: {
        Row: {
          id: string
          user_id: string
          kind: 'VAT' | 'ZUS' | 'PPE' | 'OTHER'
          title: string
          amount: number
          due_date: string
          is_paid: boolean
          paid_at: string | null
          created_at: string
        }
        Insert: {
          id?: string
          user_id: string
          kind: 'VAT' | 'ZUS' | 'PPE' | 'OTHER'
          title: string
          amount: number
          due_date: string
          is_paid?: boolean
          paid_at?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          kind?: 'VAT' | 'ZUS' | 'PPE' | 'OTHER'
          title?: string
          amount?: number
          due_date?: string
          is_paid?: boolean
          paid_at?: string | null
          created_at?: string
        }
      }
      company_settings: {
        Row: {
          id: string
          user_id: string
          company_name: string | null
          vat_active: boolean
          income_tax_scheme: string
          default_vat_rate: number
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          company_name?: string | null
          vat_active?: boolean
          income_tax_scheme?: string
          default_vat_rate?: number
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          company_name?: string | null
          vat_active?: boolean
          income_tax_scheme?: string
          default_vat_rate?: number
          created_at?: string
          updated_at?: string
        }
      }
    }
    Views: {
      expenses_with_deductible: {
        Row: {
          id: string
          user_id: string
          title: string
          note: string | null
          currency_code: string
          amount_net: number | null
          amount_gross: number | null
          vat_amount: number | null
          vat_rate: number
          is_company: boolean
          deductible_override: boolean | null
          deductible_ratio: number | null
          is_paid: boolean
          issue_date: string
          due_date: string | null
          paid_at: string | null
          invoice_number: string | null
          counterparty: string | null
          created_at: string
          updated_at: string
          deductible_from_categories: boolean
          effective_deductible_ratio: number
        }
      }
    }
  }
}
