{{
    config(
        materialized='table',
        tags=['gtm', 'salesforce', 'staging', 'adroll']
    )
}}

/*
    Staging model for Salesforce adroll__RollWorks_Tracking_Data_Aggregation__c
    Source: rev_ops_prod.gtm_raw.adroll_roll_works_tracking_data_aggregation_c (via Fivetran)

    Field count: 26 fields (as of 2025-11-20)
    Specification: SFDC Objects + Fields - RollWorks Tracking Data Aggregation.csv

    Purpose: Aggregated RollWorks tracking data. This is the LARGEST AdRoll object
    with comprehensive metrics rolled up by date and user/account.

    Transformations:
    - Remove soft deletes (is_deleted = true, _fivetran_deleted = true)
    - Deduplicate by ID (keep most recent _fivetran_synced)
*/

with source as (
    select * from {{ source('salesforce', 'adroll_roll_works_tracking_data_aggregation_c') }}
),

deduplicated as (
    select
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

        -- Soft Delete Flag (for reference)
        is_deleted,

        -- Fivetran Metadata
        _fivetran_synced as last_synced_at,
        _fivetran_deleted

    from source

    where
        -- Remove soft deletes
        coalesce(is_deleted, false) = false
        and coalesce(_fivetran_deleted, false) = false

    -- Deduplicate
    qualify row_number() over (
        partition by id
        order by _fivetran_synced desc
    ) = 1
)

select * from deduplicated
