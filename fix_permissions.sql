-- Grant necessary permissions to the Supabase roles
GRANT ALL ON TABLE public.notifications TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.notification_outbox TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.user_devices TO anon, authenticated, service_role;

-- Also ensure sequences are accessible if there are any
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
