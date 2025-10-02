import type { Database } from '~/types/database';
import { serverSupabaseClient } from '#supabase/server';

export default defineEventHandler(async (event) => {
  const config = useRuntimeConfig();

  // Verify webhook secret
  const webhookSecret = getHeader(event, 'x-webhook-secret');
  if (webhookSecret !== config.WEBHOOK_SECRET) {
    throw createError({
      statusCode: 401,
      statusMessage: 'Unauthorized: Invalid webhook secret',
    });
  }

  const body = await readBody(event);

  // Get Supabase admin client
  const supabase = await serverSupabaseClient<Database>(event);
  const ownerId = config.OWNER_USER_ID;

  if (!ownerId) {
    throw createError({
      statusCode: 500,
      statusMessage: 'Server misconfiguration: OWNER_USER_ID not set',
    });
  }

  try {
    // Insert income
    const { data: income, error: incomeError } = await supabase
      .from('incomes')
      .insert({
        user_id: ownerId,
        title: body.title,
        note: body.note || null,
        counterparty: body.counterparty || null,
        invoice_number: body.invoice_number || null,
        issue_date: body.issue_date || new Date().toISOString().split('T')[0],
        vat_rate: body.vat_rate ?? 23,
        amount_net: body.amount_net || null,
        amount_gross: body.amount_gross || null,
        is_company: body.is_company ?? false,
      })
      .select()
      .single();

    if (incomeError) {
      throw createError({
        statusCode: 400,
        statusMessage: incomeError.message,
      });
    }

    // Handle categories if provided
    if (Array.isArray(body.categories) && body.categories.length > 0) {
      for (const categoryName of body.categories) {
        // Try to find existing category
        const { data: existingCategory } = await supabase
          .from('categories')
          .select('id')
          .eq('user_id', ownerId)
          .eq('name', categoryName)
          .maybeSingle();

        let categoryId = existingCategory?.id;

        // Create category if it doesn't exist
        if (!categoryId) {
          const { data: newCategory, error: categoryError } = await supabase
            .from('categories')
            .insert({
              user_id: ownerId,
              name: categoryName,
              is_deductible_in_company: false,
              default_deductible_ratio: 1.0,
            })
            .select('id')
            .single();

          if (categoryError) {
            console.error('Error creating category:', categoryError);
            continue;
          }

          categoryId = newCategory.id;
        }

        // Link category to income
        if (categoryId) {
          await supabase.from('income_categories').insert({
            income_id: income.id,
            category_id: categoryId,
          });
        }
      }
    }

    return {
      success: true,
      income,
    };
  } catch (error) {
    throw createError({
      statusCode: 400,
      statusMessage: (error as Error).message || 'Error creating income',
    });
  }
});
