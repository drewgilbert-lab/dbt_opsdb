{{
    config(
        materialized='table',
        tags=['gtm', 'core', 'fact', 'adroll']
    )
}}

/*
    RollWorks Tracking Data Fact Table

    Purpose: Daily RollWorks advertising tracking data by user
    Source: stg_salesforce__adroll_ad_roll_tracking_data_c
    Grain: One row per day per user (daily granular metrics)

    Field count: 27 fields from Salesforce
    Specification: SFDC Objects + Fields - RollWorks Tracking Data.csv

    Relationships:
    - adroll_contact_c → dim_contact.id
    - adroll_lead_c → dim_lead.id

    Use Cases:
    - Daily advertising performance tracking
    - Granular user engagement analysis
    - Time-series advertising metrics
    - Cross-device tracking via email lists
*/

SELECT
    -- Primary Key
    id,

    -- Record Identity
    name,
    owner_id,

    -- Foreign Keys (User References)
    adroll_contact_c,
    adroll_lead_c,

    -- User Identification
    adroll_email_c,
    adroll_xdevice_email_list_c,

    -- Date
    adroll_date_c,

    -- Advertising Metrics
    adroll_impressions_c,
    adroll_clicks_c,
    adroll_impression_costs_c,
    adroll_click_costs_c,

    -- Conversion Metrics
    adroll_click_conversion_c,
    adroll_view_conversion_c,

    -- Processing Flags
    adroll_is_aggregated_c,
    adroll_processed_c,

    -- Error Tracking
    adroll_error_c,

    -- Audit Fields
    created_date,
    created_by_id,
    last_modified_date,
    last_modified_by_id,
    system_modstamp,
    last_viewed_date,
    last_referenced_date,

    -- Soft Delete Flag
    is_deleted,

    -- Fivetran Metadata
    _fivetran_deleted,

    -- Metadata
    last_synced_at,
    CURRENT_TIMESTAMP() as dbt_updated_at

FROM {{ ref('stg_salesforce__adroll_ad_roll_tracking_data_c') }}
