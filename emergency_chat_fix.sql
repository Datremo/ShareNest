-- 1. Ensure the outbox has all the necessary columns (in case they were dropped)
ALTER TABLE public.notification_outbox ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.notification_outbox ADD COLUMN IF NOT EXISTS body TEXT;

-- 2. Update the chat push trigger to be FAULT TOLERANT.
-- If the push notification fails to queue (e.g., missing columns, webhook errors), 
-- it should NOT abort the chat message insertion.
CREATE OR REPLACE FUNCTION public.queue_chat_push_notification()
RETURNS trigger AS $$
DECLARE
    v_sender_name TEXT;
    v_member RECORD;
BEGIN
    -- Only trigger for USER messages, ignore SYSTEM auto-messages
    IF NEW.message_type != 'USER' THEN
        RETURN NEW;
    END IF;

    -- Get the sender's name
    SELECT full_name INTO v_sender_name FROM public.profiles WHERE id = NEW.sender_id;
    IF v_sender_name IS NULL THEN
        v_sender_name := 'Someone';
    END IF;

    -- For every OTHER member in the conversation, queue a push notification
    FOR v_member IN 
        SELECT profile_id FROM public.conversation_members 
        WHERE conversation_id = NEW.conversation_id 
        AND profile_id != NEW.sender_id
    LOOP
        BEGIN
            INSERT INTO public.notification_outbox (
                user_id,
                type,
                title,
                body,
                entity_id,
                dedupe_key
            ) VALUES (
                v_member.profile_id,
                'MESSAGE_RECEIVED',
                v_sender_name,
                NEW.content,
                NEW.conversation_id,
                'chat-' || NEW.id::text
            );
        EXCEPTION WHEN OTHERS THEN
            -- CRITICAL: If queuing the notification fails for ANY reason, 
            -- swallow the error so the chat message is still successfully saved to the database.
            RAISE WARNING 'Failed to queue push notification: %', SQLERRM;
        END;
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
