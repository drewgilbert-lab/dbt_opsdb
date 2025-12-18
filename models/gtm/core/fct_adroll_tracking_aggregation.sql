{{
    config(
        materialized='table',
        tags=['gtm', 'core', 'fact', 'adroll']
    )
}}

/*
    RollWorks Tracking Data Aggregation Fact Table

    Purpose: Aggregated RollWorks advertising metrics (largest AdRoll dataset)
    Source: stg_salesforce__adroll_roll_works_tracking_data_aggregation_c
    Grain: Date x User/Account (aggregated metrics)

    Field count: 26 fields from Salesforce
    Specification: SFDC Objects + Fields - RollWorks Tracking Data Aggregation.csv

    Relationships:
    - adroll_account_c → dim_account.id
    - adroll_contact_c → dim_contact.id
    - adroll_lead_c → dim_lead.id

    Use Cases:
    - High-level advertising performance analysis
    - Aggregated metrics for reporting dashboards
    - Account and user engagement over time
    - Ad spend ROI at scale
*/

SELECT
    -- Primary Key
    id,

    -- Record Identity
    name,
    owner_id,

    -- Foreign Keys
    adroll_account_c,
    adroll_contact_c,
    adroll_lead_c,

    -- User/Account Identification
    adroll_email_c,
    adroll_website_c,
    adroll_xdevice_email_list_c,

    -- Date
    adroll_date_c,

    -- Advertising Metrics
    adroll_impressions_c,
    adroll_clicks_c,
    adroll_impression_costs_c,
    adroll_page_views_c,

    -- Conversion Metrics
    adroll_click_conversion_c,
    adroll_view_conversion_c,
    adroll_total_conversions_c,

    -- Calculated Metrics
    adroll_ctr_c,

    -- Audit Fields
    created_date,
    created_by_id,
    last_modified_date,
    last_modified_by_id,
    system_modstamp,

    -- Soft Delete Flag
    is_deleted,

    -- Fivetran Metadata
    _fivetran_deleted,

    -- Metadata
    last_synced_at,
    CURRENT_TIMESTAMP() as dbt_updated_at

FROM {{ ref('stg_salesforce__adroll_roll_works_tracking_data_aggregation_c') }}
