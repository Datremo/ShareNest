-- 1. Add title and body columns to the outbox so we can pass raw messages
ALTER TABLE public.notification_outbox ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.notification_outbox ADD COLUMN IF NOT EXISTS body TEXT;

-- 2. Create the Trigger Function for Chat Messages
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
        -- Insert a raw payload into the outbox WITHOUT creating an Activity Feed item
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
            v_sender_name,  -- Title will be the sender's name
            NEW.content,    -- Body will be the chat message text
            NEW.conversation_id,
            'chat-' || NEW.id::text || '-' || v_member.profile_id::text
        );
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Attach the trigger to the messages table
DROP TRIGGER IF EXISTS trigger_queue_chat_push ON public.messages;

CREATE TRIGGER trigger_queue_chat_push
  AFTER INSERT ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION public.queue_chat_push_notification();
