-- It is 100% safe to drop the outbox because it is just a temporary queue we literally just invented.
-- It holds no permanent data and dropping it does NOT affect the existing notifications table.
DROP TABLE IF EXISTS public.notification_outbox CASCADE;

-- Re-create the outbox with the correct "type" column instead of "event_type"
CREATE TABLE public.notification_outbox (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_id UUID REFERENCES public.notifications(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    entity_id UUID,
    dedupe_key TEXT UNIQUE NOT NULL,
    status TEXT DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PROCESSING', 'FAILED', 'COMPLETED')),
    attempts INTEGER DEFAULT 0,
    next_attempt_at TIMESTAMPTZ DEFAULT now(),
    last_attempt_at TIMESTAMPTZ,
    last_error TEXT,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.notification_outbox ENABLE ROW LEVEL SECURITY;

-- Re-attach the trigger
DROP TRIGGER IF EXISTS on_notification_outbox_insert ON public.notification_outbox;

CREATE TRIGGER on_notification_outbox_insert
  AFTER INSERT ON public.notification_outbox
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_notification_dispatcher();
