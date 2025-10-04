import type { Database } from '~/types/database';
import { serverSupabaseClient, serverSupabaseUser } from '#supabase/server';

export default defineEventHandler(async (event) => {
  const supabase = await serverSupabaseClient<Database>(event);
  const user = await serverSupabaseUser(event);

  if (!user) {
    throw createError({
      statusCode: 401,
      statusMessage: 'Unauthorized',
    });
  }

  const id = getRouterParam(event, 'id');
  const body = await readBody(event);

  const { data, error } = await supabase
    .from('loans')
    .update({
      title: body.title,
      bank_name: body.bank_name,
      loan_purpose: body.loan_purpose,
      is_company: body.is_company,
      monthly_amount: body.monthly_amount,
      start_date: body.start_date,
      end_date: body.end_date,
      is_active: body.is_active,
      updated_at: new Date().toISOString(),
    })
    .eq('id', id!)
    .eq('user_id', user.id)
    .select()
    .single();

  if (error) {
    throw createError({
      statusCode: 400,
      statusMessage: error.message,
    });
  }

  return data;
});
