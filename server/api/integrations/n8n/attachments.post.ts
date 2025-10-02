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

  // Validate required fields
  if (
    !body.entity_type ||
    !body.entity_id ||
    !body.file_base64 ||
    !body.filename
  ) {
    throw createError({
      statusCode: 400,
      statusMessage:
        'Missing required fields: entity_type, entity_id, file_base64, filename',
    });
  }

  if (!['expense', 'income'].includes(body.entity_type)) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Invalid entity_type. Must be "expense" or "income"',
    });
  }

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
    // Parse base64 data
    let fileBuffer: Buffer;
    let mimeType = 'application/octet-stream';

    // Handle data URI format: data:mime/type;base64,xxxxx
    if (body.file_base64.startsWith('data:')) {
      const matches = body.file_base64.match(/^data:([^;]+);base64,(.+)$/);
      if (!matches) {
        throw createError({
          statusCode: 400,
          statusMessage: 'Invalid base64 data URI format',
        });
      }
      mimeType = matches[1];
      fileBuffer = Buffer.from(matches[2], 'base64');
    } else {
      // Plain base64 string
      fileBuffer = Buffer.from(body.file_base64, 'base64');
    }

    // Generate unique file path
    const timestamp = Date.now();
    const filePath = `${ownerId}/${timestamp}-${body.filename}`;

    // Upload to Supabase Storage
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from('receipts')
      .upload(filePath, fileBuffer, {
        contentType: mimeType,
        upsert: false,
      });

    if (uploadError) {
      throw createError({
        statusCode: 500,
        statusMessage: `Storage upload error: ${uploadError.message}`,
      });
    }

    // Create attachment record
    const { data: attachment, error: attachmentError } = await supabase
      .from('attachments')
      .insert({
        user_id: ownerId,
        entity_type: body.entity_type,
        entity_id: body.entity_id,
        file_path: uploadData.path,
        original_filename: body.filename,
        mime_type: mimeType,
        size_bytes: fileBuffer.length,
      })
      .select()
      .single();

    if (attachmentError) {
      // Cleanup uploaded file if DB insert fails
      await supabase.storage.from('receipts').remove([uploadData.path]);
      throw createError({
        statusCode: 400,
        statusMessage: attachmentError.message,
      });
    }

    return {
      success: true,
      attachment,
    };
  } catch (error) {
    throw createError({
      statusCode: 400,
      statusMessage: (error as Error).message || 'Error creating attachment',
    });
  }
});
