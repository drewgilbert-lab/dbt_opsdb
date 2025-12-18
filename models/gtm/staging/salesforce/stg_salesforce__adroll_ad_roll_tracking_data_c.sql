{{
    config(
        materialized='table',
        tags=['gtm', 'salesforce', 'staging', 'adroll']
    )
}}

/*
    Staging model for Salesforce adroll__AdRoll_Tracking_Data__c (RollWorks Tracking Data)
    Source: rev_ops_prod.gtm_raw.adroll_ad_roll_tracking_data_c (via Fivetran)

    Field count: 27 fields (as of 2025-11-20)
    Specification: SFDC Objects + Fields - RollWorks Tracking Data.csv

    Purpose: Daily tracking data from RollWorks advertising platform.
    Granular daily metrics by user (Contact/Lead).

    Transformations:
    - Remove soft deletes (is_deleted = true, _fivetran_deleted = true)
    - Deduplicate by ID (keep most recent _fivetran_synced)
*/

with source as (
    select * from {{ source('salesforce', 'adroll_ad_roll_tracking_data_c') }}
),

deduplicated as (
    select
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
