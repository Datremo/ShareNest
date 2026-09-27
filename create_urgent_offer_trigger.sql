-- Trigger function to notify requester when an offer is received
CREATE OR REPLACE FUNCTION public.notify_urgent_offer_received()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_requester_id UUID;
    v_request_title TEXT;
    v_helper_name TEXT;
BEGIN
    -- Get requester and request title
    SELECT requester_id, title INTO v_requester_id, v_request_title
    FROM public.urgent_requests WHERE id = NEW.urgent_request_id;

    -- Get helper name
    SELECT display_name INTO v_helper_name FROM public.profiles WHERE id = NEW.helper_id;
    IF v_helper_name IS NULL THEN v_helper_name := 'A neighbor'; END IF;

    -- Insert notification
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.notifications (user_id, actor_id, type, title, message, entity_id)
        VALUES (
            v_requester_id, 
            NEW.helper_id, 
            'urgent_offer_received', 
            'Help Offered!', 
            v_helper_name || ' offered to help with your request: ' || v_request_title, 
            NEW.urgent_request_id
        );
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger on urgent_request_offers
DROP TRIGGER IF EXISTS trigger_notify_urgent_offer ON public.urgent_request_offers;
CREATE TRIGGER trigger_notify_urgent_offer
    AFTER INSERT ON public.urgent_request_offers
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_urgent_offer_received();
