-- Replace '<YOUR_USER_ID>' with your actual UUID from the auth.users or public.profiles table.

DO $$
DECLARE
    v_user_id UUID := '<YOUR_USER_ID>';
    v_notif_id UUID;
BEGIN
    -- 1. Insert into Activity (notifications table)
    INSERT INTO public.notifications (user_id, type, title, message)
    VALUES (
        v_user_id, 
        'TEST_EVENT', 
        'Test Notification', 
        'This is a native push proof test!'
    ) RETURNING id INTO v_notif_id;

    -- 2. Insert into Outbox (this should trigger the Edge Function via Webhook)
    INSERT INTO public.notification_outbox (notification_id, user_id, type, dedupe_key)
    VALUES (
        v_notif_id,
        v_user_id,
        'TEST_EVENT',
        'test-dedupe-' || gen_random_uuid()::text
    );
END $$;
