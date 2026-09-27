-- 1. Enable PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;

-- 2. Add location columns to key entities
-- We use geography(Point, 4326) which natively understands spherical distance (meters)
ALTER TABLE public.listings ADD COLUMN IF NOT EXISTS location geography(Point, 4326);
ALTER TABLE public.urgent_requests ADD COLUMN IF NOT EXISTS location geography(Point, 4326);
ALTER TABLE public.item_requests ADD COLUMN IF NOT EXISTS handover_location geography(Point, 4326);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS home_location geography(Point, 4326);

-- 3. Create spatial indexes for fast querying
CREATE INDEX IF NOT EXISTS listings_location_idx ON public.listings USING GIST (location);
CREATE INDEX IF NOT EXISTS urgent_requests_location_idx ON public.urgent_requests USING GIST (location);

-- 4. RPC: Nearby Urgent Requests
-- This securely fetches open urgent requests within a given radius in meters.
-- It avoids exposing exact coordinates if they belong to another user (redacted for privacy).
CREATE OR REPLACE FUNCTION nearby_urgent_requests(
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION,
    p_radius_meters DOUBLE PRECISION
)
RETURNS TABLE (
    id UUID,
    requester_id UUID,
    title TEXT,
    description TEXT,
    distance_meters DOUBLE PRECISION,
    approximate_lat DOUBLE PRECISION,
    approximate_lng DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ur.id,
        ur.requester_id,
        ur.title,
        ur.description,
        ST_Distance(ur.location, ST_SetSRID(ST_Point(p_lng, p_lat), 4326)) AS distance_meters,
        -- Instead of exact coords, we can add a slight jitter or just return the exact if accepted,
        -- but for public Live Radar, we'll return approximate coordinates (rounded to 3 decimal places ~100m)
        ROUND(ST_Y(ur.location::geometry)::NUMERIC, 3)::DOUBLE PRECISION AS approximate_lat,
        ROUND(ST_X(ur.location::geometry)::NUMERIC, 3)::DOUBLE PRECISION AS approximate_lng,
        ur.created_at
    FROM public.urgent_requests ur
    WHERE ur.status = 'OPEN'
      AND ur.location IS NOT NULL
      AND ST_DWithin(
          ur.location, 
          ST_SetSRID(ST_Point(p_lng, p_lat), 4326), 
          p_radius_meters
      )
    ORDER BY distance_meters ASC;
END;
$$;

-- 5. RPC: Posts in Map Bounds
-- Used by the Explore map when dragging around to find items.
CREATE OR REPLACE FUNCTION posts_in_map_bounds(
    p_min_lng DOUBLE PRECISION,
    p_min_lat DOUBLE PRECISION,
    p_max_lng DOUBLE PRECISION,
    p_max_lat DOUBLE PRECISION
)
RETURNS TABLE (
    id UUID,
    owner_id UUID,
    title TEXT,
    mode TEXT,
    image_url TEXT,
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        l.id,
        l.owner_id,
        l.title,
        l.mode,
        l.image_url,
        -- Returning exact coordinates here because for public posts (Lend/Give), the user
        -- explicitly set a public meeting/pickup point (not their home).
        ST_Y(l.location::geometry) AS lat,
        ST_X(l.location::geometry) AS lng
    FROM public.listings l
    WHERE l.status IN ('AVAILABLE', 'ACTIVE')
      AND l.location IS NOT NULL
      AND l.location && ST_MakeEnvelope(p_min_lng, p_min_lat, p_max_lng, p_max_lat, 4326);
END;
$$;
