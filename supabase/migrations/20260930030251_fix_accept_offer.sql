CREATE OR REPLACE FUNCTION accept_urgent_offer(
  p_offer_id UUID
) RETURNS UUID AS $$
DECLARE
  v_offer RECORD;
  v_request RECORD;
  v_listing_id UUID;
  v_item_request_id UUID;
  v_conv_id UUID;
  v_offer_type TEXT := 'LEND';
BEGIN
  -- 1. Get the offer details
  SELECT * INTO v_offer
  FROM public.urgent_request_offers
  WHERE id = p_offer_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Offer not found';
  END IF;

  -- 2. Get the original request details
  SELECT * INTO v_request
  FROM public.urgent_requests
  WHERE id = v_offer.urgent_request_id;

  IF v_request.requester_id != auth.uid() THEN
    RAISE EXCEPTION 'Only the requester can accept an offer';
  END IF;

  -- 3. Mark the chosen offer as ACCEPTED
  UPDATE public.urgent_request_offers
  SET status = 'ACCEPTED', updated_at = now()
  WHERE id = p_offer_id;

  -- 4. Mark other offers for this request as REJECTED
  UPDATE public.urgent_request_offers
  SET status = 'REJECTED', updated_at = now()
  WHERE urgent_request_id = v_offer.urgent_request_id
  AND id != p_offer_id;

  -- 4.5. Archive the conversations of those rejected offers so they close immediately
  UPDATE public.conversations
  SET status = 'ARCHIVED'
  WHERE urgent_offer_id IN (
    SELECT id FROM public.urgent_request_offers
    WHERE urgent_request_id = v_offer.urgent_request_id
    AND id != p_offer_id
  );

  -- 4.6. Insert notifications for rejected offers
  INSERT INTO public.notifications (user_id, title, message, type, data, actor_id)
  SELECT 
    helper_id,
    'Offer Rejected',
    'Your offer for "' || v_request.title || '" was not selected.',
    'OFFER_REJECTED',
    jsonb_build_object('urgent_request_id', v_request.id),
    auth.uid()
  FROM public.urgent_request_offers
  WHERE urgent_request_id = v_offer.urgent_request_id
  AND id != p_offer_id;

  -- 5. Mark the urgent_request as ACCEPTED
  UPDATE public.urgent_requests
  SET status = 'ACCEPTED', updated_at = now()
  WHERE id = v_offer.urgent_request_id;

  -- 6. The Bridge: Determine the listing ID and mode
  BEGIN
    IF (v_offer.offered_listing_id IS NOT NULL) THEN
      v_listing_id := v_offer.offered_listing_id;
    END IF;
  EXCEPTION WHEN undefined_column THEN
    -- Column doesn't exist, which is fine
  END;

  -- Extract type (GIVE or LEND) from available_for_duration
  BEGIN
    v_offer_type := COALESCE((v_offer.available_for_duration::jsonb)->>'type', 'LEND');
  EXCEPTION WHEN OTHERS THEN
    v_offer_type := 'LEND';
  END;

  IF v_listing_id IS NULL THEN
    -- Parse available_for_duration to see if photos were provided
    DECLARE
      v_offer_photos JSONB;
      v_photo_urls TEXT[] := '{}';
    BEGIN
      BEGIN
        v_offer_photos := (v_offer.available_for_duration::jsonb)->'photos';
        IF jsonb_array_length(v_offer_photos) > 0 THEN
          SELECT array_agg(x::text) INTO v_photo_urls
          FROM jsonb_array_elements_text(v_offer_photos) x;
        END IF;
      EXCEPTION WHEN OTHERS THEN
        v_photo_urls := '{}';
      END;

      IF array_length(v_photo_urls, 1) IS NULL AND v_request.photo_urls IS NOT NULL THEN
        v_photo_urls := v_request.photo_urls;
      END IF;

      -- Create a hidden private listing for this transaction
      INSERT INTO public.listings (
        owner_id, title, description, mode, status, location_name, category_id, is_urgent_fulfillment, photo_urls
      ) VALUES (
        v_offer.helper_id, 
        'SOS Fulfillment: ' || v_request.title, 
        'Automatic listing for Need It Now fulfillment.', 
        UPPER(v_offer_type), 
        'UNAVAILABLE', 
        (SELECT location_name FROM public.profiles WHERE id = v_offer.helper_id LIMIT 1), 
        'other',
        TRUE,
        v_photo_urls
      ) RETURNING id INTO v_listing_id;
    END;
  END IF;

  -- 7. Create an ACCEPTED ItemRequest linking the two
  INSERT INTO public.item_requests (
    listing_id, requester_id, status, start_date, end_date, is_urgent
  ) VALUES (
    v_listing_id,
    v_request.requester_id,
    'ACCEPTED',
    now(),
    now() + interval '1 day',
    TRUE
  ) RETURNING id INTO v_item_request_id;

  -- 8. Morph the existing conversation!
  -- Attach the new listing_id and item_request_id to the conversation that was started for this urgent offer
  UPDATE public.conversations
  SET listing_id = v_listing_id,
      item_request_id = v_item_request_id
  WHERE urgent_offer_id = p_offer_id
  RETURNING id INTO v_conv_id;

  -- 8.5. If no conversation exists yet, CREATE ONE to link the offer to the request!
  IF v_conv_id IS NULL THEN
    v_conv_id := gen_random_uuid();
    INSERT INTO public.conversations (id, urgent_offer_id, listing_id, item_request_id)
    VALUES (v_conv_id, p_offer_id, v_listing_id, v_item_request_id);
    
    INSERT INTO public.conversation_members (conversation_id, profile_id)
    VALUES (v_conv_id, auth.uid()), (v_conv_id, v_offer.helper_id);
  END IF;

  -- 9. Insert a SYSTEM message into the conversation
  IF v_conv_id IS NOT NULL THEN
    INSERT INTO public.messages (
      conversation_id, sender_id, message_type, content
    ) VALUES (
      v_conv_id,
      auth.uid(),
      'SYSTEM',
      'Offer accepted! The transaction has started.'
    );
  END IF;

  -- Return the generated request ID to navigate to chat/receipt
  RETURN v_item_request_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
