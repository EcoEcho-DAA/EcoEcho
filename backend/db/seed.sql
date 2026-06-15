-- 1. seed tiers for dfs progression graph
insert into tiers (id, tier_name, required_xp) values
(1, 'seed', 0),
(2, 'sprout', 500),
(3, 'sapling', 1200),
(4, 'ancient tree', 2500),
(5, 'legendary tree', 10000)
on conflict (id) do update set 
    tier_name = excluded.tier_name,
    required_xp = excluded.required_xp;

-- seed tier prerequisites for progression
insert into tier_prerequisites (tier_id, prerequisite_tier_id) values
(2, 1),
(3, 2),
(4, 3)
on conflict do nothing;

-- seed categories
insert into categories (id, name, xp_weight) values
(1, 'Tree Planting', 50),
(2, 'Sustainable Transport', 30),
(3, 'Recycling', 20),
(4, 'Energy Saving', 20),
(5, 'Cleanup Drive', 40),
(6, 'EcoWrapped 2026', 100)
on conflict (id) do update set
    name = excluded.name,
    xp_weight = excluded.xp_weight;

-- 2. seed mock users for max-heap leaderboard & testing
insert into users (uid, username, email, password_hash, total_xp, city, province, current_tier_id) values
('11111111-1111-1111-1111-111111111111', 'joan_dev', 'joan@ecoecho.org', 'securehash', 1500, 'manila', 'metro manila', 3),
('22222222-2222-2222-2222-222222222222', 'roxane_eco', 'roxane@ecoecho.org', 'securehash', 2800, 'manila', 'metro manila', 4),
('33333333-3333-3333-3333-333333333333', 'jinri_green', 'jinri@ecoecho.org', 'securehash', 450, 'pateros', 'metro manila', 1),
('44444444-4444-4444-4444-444444444444', 'princess_earth', 'princess@ecoecho.org', 'securehash', 980, 'las pinas', 'metro manila', 2),
('55555555-5555-5555-5555-555555555555', 'eco_warrior99', 'warrior@ecoecho.org', 'securehash', 1900, 'caloocan', 'metro manila', 3)
on conflict do nothing;

-- 3. seed base missions
insert into missions (id, title, description, xp_reward, is_daily, tier_id) values
(1, 'unplug installer', 'unplug phantom devices for 24 hours', 50, true, 1),
(2, 'hydrosaver', 'limit shower times to under 5 minutes', 40, false, 2),
(3, 'plastic purge', 'recycled 5 single-use plastic bottles', 60, true, 1),
(4, 'plant a Tree', 'plant a tree in your local community', 50, true, 1),
(101, 'Eco-Starter', 'Complete your very first environmental action.', 100, false, 1),
(102, 'Waste Warrior', 'Sort and recycle 10 items.', 150, false, 1),
(103, 'Green Commuter', 'Use public transport or bike 5 times.', 150, false, 1),
(104, 'Compost King', 'Start a compost bin and maintain it for a month.', 300, false, 1),
(105, 'Carbon Neutral', 'Offset your carbon footprint by planting 5 trees.', 500, false, 1)
on conflict (id) do nothing;

-- 4. seed consecutive activity logs for joan_dev (uid 11111111-1111-1111-1111-111111111111) to test the 5-day streak counter
insert into activity_logs (user_uid, action_description, created_at) values
('11111111-1111-1111-1111-111111111111', 'Logged in to account.', '2026-06-11 10:00:00+08'),
('11111111-1111-1111-1111-111111111111', 'Created a post.', '2026-06-12 11:30:00+08'),
('11111111-1111-1111-1111-111111111111', 'Completed a daily mission.', '2026-06-13 14:15:00+08'),
('11111111-1111-1111-1111-111111111111', 'Liked a post.', '2026-06-14 18:20:00+08'),
('11111111-1111-1111-1111-111111111111', 'Completed a mission.', '2026-06-15 07:35:00+08');

