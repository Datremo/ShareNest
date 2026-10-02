-- 1. Safely drop the old tables
DROP TABLE IF EXISTS public.notification_outbox CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;

-- 2. Re-create notifications table using the EXACT column names expected by Flutter
-- (message instead of body, type instead of event_type, plus actor_id and data)
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT,
    data JSONB,
    entity_id UUID,
    actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update their own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "System can insert notifications" ON public.notifications FOR INSERT WITH CHECK (true);

-- 3. Re-create the notification_outbox table (Queue) matching the 'type' column
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

-- 4. Re-attach the manual Webhook trigger
DROP TRIGGER IF EXISTS on_notification_outbox_insert ON public.notification_outbox;
CREATE TRIGGER on_notification_outbox_insert
  AFTER INSERT ON public.notification_outbox
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_notification_dispatcher();
