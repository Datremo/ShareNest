-- 1. Enable the pg_net extension (required for making HTTP requests from Postgres)
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 2. Create the trigger function that uses pg_net directly
CREATE OR REPLACE FUNCTION public.trigger_notification_dispatcher()
RETURNS trigger AS $$
DECLARE
  v_url text := 'https://<YOUR_PROJECT_ID>.supabase.co/functions/v1/notification-dispatcher';
  v_anon_key text := '<YOUR_ANON_KEY>';
  v_payload jsonb;
  v_headers jsonb;
BEGIN
  -- Build the JSON payload to match what Supabase Webhooks normally send
  v_payload := jsonb_build_object(
    'type', 'INSERT',
    'table', 'notification_outbox',
    'schema', 'public',
    'record', row_to_json(NEW)
  );

  -- Build the headers
  v_headers := jsonb_build_object(
    'Content-Type', 'application/json',
    'Authorization', 'Bearer ' || v_anon_key
  );

  -- Make the HTTP POST request to your Edge Function
  PERFORM net.http_post(
    url := v_url,
    body := v_payload,
    headers := v_headers,
    timeout_milliseconds := 2000
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Attach the trigger to the notification_outbox table
DROP TRIGGER IF EXISTS on_notification_outbox_insert ON public.notification_outbox;

CREATE TRIGGER on_notification_outbox_insert
  AFTER INSERT ON public.notification_outbox
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_notification_dispatcher();
