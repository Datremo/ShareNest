ALTER TABLE public.urgent_request_offers 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();
