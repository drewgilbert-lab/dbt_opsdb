{{
    config(
        materialized='table',
        tags=['gtm', 'core', 'fact']
    )
}}

/*
    Event Fact Table

    Purpose: Track calendar events and meetings - EXACT MATCH to Google Sheets specification
    Source: stg_salesforce__event
    Grain: One row per event

    IMPORTANT: This model ONLY includes fields from "SFDC Objects + Fields - Event.csv"
    Field count: 24 fields from Salesforce + minimal metadata

    Google Sheets Specification: /Users/eliakemp/Downloads/SFDC Objects + Fields - Event.csv
    Last Updated: 2025-11-07
*/

SELECT
    -- Primary Key & Relationships
    id,
    who_id,
    what_id,
    account_id,
    owner_id,
    created_by_id,

    -- Event Attributes
    subject,
    type,
    location,
    description,

    -- Event Timing
    start_date_time,
    end_date_time,
    activity_date,
    activity_date_time,
    duration_in_minutes,

    -- Event Flags
    is_all_day_event,
    is_private,
    show_as,

    -- Recurrence Fields
    is_recurrence,
    recurrence_type,
    recurrence_interval,
    recurrence_end_date_only,

    -- Dates
    created_date,
    last_modified_date,

    -- Metadata
    last_synced_at,
    CURRENT_TIMESTAMP() as dbt_updated_at

FROM {{ ref('stg_salesforce__event') }}

-- No additional filtering - all events pass through
