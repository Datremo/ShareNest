-- 1. Create user_devices table
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

-- Enable RLS for user_devices
ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own devices"
ON public.user_devices FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 2. Create notifications table (Activity)
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT,
    entity_type TEXT,
    entity_id UUID,
    deep_link TEXT,
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS for notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own notifications"
ON public.notifications FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications"
ON public.notifications FOR UPDATE
USING (auth.uid() = user_id);

-- 3. Create notification_outbox table (Queue)
CREATE TABLE IF NOT EXISTS public.notification_outbox (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_id UUID REFERENCES public.notifications(id) ON DELETE SET NULL,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL,
    entity_type TEXT,
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

-- Note: The notification_outbox does not strictly need RLS since it's processed by Edge Functions (service role),
-- but we can restrict it so users can't read it.
ALTER TABLE public.notification_outbox ENABLE ROW LEVEL SECURITY;
-- No policies on outbox means only Service Role can access it.

-- 4. Supabase Webhook Function for Outbox processing
-- For Phase 1, we will trigger the edge function on insert to notification_outbox
CREATE OR REPLACE FUNCTION notify_edge_function()
RETURNS trigger AS $$
BEGIN
  -- We use pg_notify or direct http request. 
  -- In Supabase, usually we set up a Webhook in the dashboard to call the edge function on insert to `notification_outbox`.
  -- We don't necessarily need a PL/pgSQL function here if we use Dashboard Webhooks, but for completeness, we can use net.http_post.
  
  -- Assuming edge function URL is configured. We will leave this for the webhook configuration in the dashboard.
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
