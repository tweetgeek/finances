import type { Database } from '~/types/database';
import { serverSupabaseClient } from '#supabase/server';

/**
 * API endpoint to generate monthly expenses from active loans.
 * This should be called periodically (e.g., via cron job) to create loan payment expenses.
 */
export default defineEventHandler(async (event) => {
  const config = useRuntimeConfig();

  // Verify webhook secret for security
  const webhookSecret = getHeader(event, 'x-webhook-secret');
  if (webhookSecret !== config.WEBHOOK_SECRET) {
    throw createError({
      statusCode: 401,
      statusMessage: 'Unauthorized: Invalid webhook secret',
    });
  }

  const supabase = await serverSupabaseClient<Database>(event);
  const today = new Date();
  const currentDate = today.toISOString().split('T')[0];
  const currentMonth = today.getMonth();
  const currentYear = today.getFullYear();

  // Get all active loans that haven't been generated for this month
  const { data: loans, error: loansError } = await supabase
    .from('loans')
    .select('*')
    .eq('is_active', true)
    .lte('start_date', currentDate)
    .gte('end_date', currentDate);

  if (loansError) {
    throw createError({
      statusCode: 500,
      statusMessage: loansError.message,
    });
  }

  const generatedExpenses = [];
  const errors = [];

  for (const loan of loans || []) {
    try {
      // Check if we already generated an expense for this loan this month
      const lastGenerated = loan.last_generated_date
        ? new Date(loan.last_generated_date)
        : null;

      if (lastGenerated) {
        const lastMonth = lastGenerated.getMonth();
        const lastYear = lastGenerated.getFullYear();

        // Skip if already generated for current month
        if (lastMonth === currentMonth && lastYear === currentYear) {
          continue;
        }
      }

      // Generate expense for this loan
      const issueDate = new Date(currentYear, currentMonth, 1).toISOString().split('T')[0];

      const { data: expense, error: expenseError } = await supabase
        .from('expenses')
        .insert({
          user_id: loan.user_id,
          title: `Rata kredytu: ${loan.title}`,
          counterparty: loan.bank_name,
          note: `Automatycznie wygenerowane z kredytu: ${loan.loan_purpose}`,
          amount_gross: loan.monthly_amount,
          vat_rate: 0,
          is_company: loan.is_company,
          is_paid: false,
          issue_date: issueDate,
          due_date: issueDate,
        })
        .select()
        .single();

      if (expenseError) {
        errors.push({
          loan_id: loan.id,
          loan_title: loan.title,
          error: expenseError.message,
        });
        continue;
      }

      // Update last_generated_date for this loan
      await supabase
        .from('loans')
        .update({ last_generated_date: currentDate })
        .eq('id', loan.id);

      generatedExpenses.push({
        loan_id: loan.id,
        loan_title: loan.title,
        expense_id: expense.id,
      });
    } catch (error) {
      errors.push({
        loan_id: loan.id,
        loan_title: loan.title,
        error: (error as Error).message,
      });
    }
  }

  return {
    success: true,
    generated: generatedExpenses.length,
    errors: errors.length,
    details: {
      generated_expenses: generatedExpenses,
      errors,
    },
  };
});
