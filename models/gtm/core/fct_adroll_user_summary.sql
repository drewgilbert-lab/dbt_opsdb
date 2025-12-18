{{
    config(
        materialized='table',
        tags=['gtm', 'core', 'fact', 'adroll']
    )
}}

/*
    RollWorks User Summary Fact Table

    Purpose: RollWorks advertising metrics aggregated by user (Contact/Lead)
    Source: stg_salesforce__adroll_user_summary_c
    Grain: One row per user summary record (time period x user)

    Field count: 23 fields from Salesforce
    Specification: SFDC Objects + Fields - RollWorks User Summary.csv

    Relationships:
    - adroll_contact_c → dim_contact.id
    - adroll_lead_c → dim_lead.id

    Use Cases:
    - User-level advertising attribution
    - Contact/Lead engagement tracking
    - Advertising ROI by individual
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

    -- Date Range
    adroll_start_date_c,
    adroll_end_date_c,
    adroll_look_back_days_c,

    -- Advertising Metrics
    adroll_impressions_c,
    adroll_clicks_c,
    adroll_impression_costs_c,

    -- Conversion Metrics
    adroll_click_conversion_c,
    adroll_view_conversion_c,

    -- Audit Fields
    created_date,
    created_by_id,
    last_modified_date,
    last_modified_by_id,
    system_modstamp,
    last_activity_date,

    -- Soft Delete Flag
    is_deleted,

    -- Fivetran Metadata
    _fivetran_deleted,

    -- Metadata
    last_synced_at,
    CURRENT_TIMESTAMP() as dbt_updated_at

FROM {{ ref('stg_salesforce__adroll_user_summary_c') }}
