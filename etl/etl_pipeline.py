import pandas as pd
import numpy as np
import csv  

# =========================================================
# HELPER FUNCTIONS
# =========================================================

def standardize_columns(df):
    df.columns = df.columns.str.lower().str.strip()
    return df

def clean_strings(series):
    return series.astype(str).str.lower().str.strip()

def remove_duplicates(df, key=None):
    if key:
        return df.drop_duplicates(subset=[key], keep='first')
    return df.drop_duplicates()

# =========================================================
# LOAD DATA
# =========================================================

fact_ad_events = pd.read_csv("fact_ad_events.csv")
dim_ads = pd.read_csv("dim_ads.csv")
dim_campaigns = pd.read_csv("dim_campaigns.csv")
dim_users = pd.read_csv("dim_users.csv")

# =========================================================
# DIM TABLE: dim_ads
# =========================================================

dim_ads = standardize_columns(dim_ads)
dim_ads = remove_duplicates(dim_ads, key='ad_id')

dim_ads['ad_platform'] = clean_strings(dim_ads['ad_platform'])
dim_ads['ad_type'] = clean_strings(dim_ads['ad_type'])
dim_ads['target_gender'] = clean_strings(dim_ads['target_gender'])
dim_ads['target_age_group'] = clean_strings(dim_ads['target_age_group'])
dim_ads['target_interests'] = clean_strings(dim_ads['target_interests'])

valid_platforms = ['facebook', 'instagram']
dim_ads = dim_ads[dim_ads['ad_platform'].isin(valid_platforms)]

dim_ads['target_interests'] = dim_ads['target_interests'].str.replace(', ', ',', regex=False)

dim_ads = dim_ads.dropna(subset=['ad_id', 'campaign_id'])

# =========================================================
# DIM TABLE: dim_users
# =========================================================

dim_users = standardize_columns(dim_users)

dim_users['user_gender'] = clean_strings(dim_users['user_gender'])
dim_users['age_group'] = clean_strings(dim_users['age_group'])
dim_users['interests'] = clean_strings(dim_users['interests'])
dim_users['country'] = clean_strings(dim_users['country'])
dim_users['location'] = clean_strings(dim_users['location'])

dim_users = dim_users.dropna(subset=['user_id'])
dim_users = remove_duplicates(dim_users, key='user_id')

# =========================================================
# DIM TABLE: dim_campaigns
# =========================================================

dim_campaigns = standardize_columns(dim_campaigns)
dim_campaigns['name'] = clean_strings(dim_campaigns['name'])

dim_campaigns['start_date'] = pd.to_datetime(dim_campaigns['start_date'], errors='coerce')
dim_campaigns['end_date'] = pd.to_datetime(dim_campaigns['end_date'], errors='coerce')

dim_campaigns = dim_campaigns.dropna(subset=['start_date', 'end_date'])

dim_campaigns['duration_days'] = (dim_campaigns['end_date'] - dim_campaigns['start_date']).dt.days

dim_campaigns['total_budget'] = pd.to_numeric(
    dim_campaigns['total_budget'].astype(str).str.replace(' ', ''), errors='coerce'
)

dim_campaigns = dim_campaigns.dropna(subset=['total_budget', 'campaign_id'])
dim_campaigns = remove_duplicates(dim_campaigns, key='campaign_id')

# =========================================================
# FACT TABLE
# =========================================================

fact_ad_events = standardize_columns(fact_ad_events)
fact_ad_events['event_type'] = clean_strings(fact_ad_events['event_type'])

valid_events = ['impression', 'click', 'like', 'comment', 'share', 'purchase']
fact_ad_events = fact_ad_events[fact_ad_events['event_type'].isin(valid_events)]

# Clean timestamp
fact_ad_events['timestamp'] = fact_ad_events['timestamp'].str.replace(
    r'\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)$',
    '',
    regex=True
)

fact_ad_events['timestamp'] = pd.to_datetime(fact_ad_events['timestamp'], errors='coerce')

# ✅ FIXED DATE (THIS WAS YOUR ERROR)
fact_ad_events['event_date'] = fact_ad_events['timestamp'].dt.strftime('%Y-%m-%d')
fact_ad_events['event_hour'] = fact_ad_events['timestamp'].dt.hour

fact_ad_events = fact_ad_events.drop(columns=['timestamp'])

# Clean categorical
fact_ad_events['day_of_week'] = clean_strings(fact_ad_events['day_of_week'])
fact_ad_events['time_of_day'] = clean_strings(fact_ad_events['time_of_day'])

fact_ad_events = remove_duplicates(fact_ad_events)

# =========================================================
# ADD campaign_id TO FACT
# =========================================================

fact_ad_events = fact_ad_events.merge(
    dim_ads[['ad_id', 'campaign_id']],
    on='ad_id',
    how='left'
)

print("Missing campaign_id:", fact_ad_events['campaign_id'].isna().sum())

# =========================================================
# FEATURE ENGINEERING
# =========================================================

fact_ad_events['is_impression'] = (fact_ad_events['event_type'] == 'impression').astype(int)
fact_ad_events['is_click'] = (fact_ad_events['event_type'] == 'click').astype(int)
fact_ad_events['is_purchase'] = (fact_ad_events['event_type'] == 'purchase').astype(int)
fact_ad_events['is_engagement'] = fact_ad_events['event_type'].isin(
    ['like', 'comment', 'share']
).astype(int)

# =========================================================
# REMOVE campaign_id FROM dim_ads
# =========================================================

dim_ads = dim_ads.drop(columns=['campaign_id'])

# =========================================================
# FILTER VALID KEYS
# =========================================================

fact_ad_events = fact_ad_events[
    fact_ad_events['user_id'].isin(dim_users['user_id']) &
    fact_ad_events['ad_id'].isin(dim_ads['ad_id']) &
    fact_ad_events['campaign_id'].isin(dim_campaigns['campaign_id'])
]

# =========================================================
# REORDER COLUMNS 
# =========================================================

fact_ad_events = fact_ad_events[[
    'event_id',
    'ad_id',
    'user_id',
    'campaign_id',   
    'day_of_week',
    'time_of_day',
    'event_type',
    'event_date',
    'event_hour',
    'is_impression',
    'is_click',
    'is_purchase',
    'is_engagement'
]]

# =========================================================
# EXPORT
# =========================================================

fact_ad_events.to_csv(
    "fact_ad_events_cleaned.csv",
    index=False,
    quoting=csv.QUOTE_ALL,
    lineterminator='\r\n'
)

dim_ads.to_csv(
    "dim_ads_cleaned.csv",
    index=False,
    quoting=csv.QUOTE_ALL,
    lineterminator='\r\n'
)

dim_users.to_csv(
    "dim_users_cleaned.csv",
    index=False,
    quoting=csv.QUOTE_ALL,
    lineterminator='\r\n'
)

dim_campaigns.to_csv(
    "dim_campaigns_cleaned.csv",
    index=False,
    quoting=csv.QUOTE_ALL,
    lineterminator='\r\n'
)

print("ETL complete")