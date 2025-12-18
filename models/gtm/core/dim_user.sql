{{
    config(
        materialized='table',
        tags=['gtm', 'core', 'dimension']
    )
}}

/*
    User Dimension Table

    Purpose: User master data for owner resolution - EXACT MATCH to Google Sheets specification
    Source: stg_salesforce__user
    Grain: One row per user

    IMPORTANT: This model ONLY includes fields from "SFDC Objects + Fields - User.csv"
    Field count: 15 fields from Salesforce + minimal metadata

    Google Sheets Specification: /Users/eliakemp/Downloads/SFDC Objects + Fields - User.csv
    Last Updated: 2025-11-07
*/

SELECT
    -- Primary Key
    id,

    -- User Identity
    name,

    -- User Status
    is_active,

    -- Relationships
    manager_id,
    user_role_id,
    contact_id,
    profile_id,

    -- User Organization
    role_name_c,
    department,
    title,

    -- Contact Info
    sender_email,
    city,
    state,
    time_zone_sid_key,

    -- Metadata
    last_synced_at,
    CURRENT_TIMESTAMP() as dbt_updated_at

FROM {{ ref('stg_salesforce__user') }}

-- No additional filtering - all users pass through
