-- screentime_analysis.sql

-- =========================
-- 1. Create Database & Tables
-- =========================
CREATE DATABASE screentime;

CREATE TABLE apps (
    app_name VARCHAR(50) PRIMARY KEY,
    category VARCHAR(50),
    is_productive BOOLEAN
);

CREATE TABLE users (
    user_id INT PRIMARY KEY
);

CREATE TABLE app_usage (
    usage_id SERIAL PRIMARY KEY,
    user_id INT,
    app_name VARCHAR(50),
    date TIMESTAMP,
    screen_time_min FLOAT,
    launches INT,
    interactions INT,
    youtube_views FLOAT,
    youtube_likes FLOAT,
    youtube_comments FLOAT,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (app_name) REFERENCES apps(app_name)
);

-- =========================
-- 2. Basic Data Analysis Queries
-- =========================

-- List all productive apps
SELECT * FROM apps WHERE is_productive = TRUE;

-- Count total users
SELECT COUNT(*) FROM users;

-- Total screen time per app
SELECT 
    app_name, 
    SUM(screen_time_min) AS total_screen_time
FROM app_usage 
GROUP BY app_name
ORDER BY total_screen_time DESC;

-- Screen time per app with category and productivity flag
SELECT 
    au.app_name,
    a.category,
    a.is_productive,
    SUM(au.screen_time_min) AS total_screen_time
FROM app_usage au
JOIN apps a ON au.app_name = a.app_name
GROUP BY au.app_name, a.category, a.is_productive
ORDER BY total_screen_time DESC;

-- Total screen time per user
SELECT 
    user_id, 
    SUM(screen_time_min) AS total_screen_time
FROM app_usage
GROUP BY user_id
ORDER BY total_screen_time DESC;

-- Top 5 productive apps by usage
SELECT 
    au.app_name,
    a.is_productive,
    SUM(au.screen_time_min) AS total_screen_time
FROM app_usage au
JOIN apps a ON au.app_name = a.app_name
WHERE a.is_productive = TRUE
GROUP BY au.app_name, a.is_productive
ORDER BY total_screen_time DESC
LIMIT 5;

-- Users with highest % of productive time
WITH total_time AS (
    SELECT user_id, SUM(screen_time_min) AS total_time
    FROM app_usage
    GROUP BY user_id
),
productive_time AS (
    SELECT au.user_id, SUM(au.screen_time_min) AS productive_time
    FROM app_usage au
    JOIN apps a ON au.app_name = a.app_name
    WHERE a.is_productive = TRUE
    GROUP BY au.user_id
)
SELECT 
    pt.user_id,
    ROUND((pt.productive_time / tt.total_time) * 100, 2) AS productive_percentage
FROM productive_time pt
JOIN total_time tt ON pt.user_id = tt.user_id
ORDER BY productive_percentage DESC
LIMIT 10;

-- Most addictive apps by launches per minute
SELECT 
    au.app_name,
    ROUND(SUM(au.launches) / NULLIF(SUM(au.screen_time_min), 0), 2) AS launches_per_minute
FROM app_usage au
GROUP BY au.app_name
ORDER BY launches_per_minute DESC
LIMIT 5;

-- Apps with highest engagement per launch
SELECT 
    app_name,
    ROUND(SUM(interactions) / NULLIF(SUM(launches), 0), 2) AS engagement_per_launch
FROM app_usage
GROUP BY app_name
ORDER BY engagement_per_launch DESC
LIMIT 5;

-- Productive vs total screen time per user
SELECT 
    au.user_id,
    ROUND(SUM(CASE WHEN a.is_productive = TRUE THEN au.screen_time_min ELSE 0 END), 2) AS productive_time,
    ROUND(SUM(au.screen_time_min), 2) AS total_time
FROM app_usage au
JOIN apps a ON au.app_name = a.app_name
GROUP BY au.user_id
HAVING SUM(au.screen_time_min) > 0
ORDER BY productive_time DESC
LIMIT 10;

-- Total screen time per user in hours
SELECT 
    user_id,
    ROUND(SUM(screen_time_min) / 60.0, 2) AS screen_time_hours
FROM app_usage
GROUP BY user_id;
