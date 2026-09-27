-- We update the accept_urgent_offer RPC to NOT automatically generate the handoff code
CREATE OR REPLACE FUNCTION accept_urgent_offer(
  p_offer_id UUID
) RETURNS UUID AS $$
DECLARE
  v_offer RECORD;
  v_request RECORD;
  v_listing_id UUID;
  v_item_request_id UUID;
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

  -- Verify the caller is the requester (already enforced by RLS normally, but good to check here since SECURITY DEFINER)
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

  -- 5. Mark the urgent_request as ACCEPTED (or IN_PROGRESS)
  UPDATE public.urgent_requests
  SET status = 'ACCEPTED', updated_at = now()
  WHERE id = v_offer.urgent_request_id;

  -- 6. The Bridge: Determine the listing ID
  IF v_offer.offered_listing_id IS NOT NULL THEN
    v_listing_id := v_offer.offered_listing_id;
  ELSE
    -- Create a hidden private listing for this transaction
    INSERT INTO public.listings (
      owner_id, title, description, mode, status, location_name, category_id, is_urgent_fulfillment
    ) VALUES (
      v_offer.helper_id, 
      'SOS Fulfillment: ' || v_request.title, 
      'Automatic listing for Need It Now fulfillment.', 
      UPPER(v_offer.mode), 
      'ACTIVE', 
      (SELECT location_name FROM public.profiles WHERE id = v_offer.helper_id LIMIT 1), 
      'other',
      TRUE
    ) RETURNING id INTO v_listing_id;
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

  -- Return the generated request ID to navigate to chat/receipt
  RETURN v_item_request_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
