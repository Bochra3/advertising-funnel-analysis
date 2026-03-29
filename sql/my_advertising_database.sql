-- database creation
CREATE DATABASE my_advertising_database;
-- specify database to work with 
USE my_advertising_database ;

-- ---------------------------------------------------
-- TABLE CREATION 
CREATE TABLE dim_users (
    user_id     VARCHAR(20) PRIMARY KEY,
    user_gender VARCHAR(10),
    user_age    INT,
    age_group   VARCHAR(20),
    country     VARCHAR(50),
    location    VARCHAR(100),
    interests   TEXT
);


CREATE TABLE dim_campaigns (
    campaign_id   INT PRIMARY KEY,
    `name`       VARCHAR(100),
    start_date    DATE,
    end_date      DATE,
    duration_days INT,
    total_budget  DECIMAL(18,2)
);

CREATE TABLE dim_ads (
    ad_id           INT PRIMARY KEY,
    campaign_id     INT,
    ad_platform     VARCHAR(20),
    ad_type         VARCHAR(20),
    target_gender   VARCHAR(10),
    target_age      VARCHAR(20),
    target_interest TEXT,
    FOREIGN KEY (campaign_id) REFERENCES dim_campaigns(campaign_id)
);




CREATE TABLE  fact_ad_events (
    event_id        INT PRIMARY KEY,
    ad_id           INT,
    user_id         VARCHAR(20),
    day_of_week     VARCHAR(10),
    time_of_day     VARCHAR(20),
    event_type      VARCHAR(20),
    event_date      DATE,
    event_hour      TINYINT,
    is_impression   INT,
    is_click        INT,
    is_purchase     INT,
    is_engagement   INT,
    FOREIGN KEY (ad_id) REFERENCES dim_ads(ad_id),
    FOREIGN KEY (user_id) REFERENCES dim_users(user_id)
);
-- -----------------------------------------------------------
-- loading CVS
SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dim_users_cleaned.csv'
INTO TABLE dim_users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(user_id, user_gender, user_age, age_group, country, location, interests);


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dim_campaigns_cleaned.csv'
INTO TABLE dim_campaigns
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(campaign_id, `name`, start_date, end_date, duration_days, total_budget);


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dim_ads_cleaned.csv'
INTO TABLE dim_ads
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(ad_id, campaign_id, ad_platform, ad_type, target_gender, target_age, target_interest);




LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/fact_ad_events_cleaned.csv"
INTO TABLE fact_ad_events
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(event_id, ad_id, user_id, day_of_week, time_of_day, event_type,event_date, event_hour, is_impression, is_click, is_purchase, is_engagement);

-- ------------------------------------------------------------------------------------
-- DISPLAY TABLE CONTENT 
SELECT * FROM dim_users;
SELECT * FROM dim_ads;
SELECT * FROM dim_campaigns;
SELECT * FROM fact_ad_events;
-- -----------------------------------------------
-- ROW COUNTS 
SELECT COUNT(*) AS total_rows
FROM fact_ad_events ;
SELECT COUNT(*) AS total_rows
FROM dim_campaigns ;
SELECT COUNT(*) AS total_rows
FROM dim_users ;
SELECT COUNT(*) AS total_rows
FROM dim_ads ;

-- ----------------------------------------------------------------------------------
-- ANALYTICAL QUESTIONS 
-- Count unique users at each funnel stage 
WITH funnel_users AS (
    SELECT
        COUNT(DISTINCT CASE WHEN is_impression = 1 THEN user_id END) AS users_impression,
        COUNT(DISTINCT CASE WHEN is_click = 1 THEN user_id END) AS users_click,
        COUNT(DISTINCT CASE WHEN is_engagement = 1 THEN user_id END) AS users_engagement,
        COUNT(DISTINCT CASE WHEN is_purchase = 1 THEN user_id END) AS users_purchase
    FROM fact_ad_events
)
SELECT * FROM funnel_users;

-- Funnel Conversion Rates 
-- Step-to-step and top-of-funnel conversions
SELECT
    'Step-to-Step' AS conversion_type,
    'Impression → Click' AS stage,
    ROUND(users_click * 100.0 / NULLIF(users_impression,0),2) AS conversion_percentage
FROM (
    SELECT
        COUNT(DISTINCT CASE WHEN is_impression = 1 THEN user_id END) AS users_impression,
        COUNT(DISTINCT CASE WHEN is_click = 1 THEN user_id END) AS users_click
    FROM fact_ad_events
) AS funnel_users

UNION ALL

SELECT
    'Step-to-Step',
    'Click → Engagement',
    ROUND(users_engagement * 100.0 / NULLIF(users_click,0),2)
FROM (
    SELECT
        COUNT(DISTINCT CASE WHEN is_click = 1 THEN user_id END) AS users_click,
        COUNT(DISTINCT CASE WHEN is_engagement = 1 THEN user_id END) AS users_engagement
    FROM fact_ad_events
) AS funnel_users

UNION ALL

SELECT
    'Step-to-Step',
    'Engagement → Purchase',
    ROUND(users_purchase * 100.0 / NULLIF(users_engagement,0),2)
FROM (
    SELECT
        COUNT(DISTINCT CASE WHEN is_engagement = 1 THEN user_id END) AS users_engagement,
        COUNT(DISTINCT CASE WHEN is_purchase = 1 THEN user_id END) AS users_purchase
    FROM fact_ad_events
) AS funnel_users

UNION ALL

SELECT
    'Top-of-Funnel',
    'Impression → Click',
    ROUND(users_click * 100.0 / NULLIF(users_impression,0),2)
FROM (
    SELECT
        COUNT(DISTINCT CASE WHEN is_impression = 1 THEN user_id END) AS users_impression,
        COUNT(DISTINCT CASE WHEN is_click = 1 THEN user_id END) AS users_click
    FROM fact_ad_events
) AS funnel_users

UNION ALL

SELECT
    'Top-of-Funnel',
    'Impression → Engagement',
    ROUND(users_engagement * 100.0 / NULLIF(users_impression,0),2)
FROM (
    SELECT
        COUNT(DISTINCT CASE WHEN is_impression = 1 THEN user_id END) AS users_impression,
        COUNT(DISTINCT CASE WHEN is_engagement = 1 THEN user_id END) AS users_engagement
    FROM fact_ad_events
) AS funnel_users

UNION ALL

SELECT
    'Top-of-Funnel',
    'Impression → Purchase',
    ROUND(users_purchase * 100.0 / NULLIF(users_impression,0),2)
FROM (
    SELECT
        COUNT(DISTINCT CASE WHEN is_impression = 1 THEN user_id END) AS users_impression,
        COUNT(DISTINCT CASE WHEN is_purchase = 1 THEN user_id END) AS users_purchase
    FROM fact_ad_events
) AS funnel_users;

-- Conversion rate by funnel step (biggest drop-off)
WITH step_conversion AS (
    SELECT
        'Impression → Click' AS stage,
        COUNT(DISTINCT CASE WHEN is_impression = 1 THEN user_id END) AS users_previous,
        COUNT(DISTINCT CASE WHEN is_click = 1 THEN user_id END) AS users_current
    FROM fact_ad_events
    UNION ALL
    SELECT
        'Click → Engagement',
        COUNT(DISTINCT CASE WHEN is_click = 1 THEN user_id END),
        COUNT(DISTINCT CASE WHEN is_engagement = 1 THEN user_id END)
    FROM fact_ad_events
    UNION ALL
    SELECT
        'Engagement → Purchase',
        COUNT(DISTINCT CASE WHEN is_engagement = 1 THEN user_id END),
        COUNT(DISTINCT CASE WHEN is_purchase = 1 THEN user_id END)
    FROM fact_ad_events
)
SELECT
    stage,
    users_previous,
    users_current,
    ROUND(users_current * 100.0 / NULLIF(users_previous,0),2) AS conversion_percentage,
    ROUND((users_previous - users_current) * 100.0 / NULLIF(users_previous,0),2) AS drop_off_percentage
FROM step_conversion
ORDER BY drop_off_percentage DESC;

-- Conversion rate by campaign (most efficient funnel)
WITH campaign_funnel AS (
    SELECT
        c.campaign_id,
        c.`name` AS campaign_name,
        COUNT(DISTINCT CASE WHEN fae.is_impression = 1 THEN fae.user_id END) AS users_impression,
        COUNT(DISTINCT CASE WHEN fae.is_purchase = 1 THEN fae.user_id END) AS users_purchase
    FROM fact_ad_events fae
    JOIN dim_ads da ON fae.ad_id = da.ad_id
    JOIN dim_campaigns c ON da.campaign_id = c.campaign_id
    GROUP BY c.campaign_id, c.`name`
)
SELECT
    campaign_id,
    campaign_name,
    ROUND(users_purchase * 100.0 / NULLIF(users_impression,0),2) AS conversion_impression_to_purchase
FROM campaign_funnel
ORDER BY conversion_impression_to_purchase DESC;


-- Conversion rate by engagement (Engaged vs Non-Engaged users)
WITH user_engagement AS (
    SELECT
        user_id,
        MAX(is_engagement) AS ever_engaged,
        MAX(is_purchase) AS ever_purchased
    FROM fact_ad_events
    GROUP BY user_id
),
totals AS (
    SELECT
        CASE WHEN ever_engaged = 1 THEN 'Engaged' ELSE 'Non-Engaged' END AS user_group,
        COUNT(*) AS total_users,
        SUM(ever_purchased) AS users_who_purchased
    FROM user_engagement
    GROUP BY user_group
)
SELECT
    user_group,
    total_users,
    users_who_purchased,
    ROUND(users_who_purchased * 100.0 / NULLIF(total_users,0),2) AS conversion_rate_percentage
FROM totals;

-- Engagement rate by type (most common engagement type)
SELECT
    event_type AS engagement_type,
    COUNT(DISTINCT user_id) AS unique_users,
    ROUND(COUNT(DISTINCT user_id) * 100.0 / 
          (SELECT COUNT(DISTINCT user_id) 
           FROM fact_ad_events 
           WHERE event_type IN ('like','comment','share')), 2) AS percent_of_users
FROM fact_ad_events
WHERE event_type IN ('like','comment','share')
GROUP BY event_type
ORDER BY percent_of_users DESC;

-- Engagement rate by campaign
WITH campaign_engagement AS (
    SELECT
        c.campaign_id,
        c.`name` AS campaign_name,
        COUNT(DISTINCT CASE WHEN fae.is_engagement = 1 THEN fae.user_id END) AS engaged_users,
        COUNT(DISTINCT CASE WHEN fae.is_click = 1 THEN fae.user_id END) AS clicked_users
    FROM fact_ad_events fae
    JOIN dim_ads da ON fae.ad_id = da.ad_id
    JOIN dim_campaigns c ON da.campaign_id = c.campaign_id
    GROUP BY c.campaign_id, c.`name`
)
SELECT
    campaign_id,
    campaign_name,
    engaged_users,
    clicked_users,
    ROUND(engaged_users * 100.0 / NULLIF(clicked_users,0),2) AS engagement_rate_percentage
FROM campaign_engagement
ORDER BY engagement_rate_percentage DESC;


-- Conversion rate by age group
WITH age_conversion AS (
    SELECT
        u.age_group,
        COUNT(DISTINCT CASE WHEN fae.is_impression = 1 THEN fae.user_id END) AS users_impression,
        COUNT(DISTINCT CASE WHEN fae.is_purchase = 1 THEN fae.user_id END) AS users_purchase
    FROM fact_ad_events fae
    JOIN dim_users u ON fae.user_id = u.user_id
    GROUP BY u.age_group
)
SELECT
    age_group,
    users_impression,
    users_purchase,
    ROUND(users_purchase * 100.0 / NULLIF(users_impression,0),2) AS conversion_rate_percentage
FROM age_conversion
ORDER BY conversion_rate_percentage DESC;

-- Conversion rate by gender
WITH gender_conversion AS (
    SELECT
        u.user_gender,
        COUNT(DISTINCT CASE WHEN fae.is_impression = 1 THEN fae.user_id END) AS users_impression,
        COUNT(DISTINCT CASE WHEN fae.is_purchase = 1 THEN fae.user_id END) AS users_purchase
    FROM fact_ad_events fae
    JOIN dim_users u ON fae.user_id = u.user_id
    GROUP BY u.user_gender
)
SELECT
    user_gender,
    users_impression,
    users_purchase,
    ROUND(users_purchase * 100.0 / NULLIF(users_impression,0),2) AS conversion_rate_percentage
FROM gender_conversion
ORDER BY conversion_rate_percentage DESC;

-- Conversion rate by interest 
WITH exploded_interests AS (
    SELECT
        fae.user_id,
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(u.interests, ',', n.n), ',', -1)) AS interest,
        fae.is_impression,
        fae.is_purchase
    FROM fact_ad_events fae
    JOIN dim_users u ON fae.user_id = u.user_id
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
    ) n ON n.n <= 1 + LENGTH(u.interests) - LENGTH(REPLACE(u.interests, ',', ''))
)
SELECT
    interest,
    COUNT(DISTINCT CASE WHEN is_impression = 1 THEN user_id END) AS users_impression,
    COUNT(DISTINCT CASE WHEN is_purchase = 1 THEN user_id END) AS users_purchase,
    ROUND(COUNT(DISTINCT CASE WHEN is_purchase = 1 THEN user_id END) * 100.0 /
          NULLIF(COUNT(DISTINCT CASE WHEN is_impression = 1 THEN user_id END),0),2) AS conversion_rate_percentage
FROM exploded_interests
GROUP BY interest
ORDER BY conversion_rate_percentage DESC;

-- Conversion rate by platform 
WITH platform_conversion AS (
    SELECT
        da.ad_platform,
        COUNT(DISTINCT CASE WHEN fae.is_impression = 1 THEN fae.user_id END) AS users_impression,
        COUNT(DISTINCT CASE WHEN fae.is_purchase = 1 THEN fae.user_id END) AS users_purchase
    FROM fact_ad_events fae
    JOIN dim_ads da ON fae.ad_id = da.ad_id
    GROUP BY da.ad_platform
)
SELECT
    ad_platform,
    users_impression,
    users_purchase,
    ROUND(users_purchase * 100.0 / NULLIF(users_impression,0),2) AS conversion_rate_percentage
FROM platform_conversion
ORDER BY conversion_rate_percentage DESC;

-- Conversion rate by adtype 
WITH adtype_conversion AS (
    SELECT
        da.ad_type,
        COUNT(DISTINCT CASE WHEN fae.is_impression = 1 THEN fae.user_id END) AS users_impression,
        COUNT(DISTINCT CASE WHEN fae.is_purchase = 1 THEN fae.user_id END) AS users_purchase
    FROM fact_ad_events fae
    JOIN dim_ads da ON fae.ad_id = da.ad_id
    GROUP BY da.ad_type
)
SELECT
    ad_type,
    users_impression,
    users_purchase,
    ROUND(users_purchase * 100.0 / NULLIF(users_impression,0),2) AS conversion_rate_percentage
FROM adtype_conversion
ORDER BY conversion_rate_percentage DESC;

-- Conversion rate by temporal & behavioral metrics -- Average Time to Purchase (per user)
WITH user_first_impression AS (
    SELECT
        user_id,
        MIN(event_date) AS first_impression_date
    FROM fact_ad_events
    WHERE is_impression = 1
    GROUP BY user_id
),
user_purchase AS (
    SELECT
        user_id,
        MIN(event_date) AS first_purchase_date
    FROM fact_ad_events
    WHERE is_purchase = 1
    GROUP BY user_id
),
user_conversion_time AS (
    SELECT
        ufi.user_id,
        DATEDIFF(up.first_purchase_date, ufi.first_impression_date) AS days_to_purchase
    FROM user_first_impression ufi
    JOIN user_purchase up ON ufi.user_id = up.user_id
    WHERE DATEDIFF(up.first_purchase_date, ufi.first_impression_date) >= 0
)
SELECT
    ROUND(AVG(days_to_purchase),2) AS avg_days_to_purchase,
    MIN(days_to_purchase) AS min_days_to_purchase,
    MAX(days_to_purchase) AS max_days_to_purchase
FROM user_conversion_time;

-- Conversion rate by hour of day
WITH time_conversion AS (
    SELECT
        event_hour,
        COUNT(DISTINCT CASE WHEN is_click = 1 THEN user_id END) AS users_clicked,
        COUNT(DISTINCT CASE WHEN is_purchase = 1 THEN user_id END) AS users_purchased
    FROM fact_ad_events
    GROUP BY event_hour
)
SELECT
    event_hour,
    users_clicked,
    users_purchased,
    ROUND(users_purchased * 100.0 / NULLIF(users_clicked,0),2) AS conversion_rate_percentage
FROM time_conversion
ORDER BY conversion_rate_percentage DESC;

-- Conversion rate by time of day (categorical)
WITH time_of_day_conversion AS (
    SELECT
        time_of_day,
        COUNT(DISTINCT CASE WHEN is_click = 1 THEN user_id END) AS users_clicked,
        COUNT(DISTINCT CASE WHEN is_purchase = 1 THEN user_id END) AS users_purchased
    FROM fact_ad_events
    GROUP BY time_of_day
)
SELECT
    time_of_day,
    users_clicked,
    users_purchased,
    ROUND(users_purchased * 100.0 / NULLIF(users_clicked,0),2) AS conversion_rate_percentage
FROM time_of_day_conversion
ORDER BY conversion_rate_percentage DESC;


-- Conversion rate by day of week
WITH day_of_week_conversion AS (
    SELECT
        day_of_week,
        COUNT(DISTINCT CASE WHEN is_click = 1 THEN user_id END) AS users_clicked,
        COUNT(DISTINCT CASE WHEN is_purchase = 1 THEN user_id END) AS users_purchased
    FROM fact_ad_events
    GROUP BY day_of_week
)
SELECT
    day_of_week,
    users_clicked,
    users_purchased,
    ROUND(users_purchased * 100.0 / NULLIF(users_clicked,0),2) AS conversion_rate_percentage
FROM day_of_week_conversion
ORDER BY conversion_rate_percentage DESC;


