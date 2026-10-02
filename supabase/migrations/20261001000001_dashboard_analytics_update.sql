CREATE OR REPLACE FUNCTION get_dashboard_data(p_user_id UUID, p_start_date TIMESTAMP DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_snapshot JSONB;
  v_lending JSONB;
  v_borrowing JSONB;
  v_giving JSONB;
  v_received JSONB;
  v_urgent JSONB;
  v_status JSONB;
  v_post_perf JSONB;
  v_history JSONB;
  v_activity JSONB;
  v_request_analytics JSONB;
  v_returns_handovers JSONB;
  v_needs_attention JSONB;
BEGIN
  -- 1. CURRENT SNAPSHOT
  SELECT jsonb_build_object(
    'active_lending', (SELECT count(*) FROM item_requests req JOIN listings l ON req.listing_id = l.id WHERE l.owner_id = p_user_id AND l.mode = 'LEND' AND req.status IN ('ACCEPTED', 'ACTIVE', 'RETURN_REQUESTED')),
    'active_borrowing', (SELECT count(*) FROM item_requests req JOIN listings l ON req.listing_id = l.id WHERE req.requester_id = p_user_id AND l.mode = 'LEND' AND req.status IN ('ACCEPTED', 'ACTIVE', 'RETURN_REQUESTED')),
    'pending_returns', (SELECT count(*) FROM item_requests req JOIN listings l ON req.listing_id = l.id WHERE (l.owner_id = p_user_id OR req.requester_id = p_user_id) AND req.status IN ('ACTIVE', 'RETURN_REQUESTED')),
    'giving', (SELECT count(*) FROM item_requests req JOIN listings l ON req.listing_id = l.id WHERE l.owner_id = p_user_id AND l.mode = 'GIVE' AND req.status IN ('ACCEPTED', 'ACTIVE')),
    'receiving', (SELECT count(*) FROM item_requests req JOIN listings l ON req.listing_id = l.id WHERE req.requester_id = p_user_id AND l.mode = 'GIVE' AND req.status IN ('ACCEPTED', 'ACTIVE')),
    'open_urgent', (SELECT count(*) FROM urgent_requests WHERE requester_id = p_user_id AND status = 'OPEN')
  ) INTO v_snapshot;

  -- 2. TRANSACTIONS SUMMARY (Lending)
  SELECT jsonb_build_object(
    'total', count(*),
    'pending', count(*) FILTER (WHERE req.status = 'PENDING'),
    'accepted', count(*) FILTER (WHERE req.status = 'ACCEPTED'),
    'active', count(*) FILTER (WHERE req.status = 'ACTIVE'),
    'pending_return', count(*) FILTER (WHERE req.status IN ('RETURN_REQUESTED')),
    'completed', count(*) FILTER (WHERE req.status = 'COMPLETED'),
    'cancelled', count(*) FILTER (WHERE req.status IN ('CANCELLED', 'DECLINED', 'EXPIRED'))
  ) FROM item_requests req JOIN listings l ON req.listing_id = l.id
  WHERE l.owner_id = p_user_id AND l.mode = 'LEND'
  AND (p_start_date IS NULL OR req.created_at >= p_start_date)
  INTO v_lending;

  -- Borrowing
  SELECT jsonb_build_object(
    'total', count(*),
    'pending', count(*) FILTER (WHERE req.status = 'PENDING'),
    'accepted', count(*) FILTER (WHERE req.status = 'ACCEPTED'),
    'active', count(*) FILTER (WHERE req.status = 'ACTIVE'),
    'pending_return', count(*) FILTER (WHERE req.status IN ('RETURN_REQUESTED')),
    'completed', count(*) FILTER (WHERE req.status = 'COMPLETED'),
    'cancelled', count(*) FILTER (WHERE req.status IN ('CANCELLED', 'DECLINED', 'EXPIRED'))
  ) FROM item_requests req JOIN listings l ON req.listing_id = l.id
  WHERE req.requester_id = p_user_id AND l.mode = 'LEND'
  AND (p_start_date IS NULL OR req.created_at >= p_start_date)
  INTO v_borrowing;

  -- Giving
  SELECT jsonb_build_object(
    'total', count(*),
    'pending', count(*) FILTER (WHERE req.status = 'PENDING'),
    'pending_handover', count(*) FILTER (WHERE req.status = 'ACCEPTED'),
    'completed', count(*) FILTER (WHERE req.status = 'COMPLETED'),
    'cancelled', count(*) FILTER (WHERE req.status IN ('CANCELLED', 'DECLINED', 'EXPIRED'))
  ) FROM item_requests req JOIN listings l ON req.listing_id = l.id
  WHERE l.owner_id = p_user_id AND l.mode = 'GIVE'
  AND (p_start_date IS NULL OR req.created_at >= p_start_date)
  INTO v_giving;

  -- Received
  SELECT jsonb_build_object(
    'total', count(*),
    'pending', count(*) FILTER (WHERE req.status = 'PENDING'),
    'pending_handover', count(*) FILTER (WHERE req.status = 'ACCEPTED'),
    'completed', count(*) FILTER (WHERE req.status = 'COMPLETED'),
    'cancelled', count(*) FILTER (WHERE req.status IN ('CANCELLED', 'DECLINED', 'EXPIRED'))
  ) FROM item_requests req JOIN listings l ON req.listing_id = l.id
  WHERE req.requester_id = p_user_id AND l.mode = 'GIVE'
  AND (p_start_date IS NULL OR req.created_at >= p_start_date)
  INTO v_received;

  -- Urgent
  SELECT jsonb_build_object(
    'total', count(*),
    'open', count(*) FILTER (WHERE status = 'OPEN'),
    'accepted', count(*) FILTER (WHERE status IN ('ACCEPTED', 'ACTIVE')),
    'completed', count(*) FILTER (WHERE status = 'COMPLETED'),
    'cancelled', count(*) FILTER (WHERE status IN ('CANCELLED', 'EXPIRED'))
  ) FROM urgent_requests
  WHERE requester_id = p_user_id
  AND (p_start_date IS NULL OR created_at >= p_start_date)
  INTO v_urgent;

  -- 3. STATUS DONUT
  SELECT jsonb_build_object(
    'active', count(*) FILTER (WHERE req.status = 'ACTIVE'),
    'accepted', count(*) FILTER (WHERE req.status = 'ACCEPTED'),
    'pending', count(*) FILTER (WHERE req.status = 'PENDING'),
    'completed', count(*) FILTER (WHERE req.status = 'COMPLETED'),
    'cancelled', count(*) FILTER (WHERE req.status IN ('CANCELLED', 'DECLINED', 'EXPIRED'))
  ) FROM item_requests req JOIN listings l ON req.listing_id = l.id
  WHERE (l.owner_id = p_user_id OR req.requester_id = p_user_id)
  AND (p_start_date IS NULL OR req.created_at >= p_start_date)
  INTO v_status;

  -- 4. POST PERFORMANCE
  SELECT jsonb_build_object(
    'posts_created', count(DISTINCT l.id),
    'lend', count(DISTINCT l.id) FILTER (WHERE l.mode = 'LEND'),
    'give', count(DISTINCT l.id) FILTER (WHERE l.mode = 'GIVE'),
    'urgent', (SELECT count(*) FROM urgent_requests WHERE requester_id = p_user_id AND (p_start_date IS NULL OR created_at >= p_start_date)),
    'requests_received', count(req.id),
    'accepted', count(req.id) FILTER (WHERE req.status IN ('ACCEPTED', 'ACTIVE', 'RETURN_REQUESTED')),
    'completed', count(req.id) FILTER (WHERE req.status = 'COMPLETED')
  ) FROM listings l LEFT JOIN item_requests req ON l.id = req.listing_id
  WHERE l.owner_id = p_user_id
  AND (p_start_date IS NULL OR l.created_at >= p_start_date)
  INTO v_post_perf;

  -- 5. ACTIVITY HEATMAP / MONTHLY
  WITH monthly_counts AS (
      SELECT to_char(req.created_at, 'Mon') as month_name, count(*) as cnt
      FROM item_requests req
      WHERE (req.listing_id IN (SELECT id FROM listings WHERE owner_id = p_user_id) OR req.requester_id = p_user_id)
      AND (p_start_date IS NULL OR req.created_at >= p_start_date)
      GROUP BY month_name
  )
  SELECT COALESCE(jsonb_object_agg(month_name, cnt), '{}'::jsonb) FROM monthly_counts INTO v_activity;

  -- 6. REQUEST ANALYTICS
  WITH reqs AS (
    SELECT req.id, req.status, req.created_at,
           (CASE WHEN l.owner_id = p_user_id THEN 'INCOMING' ELSE 'OUTGOING' END) as direction
    FROM item_requests req JOIN listings l ON req.listing_id = l.id
    WHERE (l.owner_id = p_user_id OR req.requester_id = p_user_id)
    AND (p_start_date IS NULL OR req.created_at >= p_start_date)
  ),
  monthly_incoming AS (
    SELECT to_char(created_at, 'Mon') as month_name, count(*) as cnt FROM reqs WHERE direction = 'INCOMING' GROUP BY month_name
  ),
  monthly_outgoing AS (
    SELECT to_char(created_at, 'Mon') as month_name, count(*) as cnt FROM reqs WHERE direction = 'OUTGOING' GROUP BY month_name
  )
  SELECT jsonb_build_object(
    'total', (SELECT count(*) FROM reqs),
    'accepted', (SELECT count(*) FROM reqs WHERE status IN ('ACCEPTED', 'ACTIVE', 'RETURN_REQUESTED')),
    'pending', (SELECT count(*) FROM reqs WHERE status = 'PENDING'),
    'declined', (SELECT count(*) FROM reqs WHERE status = 'DECLINED'),
    'cancelled', (SELECT count(*) FROM reqs WHERE status IN ('CANCELLED', 'EXPIRED')),
    'incoming_trend', (SELECT COALESCE(jsonb_object_agg(month_name, cnt), '{}'::jsonb) FROM monthly_incoming),
    'outgoing_trend', (SELECT COALESCE(jsonb_object_agg(month_name, cnt), '{}'::jsonb) FROM monthly_outgoing)
  ) INTO v_request_analytics;

  -- 7. RETURNS & HANDOVERS
  SELECT jsonb_build_object(
    'on_time', count(*) FILTER (WHERE req.status = 'COMPLETED'),
    'late', count(*) FILTER (WHERE req.status = 'COMPLETED' AND req.end_date < req.updated_at),
    'overdue', count(*) FILTER (WHERE req.status IN ('ACTIVE', 'RETURN_REQUESTED') AND req.end_date < now()),
    'waiting_owner', count(*) FILTER (WHERE req.status = 'ACCEPTED' AND l.owner_id = p_user_id),
    'waiting_receiver', count(*) FILTER (WHERE req.status = 'ACCEPTED' AND req.requester_id = p_user_id),
    'completed_handovers', count(*) FILTER (WHERE req.status IN ('ACTIVE', 'RETURN_REQUESTED', 'COMPLETED')),
    'avg_duration_days', COALESCE(AVG(EXTRACT(EPOCH FROM (req.updated_at - req.start_date))/86400) FILTER (WHERE req.status = 'COMPLETED' AND req.start_date IS NOT NULL), 0)
  ) FROM item_requests req JOIN listings l ON req.listing_id = l.id
  WHERE (l.owner_id = p_user_id OR req.requester_id = p_user_id)
  AND (p_start_date IS NULL OR req.created_at >= p_start_date)
  INTO v_returns_handovers;

  -- 8. HISTORY LEDGER
  SELECT jsonb_agg(
     jsonb_build_object(
       'id', req.id,
       'title', l.title,
       'category', CASE WHEN l.owner_id = p_user_id THEN l.mode ELSE (CASE WHEN l.mode = 'LEND' THEN 'BORROW' ELSE 'RECEIVE' END) END,
       'status', req.status,
       'date', req.created_at,
       'is_owner', (l.owner_id = p_user_id),
       'raw_data', row_to_json(req)
     )
  ) FROM item_requests req JOIN listings l ON req.listing_id = l.id 
  WHERE (l.owner_id = p_user_id OR req.requester_id = p_user_id)
  AND (p_start_date IS NULL OR req.created_at >= p_start_date)
  INTO v_history;

  -- 9. NEEDS ATTENTION
  SELECT jsonb_agg(
     jsonb_build_object(
       'id', req.id,
       'title', l.title,
       'action', CASE 
           WHEN l.owner_id = p_user_id AND req.status = 'ACCEPTED' THEN 'Handover to user'
           WHEN req.requester_id = p_user_id AND req.status = 'ACCEPTED' THEN 'Collect from user'
           WHEN req.status = 'ACTIVE' AND req.end_date < now() THEN 'Return overdue item'
           WHEN req.status = 'RETURN_REQUESTED' THEN 'Acknowledge return'
           ELSE 'Action required'
         END,
       'type', CASE 
           WHEN req.status = 'ACCEPTED' THEN 'HANDOVER'
           WHEN req.status IN ('ACTIVE', 'RETURN_REQUESTED') THEN 'RETURN'
           ELSE 'OTHER'
         END,
       'due_date', req.end_date
     )
  ) FROM item_requests req JOIN listings l ON req.listing_id = l.id
  WHERE (
    (l.owner_id = p_user_id AND req.status IN ('ACCEPTED', 'RETURN_REQUESTED')) OR 
    (req.requester_id = p_user_id AND req.status = 'ACCEPTED') OR
    (req.status IN ('ACTIVE', 'RETURN_REQUESTED') AND req.end_date < now())
  )
  INTO v_needs_attention;

  RETURN jsonb_build_object(
     'snapshot', COALESCE(v_snapshot, '{}'::jsonb),
     'lending', COALESCE(v_lending, '{}'::jsonb),
     'borrowing', COALESCE(v_borrowing, '{}'::jsonb),
     'giving', COALESCE(v_giving, '{}'::jsonb),
     'received', COALESCE(v_received, '{}'::jsonb),
     'urgent', COALESCE(v_urgent, '{}'::jsonb),
     'status', COALESCE(v_status, '{}'::jsonb),
     'post_performance', COALESCE(v_post_perf, '{}'::jsonb),
     'activity', COALESCE(v_activity, '{}'::jsonb),
     'request_analytics', COALESCE(v_request_analytics, '{}'::jsonb),
     'returns_handovers', COALESCE(v_returns_handovers, '{}'::jsonb),
     'history', COALESCE(v_history, '[]'::jsonb),
     'needs_attention', COALESCE(v_needs_attention, '[]'::jsonb)
  );
END;
$$;
