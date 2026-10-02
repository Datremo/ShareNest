-- Phase 3: The "Magic Switch"
-- This trigger automatically queues a push notification every time a new row is inserted into the notifications table.

-- 1. Create the trigger function
CREATE OR REPLACE FUNCTION public.queue_push_notification()
RETURNS trigger AS $$
BEGIN
  -- Insert a corresponding row into the outbox so the Edge Function picks it up
  INSERT INTO public.notification_outbox (
    notification_id,
    user_id,
    type,
    entity_id,
    dedupe_key
  ) VALUES (
    NEW.id,
    NEW.user_id,
    NEW.type,
    NEW.entity_id,
    'push-' || NEW.id::text
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Attach the trigger to the notifications table
DROP TRIGGER IF EXISTS trigger_queue_push_notification ON public.notifications;

CREATE TRIGGER trigger_queue_push_notification
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.queue_push_notification();
