CREATE OR REPLACE FUNCTION public.create_or_get_conversation(
  p_context_type TEXT,
  p_context_id UUID,
  p_other_user_id UUID
) RETURNS UUID AS $$
DECLARE
  v_conv_id UUID;
  v_column_name TEXT;
  v_query TEXT;
  v_listing_id UUID;
BEGIN
  -- 1. Determine the exact foreign key column based on the context type
  IF p_context_type = 'listing' THEN
    v_column_name := 'listing_id';
  ELSIF p_context_type = 'borrow_request' THEN
    v_column_name := 'borrow_request_id';
    SELECT listing_id INTO v_listing_id FROM public.borrow_requests WHERE id = p_context_id;
  ELSIF p_context_type = 'item_request' THEN
    v_column_name := 'item_request_id';
    SELECT listing_id INTO v_listing_id FROM public.item_requests WHERE id = p_context_id;
  ELSIF p_context_type = 'urgent_request' THEN
    v_column_name := 'urgent_request_id';
  ELSIF p_context_type = 'urgent_offer' THEN
    v_column_name := 'urgent_offer_id';
  ELSIF p_context_type = 'loan' THEN
    v_column_name := 'loan_id';
    -- Could lookup listing_id from item_requests or borrow_requests but we will handle simple cases for now.
  ELSE
    RAISE EXCEPTION 'Invalid context type: %', p_context_type;
  END IF;

  -- 2. Try to find an existing conversation exactly matching this context ID
  v_query := format('
    SELECT c.id 
    FROM public.conversations c
    JOIN public.conversation_members cm1 ON c.id = cm1.conversation_id
    JOIN public.conversation_members cm2 ON c.id = cm2.conversation_id
    WHERE c.%I =  
      AND cm1.profile_id =  
      AND cm2.profile_id = 
    LIMIT 1
  ', v_column_name);
  
  EXECUTE v_query INTO v_conv_id USING p_context_id, auth.uid(), p_other_user_id;

  -- 3. If it exists, just return it
  IF v_conv_id IS NOT NULL THEN
    RETURN v_conv_id;
  END IF;

  -- 3.5. MORPHING LOGIC: If not found, and we have a v_listing_id, look for a conversation 
  -- between these two users for this listing. If found, upgrade/morph it by attaching this new context ID!
  IF v_listing_id IS NOT NULL THEN
     SELECT c.id INTO v_conv_id
     FROM public.conversations c
     JOIN public.conversation_members cm1 ON c.id = cm1.conversation_id
     JOIN public.conversation_members cm2 ON c.id = cm2.conversation_id
     WHERE c.listing_id = v_listing_id 
       AND cm1.profile_id = auth.uid() 
       AND cm2.profile_id = p_other_user_id
     LIMIT 1;
     
     IF v_conv_id IS NOT NULL THEN
        -- Morph the conversation by linking the new context ID
        v_query := format('UPDATE public.conversations SET %I =  WHERE id = ', v_column_name);
        EXECUTE v_query USING p_context_id, v_conv_id;
        RETURN v_conv_id;
     END IF;
  END IF;

  -- 4. Otherwise, generate a new ID and insert the conversation
  v_conv_id := gen_random_uuid();
  
  IF v_listing_id IS NOT NULL THEN
    v_query := format('INSERT INTO public.conversations (id, listing_id, %I) VALUES (, , )', v_column_name);
    EXECUTE v_query USING v_conv_id, v_listing_id, p_context_id;
  ELSE
    v_query := format('INSERT INTO public.conversations (id, %I) VALUES (, )', v_column_name);
    EXECUTE v_query USING v_conv_id, p_context_id;
  END IF;

  -- 5. Insert both members (the caller and the other user)
  INSERT INTO public.conversation_members (conversation_id, profile_id)
  VALUES 
    (v_conv_id, auth.uid()),
    (v_conv_id, p_other_user_id)
  ON CONFLICT DO NOTHING;

  RETURN v_conv_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
