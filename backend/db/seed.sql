-- 1. seed tiers for dfs progression graph
insert into tiers (id, tier_name, required_xp, parent_tier_id) values
(1, 'seed', 0, null),
(2, 'sprout', 500, 1),
(3, 'sapling', 1200, 2),
(4, 'ancient tree', 2500, 3)
on conflict (id) do update set 
    tier_name = excluded.tier_name,
    required_xp = excluded.required_xp,
    parent_tier_id = excluded.parent_tier_id;

-- 2. seed mock users for max-heap leaderboard & testing
insert into users (username, email, password_hash, first_name, total_xp, city, province, current_tier_id) values
('joan_dev', 'joan@ecoecho.org', 'securehash', 'Joan', 1500, 'manila', 'metro manila', 3),
('roxane_eco', 'roxane@ecoecho.org', 'securehash', 'Roxane', 2800, 'manila', 'metro manila', 4),
('jinri_green', 'jinri@ecoecho.org', 'securehash', 'Jinri', 450, 'pateros', 'metro manila', 1),
('princess_earth', 'princess@ecoecho.org', 'securehash', 'Princess', 980, 'las pinas', 'metro manila', 2),
('eco_warrior99', 'warrior@ecoecho.org', 'securehash', 'Warrior', 1900, 'caloocan', 'metro manila', 3)
on conflict do nothing;

-- 3. seed base missions
insert into missions (id, title, description, xp_reward, is_daily, tier_id) values
(1, 'unplug installer', 'unplug phantom devices for 24 hours', 50, true, 1),
(2, 'hydrosaver', 'limit shower times to under 5 minutes', 40, false, 2),
(3, 'plastic purge', 'recycled 5 single-use plastic bottles', 60, true, 1),
(4, 'plant a Tree', 'plant a tree in your local community', 50, true, 1)
on conflict (id) do nothing;
