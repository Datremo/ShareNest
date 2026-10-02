import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4'
import { JWT } from 'https://esm.sh/google-auth-library@9.0.0'

// Initialize Supabase Client
const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const supabaseServiceKey = Deno.env.get('SERVICE_ROLE_KEY') ?? '';
const supabase = createClient(supabaseUrl, supabaseServiceKey);

// Firebase FCM HTTP v1 API
const projectId = Deno.env.get('FIREBASE_PROJECT_ID') ?? '';
const clientEmail = Deno.env.get('FIREBASE_CLIENT_EMAIL') ?? '';
const privateKey = Deno.env.get('FIREBASE_PRIVATE_KEY')?.replace(/\\n/g, '\n') ?? '';

async function getAccessToken() {
  const jwtClient = new JWT({
    email: clientEmail,
    key: privateKey,
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  });
  const tokens = await jwtClient.authorize();
  return tokens.access_token;
}

async function sendFcmMessage(token: string, notification: any, data: any) {
  const accessToken = await getAccessToken();
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${accessToken}`,
    },
    body: JSON.stringify({
      message: {
        token: token,
        notification: notification,
        data: data,
        android: {
          notification: {
            color: '#10B981', // NeighborShare vibrant green
            sound: 'default'
          }
        },
        apns: {
          payload: {
            aps: {
              sound: 'default'
            }
          }
        }
      },
    }),
  });

  const result = await response.json();
  if (!response.ok) {
    throw new Error(`FCM send failed: ${JSON.stringify(result)}`);
  }
  return result;
}

serve(async (req) => {
  try {
    const { record, type } = await req.json();
    
    // We expect this function to be called by a Supabase Webhook when a new row is INSERTED into `notification_outbox`.
    if (type !== 'INSERT' || !record) {
      return new Response("OK", { status: 200 });
    }

    const outboxId = record.id;
    const userId = record.user_id;
    const eventType = record.type;
    const entityId = record.entity_id;

    console.log(`Processing outbox ${outboxId} for user ${userId}, event: ${eventType}`);

    // Update status to PROCESSING
    await supabase.from('notification_outbox')
      .update({ status: 'PROCESSING', attempts: record.attempts + 1 })
      .eq('id', outboxId);

    // Get the actual notification content
    let pushTitle = record.title;
    let pushBody = record.body;
    let pushNotificationId = record.notification_id || '';

    // If it's a standard notification (like Activity Feed), fetch the missing title/body from the notifications table
    if (!pushTitle && record.notification_id) {
      const { data: notificationData, error: notifError } = await supabase
        .from('notifications')
        .select('*')
        .eq('id', record.notification_id)
        .single();

      if (notifError || !notificationData) {
        throw new Error(`Notification not found: ${notifError?.message}`);
      }
      
      pushTitle = notificationData.title;
      pushBody = notificationData.message;
    }

    if (!pushTitle) {
      throw new Error("No title provided for push notification");
    }

    // Get active user devices
    const { data: devices, error: devError } = await supabase
      .from('user_devices')
      .select('fcm_token')
      .eq('user_id', userId)
      .eq('is_active', true);

    if (devError) {
      throw new Error(`Failed to fetch devices: ${devError.message}`);
    }

    if (!devices || devices.length === 0) {
      console.log(`No active devices for user ${userId}. Completing outbox.`);
      await supabase.from('notification_outbox').update({ status: 'COMPLETED' }).eq('id', outboxId);
      return new Response("No devices", { status: 200 });
    }

    // Send to all active devices
    const notificationPayload = {
      title: pushTitle,
      body: pushBody ?? '',
    };
    
    const dataPayload = {
      event_type: eventType,
      entity_id: entityId || '',
      notification_id: pushNotificationId,
    };

    let hasSuccess = false;
    let lastError = null;

    for (const device of devices) {
      try {
        await sendFcmMessage(device.fcm_token, notificationPayload, dataPayload);
        hasSuccess = true;
      } catch (err: any) {
        console.error(`Error sending to token ${device.fcm_token}:`, err);
        lastError = err.message;
        // Optionally deactivate token if it's an UNREGISTERED error
        if (err.message.includes('UNREGISTERED')) {
          await supabase.from('user_devices').update({ is_active: false }).eq('fcm_token', device.fcm_token);
        }
      }
    }

    if (hasSuccess) {
      await supabase.from('notification_outbox').update({ status: 'COMPLETED', last_error: lastError }).eq('id', outboxId);
    } else {
      await supabase.from('notification_outbox').update({ 
        status: 'FAILED', 
        last_error: lastError 
      }).eq('id', outboxId);
    }

    return new Response(JSON.stringify({ success: true }), { headers: { 'Content-Type': 'application/json' } });

  } catch (error: any) {
    console.error("Dispatcher error:", error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: { 'Content-Type': 'application/json' } });
  }
})
