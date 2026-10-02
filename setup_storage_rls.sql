-- Allow public read access so images load for everyone in the chat
CREATE POLICY "Public Access to offer_photos"
ON storage.objects FOR SELECT
USING (bucket_id = 'offer_photos');

-- Allow any authenticated user to upload an image
CREATE POLICY "Users can upload to offer_photos"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'offer_photos' AND
    auth.role() = 'authenticated'
);

-- Allow users to delete their own images
CREATE POLICY "Users can delete their own offer_photos"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'offer_photos' AND
    auth.uid() = owner
);
