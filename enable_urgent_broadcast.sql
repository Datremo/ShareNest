-- ============================================================================
-- 1. ADD LOCATION TO PROFILES (If not already there)
-- We need users to have a lat/lng so we know who is inside the 1km radius.
-- ============================================================================
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS lat DOUBLE PRECISION;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS lng DOUBLE PRECISION;

-- Allow users to opt-out or change their alert radius (Default 1km)
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS urgent_alert_radius_km DOUBLE PRECISION DEFAULT 1.0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS wants_urgent_alerts BOOLEAN DEFAULT TRUE;

-- ============================================================================
-- 2. CREATE THE HYPER-LOCAL BROADCAST TRIGGER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.queue_urgent_broadcast()
RETURNS trigger AS $$
DECLARE
    v_member RECORD;
    v_requester_name TEXT;
    v_distance_km DOUBLE PRECISION;
BEGIN
    -- 1. Only broadcast if the request has coordinates
    IF NEW.lat IS NULL OR NEW.lng IS NULL THEN
        RETURN NEW;
    END IF;

    -- 2. Respect Quiet Hours (Don't broadcast between 10PM and 7AM UTC)
    -- Note: For production, you might adjust this to local timezone
    IF EXTRACT(HOUR FROM NOW()) >= 22 OR EXTRACT(HOUR FROM NOW()) < 7 THEN
        RETURN NEW; 
    END IF;

    -- Get the requester's name
    SELECT full_name INTO v_requester_name FROM public.profiles WHERE id = NEW.requester_id;
    IF v_requester_name IS NULL THEN
        v_requester_name := 'A neighbor';
    END IF;

    -- 3. Find nearby users who have opted into alerts
    FOR v_member IN 
        SELECT id, lat, lng, urgent_alert_radius_km
        FROM public.profiles 
        WHERE id != NEW.requester_id 
        AND wants_urgent_alerts = TRUE
        AND lat IS NOT NULL 
        AND lng IS NOT NULL
    LOOP
        -- Calculate distance using the Haversine formula (Returns distance in km)
        v_distance_km := 6371 * acos(
            cos(radians(NEW.lat)) * cos(radians(v_member.lat)) * 
            cos(radians(v_member.lng) - radians(NEW.lng)) + 
            sin(radians(NEW.lat)) * sin(radians(v_member.lat))
        );

        -- Check if they are within BOTH the requester's specified radius AND their own acceptable radius
        IF v_distance_km <= COALESCE(NEW.radius_km, 1.0) AND v_distance_km <= COALESCE(v_member.urgent_alert_radius_km, 5.0) THEN
            
            -- Insert the broadcast push notification
            INSERT INTO public.notification_outbox (
                user_id,
                type,
                title,
                body,
                entity_id,
                dedupe_key
            ) VALUES (
                v_member.id,
                'URGENT_REQUEST_BROADCAST',
                '🚨 URGENT: ' || NEW.title,
                v_requester_name || ' needs this right now (' || ROUND(v_distance_km::numeric, 1) || 'km away).',
                NEW.id,
                'urgent-broadcast-' || NEW.id::text || '-' || v_member.id::text
            );
        END IF;
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Attach Trigger
DROP TRIGGER IF EXISTS trigger_urgent_broadcast ON public.urgent_requests;

CREATE TRIGGER trigger_urgent_broadcast
  AFTER INSERT ON public.urgent_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.queue_urgent_broadcast();
