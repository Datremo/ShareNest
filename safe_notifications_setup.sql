-- 1. Create user_devices table (Brand new, perfectly safe)
CREATE TABLE IF NOT EXISTS public.user_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    device_id TEXT NOT NULL,
    fcm_token TEXT NOT NULL,
    platform TEXT,
    app_version TEXT,
    is_active BOOLEAN DEFAULT true,
    last_seen_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, device_id)
);

ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own devices"
ON public.user_devices FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 2. Create notification_outbox table (Brand new, perfectly safe)
CREATE TABLE IF NOT EXISTS public.notification_outbox (
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

-- 3. Attach the manual Webhook trigger to the Outbox (Non-destructive)
DROP TRIGGER IF EXISTS on_notification_outbox_insert ON public.notification_outbox;

CREATE TRIGGER on_notification_outbox_insert
  AFTER INSERT ON public.notification_outbox
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_notification_dispatcher();
