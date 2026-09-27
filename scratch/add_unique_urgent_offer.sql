CREATE UNIQUE INDEX IF NOT EXISTS unique_active_urgent_offer 
ON urgent_request_offers (urgent_request_id, helper_id) 
WHERE status IN ('PENDING', 'ACCEPTED');
