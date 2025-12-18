{{
    config(
        materialized='table',
        tags=['gtm', 'core', 'fact', 'adroll']
    )
}}

/*
    RollWorks Account Summary Fact Table

    Purpose: RollWorks advertising metrics aggregated by account
    Source: stg_salesforce__adroll_account_summary_c
    Grain: One row per account summary record (time period x account)

    Field count: 24 fields from Salesforce
    Specification: SFDC Objects + Fields - RollWorks Advertising.csv

    Relationships:
    - adroll_account_c → dim_account.id

    Use Cases:
    - Account-based marketing (ABM) performance
    - Account-level advertising attribution
    - Ad spend and engagement by account
*/

SELECT
    -- Primary Key
    id,

    -- Record Identity
    name,
    owner_id,

    -- Foreign Keys
    adroll_account_c,

    -- Account Identification
    adroll_website_c,

    -- Date Range
    adroll_start_date_c,
    adroll_end_date_c,
    adroll_look_back_days_c,

    -- Advertising Metrics
    adroll_impressions_c,
    adroll_clicks_c,
    adroll_impression_costs_c,
    adroll_page_views_c,

    -- Conversion Metrics
    adroll_click_conversion_c,
    adroll_view_conversion_c,
    adroll_conversions_c,

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

FROM {{ ref('stg_salesforce__adroll_account_summary_c') }}
