-- This script will clear all transactional data from your ShareNest database.
-- It preserves your user accounts (auth.users and public.profiles) but deletes
-- all listings, requests, offers, notifications, and transactions so you can start fresh.

-- Delete in the correct order to respect foreign key constraints
DELETE FROM notifications;
DELETE FROM loans;
DELETE FROM borrow_requests;
DELETE FROM item_requests;
DELETE FROM urgent_request_offers;
DELETE FROM urgent_requests;
DELETE FROM listings;

-- If you also want to delete all profiles and user accounts entirely, 
-- you would need to execute this (but you will need to sign up again):
-- DELETE FROM auth.users;
-- DELETE FROM profiles;
