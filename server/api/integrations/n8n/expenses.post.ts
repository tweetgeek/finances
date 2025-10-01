import type { Database } from '~/types/database'

export default defineEventHandler(async (event) => {
  const config = useRuntimeConfig()

  // Verify webhook secret
  const webhookSecret = getHeader(event, 'x-webhook-secret')
  if (webhookSecret !== config.WEBHOOK_SECRET) {
    throw createError({
      statusCode: 401,
      statusMessage: 'Unauthorized: Invalid webhook secret'
    })
  }

  const body = await readBody(event)

  // Get Supabase admin client
  const supabase = serverSupabaseClient<Database>(event)
  const ownerId = config.OWNER_USER_ID

  if (!ownerId) {
    throw createError({
      statusCode: 500,
      statusMessage: 'Server misconfiguration: OWNER_USER_ID not set'
    })
  }

  try {
    // Insert expense
    const { data: expense, error: expenseError } = await supabase
      .from('expenses')
      .insert({
        user_id: ownerId,
        title: body.title,
        note: body.note || null,
        counterparty: body.counterparty || null,
        invoice_number: body.invoice_number || null,
        issue_date: body.issue_date || new Date().toISOString().split('T')[0],
        due_date: body.due_date || null,
        vat_rate: body.vat_rate ?? 23,
        amount_net: body.amount_net || null,
        amount_gross: body.amount_gross || null,
        is_company: body.is_company ?? false,
        deductible_override: body.deductible_override ?? null,
        deductible_ratio: body.deductible_ratio ?? null,
        is_paid: body.is_paid ?? false,
        paid_at: body.paid_at || null
      })
      .select()
      .single()

    if (expenseError) {
      throw createError({
        statusCode: 400,
        statusMessage: expenseError.message
      })
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
          .maybeSingle()

        let categoryId = existingCategory?.id

        // Create category if it doesn't exist
        if (!categoryId) {
          const { data: newCategory, error: categoryError } = await supabase
            .from('categories')
            .insert({
              user_id: ownerId,
              name: categoryName,
              is_deductible_in_company: false,
              default_deductible_ratio: 1.0
            })
            .select('id')
            .single()

          if (categoryError) {
            console.error('Error creating category:', categoryError)
            continue
          }

          categoryId = newCategory.id
        }

        // Link category to expense
        if (categoryId) {
          await supabase
            .from('expense_categories')
            .insert({
              expense_id: expense.id,
              category_id: categoryId
            })
        }
      }
    }

    return {
      success: true,
      expense
    }
  } catch (error: any) {
    throw createError({
      statusCode: 400,
      statusMessage: error.message || 'Error creating expense'
    })
  }
})
