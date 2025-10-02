export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "13.0.5"
  }
  public: {
    Tables: {
      attachments: {
        Row: {
          created_at: string
          entity_id: string
          entity_type: string
          file_path: string
          id: string
          mime_type: string | null
          original_filename: string | null
          size_bytes: number | null
          user_id: string
        }
        Insert: {
          created_at?: string
          entity_id: string
          entity_type: string
          file_path: string
          id?: string
          mime_type?: string | null
          original_filename?: string | null
          size_bytes?: number | null
          user_id: string
        }
        Update: {
          created_at?: string
          entity_id?: string
          entity_type?: string
          file_path?: string
          id?: string
          mime_type?: string | null
          original_filename?: string | null
          size_bytes?: number | null
          user_id?: string
        }
        Relationships: []
      }
      categories: {
        Row: {
          color: string | null
          created_at: string
          default_deductible_ratio: number
          id: string
          is_deductible_in_company: boolean
          name: string
          user_id: string
        }
        Insert: {
          color?: string | null
          created_at?: string
          default_deductible_ratio?: number
          id?: string
          is_deductible_in_company?: boolean
          name: string
          user_id: string
        }
        Update: {
          color?: string | null
          created_at?: string
          default_deductible_ratio?: number
          id?: string
          is_deductible_in_company?: boolean
          name?: string
          user_id?: string
        }
        Relationships: []
      }
      company_settings: {
        Row: {
          company_name: string | null
          created_at: string
          default_vat_rate: number
          id: string
          income_tax_scheme: string
          updated_at: string
          user_id: string
          vat_active: boolean
          zus_health_calculation: string
          zus_health_fixed: number | null
          zus_social_base: number | null
        }
        Insert: {
          company_name?: string | null
          created_at?: string
          default_vat_rate?: number
          id?: string
          income_tax_scheme?: string
          updated_at?: string
          user_id: string
          vat_active?: boolean
          zus_health_calculation?: string
          zus_health_fixed?: number | null
          zus_social_base?: number | null
        }
        Update: {
          company_name?: string | null
          created_at?: string
          default_vat_rate?: number
          id?: string
          income_tax_scheme?: string
          updated_at?: string
          user_id?: string
          vat_active?: boolean
          zus_health_calculation?: string
          zus_health_fixed?: number | null
          zus_social_base?: number | null
        }
        Relationships: []
      }
      expense_categories: {
        Row: {
          category_id: string
          expense_id: string
        }
        Insert: {
          category_id: string
          expense_id: string
        }
        Update: {
          category_id?: string
          expense_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "expense_categories_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "expense_categories_expense_id_fkey"
            columns: ["expense_id"]
            isOneToOne: false
            referencedRelation: "expenses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "expense_categories_expense_id_fkey"
            columns: ["expense_id"]
            isOneToOne: false
            referencedRelation: "expenses_with_deductible"
            referencedColumns: ["id"]
          },
        ]
      }
      expenses: {
        Row: {
          amount_gross: number | null
          amount_gross_pln: number | null
          amount_net: number | null
          amount_net_pln: number | null
          counterparty: string | null
          created_at: string
          currency_code: string
          deductible_override: boolean | null
          deductible_ratio: number | null
          due_date: string | null
          exchange_rate: number | null
          id: string
          invoice_number: string | null
          is_company: boolean
          is_paid: boolean
          issue_date: string
          note: string | null
          paid_at: string | null
          title: string
          updated_at: string
          user_id: string
          vat_amount: number | null
          vat_amount_pln: number | null
          vat_rate: number
        }
        Insert: {
          amount_gross?: number | null
          amount_gross_pln?: number | null
          amount_net?: number | null
          amount_net_pln?: number | null
          counterparty?: string | null
          created_at?: string
          currency_code?: string
          deductible_override?: boolean | null
          deductible_ratio?: number | null
          due_date?: string | null
          exchange_rate?: number | null
          id?: string
          invoice_number?: string | null
          is_company?: boolean
          is_paid?: boolean
          issue_date?: string
          note?: string | null
          paid_at?: string | null
          title: string
          updated_at?: string
          user_id: string
          vat_amount?: number | null
          vat_amount_pln?: number | null
          vat_rate?: number
        }
        Update: {
          amount_gross?: number | null
          amount_gross_pln?: number | null
          amount_net?: number | null
          amount_net_pln?: number | null
          counterparty?: string | null
          created_at?: string
          currency_code?: string
          deductible_override?: boolean | null
          deductible_ratio?: number | null
          due_date?: string | null
          exchange_rate?: number | null
          id?: string
          invoice_number?: string | null
          is_company?: boolean
          is_paid?: boolean
          issue_date?: string
          note?: string | null
          paid_at?: string | null
          title?: string
          updated_at?: string
          user_id?: string
          vat_amount?: number | null
          vat_amount_pln?: number | null
          vat_rate?: number
        }
        Relationships: []
      }
      income_categories: {
        Row: {
          category_id: string
          income_id: string
        }
        Insert: {
          category_id: string
          income_id: string
        }
        Update: {
          category_id?: string
          income_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "income_categories_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "income_categories_income_id_fkey"
            columns: ["income_id"]
            isOneToOne: false
            referencedRelation: "incomes"
            referencedColumns: ["id"]
          },
        ]
      }
      incomes: {
        Row: {
          amount_gross: number | null
          amount_gross_pln: number | null
          amount_net: number | null
          amount_net_pln: number | null
          counterparty: string | null
          created_at: string
          currency_code: string
          exchange_rate: number | null
          id: string
          invoice_number: string | null
          is_company: boolean
          issue_date: string
          note: string | null
          title: string
          updated_at: string
          user_id: string
          vat_amount: number | null
          vat_amount_pln: number | null
          vat_rate: number
        }
        Insert: {
          amount_gross?: number | null
          amount_gross_pln?: number | null
          amount_net?: number | null
          amount_net_pln?: number | null
          counterparty?: string | null
          created_at?: string
          currency_code?: string
          exchange_rate?: number | null
          id?: string
          invoice_number?: string | null
          is_company?: boolean
          issue_date?: string
          note?: string | null
          title: string
          updated_at?: string
          user_id: string
          vat_amount?: number | null
          vat_amount_pln?: number | null
          vat_rate?: number
        }
        Update: {
          amount_gross?: number | null
          amount_gross_pln?: number | null
          amount_net?: number | null
          amount_net_pln?: number | null
          counterparty?: string | null
          created_at?: string
          currency_code?: string
          exchange_rate?: number | null
          id?: string
          invoice_number?: string | null
          is_company?: boolean
          issue_date?: string
          note?: string | null
          title?: string
          updated_at?: string
          user_id?: string
          vat_amount?: number | null
          vat_amount_pln?: number | null
          vat_rate?: number
        }
        Relationships: []
      }
      obligations: {
        Row: {
          amount: number
          created_at: string
          due_date: string
          id: string
          is_paid: boolean
          kind: string
          paid_at: string | null
          title: string
          user_id: string
        }
        Insert: {
          amount: number
          created_at?: string
          due_date: string
          id?: string
          is_paid?: boolean
          kind: string
          paid_at?: string | null
          title: string
          user_id: string
        }
        Update: {
          amount?: number
          created_at?: string
          due_date?: string
          id?: string
          is_paid?: boolean
          kind?: string
          paid_at?: string | null
          title?: string
          user_id?: string
        }
        Relationships: []
      }
      recurring_expense_categories: {
        Row: {
          category_id: string
          recurring_expense_id: string
        }
        Insert: {
          category_id: string
          recurring_expense_id: string
        }
        Update: {
          category_id?: string
          recurring_expense_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "recurring_expense_categories_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "recurring_expense_categories_recurring_expense_id_fkey"
            columns: ["recurring_expense_id"]
            isOneToOne: false
            referencedRelation: "recurring_expenses"
            referencedColumns: ["id"]
          },
        ]
      }
      recurring_expenses: {
        Row: {
          amount_gross: number | null
          amount_net: number | null
          counterparty: string | null
          created_at: string
          currency_code: string | null
          day_of_month: number | null
          deductible_override: boolean | null
          deductible_ratio: number | null
          end_date: string | null
          frequency: string
          id: string
          is_active: boolean
          is_company: boolean
          last_generated_date: string | null
          note: string | null
          title: string
          updated_at: string
          user_id: string
          vat_rate: number
        }
        Insert: {
          amount_gross?: number | null
          amount_net?: number | null
          counterparty?: string | null
          created_at?: string
          currency_code?: string | null
          day_of_month?: number | null
          deductible_override?: boolean | null
          deductible_ratio?: number | null
          end_date?: string | null
          frequency?: string
          id?: string
          is_active?: boolean
          is_company?: boolean
          last_generated_date?: string | null
          note?: string | null
          title: string
          updated_at?: string
          user_id: string
          vat_rate?: number
        }
        Update: {
          amount_gross?: number | null
          amount_net?: number | null
          counterparty?: string | null
          created_at?: string
          currency_code?: string | null
          day_of_month?: number | null
          deductible_override?: boolean | null
          deductible_ratio?: number | null
          end_date?: string | null
          frequency?: string
          id?: string
          is_active?: boolean
          is_company?: boolean
          last_generated_date?: string | null
          note?: string | null
          title?: string
          updated_at?: string
          user_id?: string
          vat_rate?: number
        }
        Relationships: []
      }
    }
    Views: {
      expenses_with_deductible: {
        Row: {
          amount_gross: number | null
          amount_net: number | null
          counterparty: string | null
          created_at: string | null
          currency_code: string | null
          deductible_from_categories: boolean | null
          deductible_override: boolean | null
          deductible_ratio: number | null
          due_date: string | null
          effective_deductible_ratio: number | null
          id: string | null
          invoice_number: string | null
          is_company: boolean | null
          is_paid: boolean | null
          issue_date: string | null
          note: string | null
          paid_at: string | null
          title: string | null
          updated_at: string | null
          user_id: string | null
          vat_amount: number | null
          vat_rate: number | null
        }
        Insert: {
          amount_gross?: number | null
          amount_net?: number | null
          counterparty?: string | null
          created_at?: string | null
          currency_code?: string | null
          deductible_from_categories?: never
          deductible_override?: boolean | null
          deductible_ratio?: number | null
          due_date?: string | null
          effective_deductible_ratio?: never
          id?: string | null
          invoice_number?: string | null
          is_company?: boolean | null
          is_paid?: boolean | null
          issue_date?: string | null
          note?: string | null
          paid_at?: string | null
          title?: string | null
          updated_at?: string | null
          user_id?: string | null
          vat_amount?: number | null
          vat_rate?: number | null
        }
        Update: {
          amount_gross?: number | null
          amount_net?: number | null
          counterparty?: string | null
          created_at?: string | null
          currency_code?: string | null
          deductible_from_categories?: never
          deductible_override?: boolean | null
          deductible_ratio?: number | null
          due_date?: string | null
          effective_deductible_ratio?: never
          id?: string | null
          invoice_number?: string | null
          is_company?: boolean | null
          is_paid?: boolean | null
          issue_date?: string | null
          note?: string | null
          paid_at?: string | null
          title?: string | null
          updated_at?: string | null
          user_id?: string | null
          vat_amount?: number | null
          vat_rate?: number | null
        }
        Relationships: []
      }
    }
    Functions: {
      compute_amounts: {
        Args: {
          p_amount_gross: number
          p_amount_net: number
          p_vat_rate: number
        }
        Returns: {
          amount_gross: number
          amount_net: number
          vat_amount: number
        }[]
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
