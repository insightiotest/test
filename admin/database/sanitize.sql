DELETE FROM failed_logins;
UPDATE maxxer_locations SET x = RAND(3000), y = RAND(5000), timestamp = timestamp WHERE mapversion is NULL;
UPDATE maxxer_locations SET x = RAND(180) - 90, y = RAND(360) - 180, timestamp = timestamp WHERE mapversion = "google";
DELETE FROM merch_buyers;
DELETE FROM merch_items;
DELETE FROM merch_order_item_options;
DELETE FROM merch_order_items;
DELETE FROM merch_orders;
DELETE FROM referrals;
DELETE FROM tokens;
UPDATE users SET timestamp = timestamp, ip = "127.0.0.1", email = "spam@spammy.com", password = "ab4d8d2a5f480a137067da17100271cd176607a1";