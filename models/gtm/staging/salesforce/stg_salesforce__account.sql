{{
    config(
        materialized='table',
        tags=['gtm', 'salesforce', 'staging']
    )
}}

/*
    Staging model for Salesforce Accounts
    Source: rev_ops_prod.gtm_raw.account (via Fivetran)

    IMPORTANT: This model ONLY includes fields specified in Google Sheets specification
    "SFDC Objects + Fields - Account.csv"

    Field count: 42 fields (as of 2025-11-07)
    Note: BillingAddress is a compound field and not included (components are: BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude)
    Any fields not in the Google Sheets spec have been removed.

    Transformations:
    - Deduplication by id using _fivetran_synced
    - Remove soft deletes (is_deleted = false, _fivetran_deleted = false)
    - Column renaming to match dbt naming conventions (lowercase with underscores)
*/

with source as (
    select * from {{ source('salesforce', 'account') }}
),

deduplicated as (
    select
        -- Primary Key & Owner
        id,
        owner_id,

        -- Basic Account Info
        name,
        type,
        parent_id,

        -- Billing Address (component fields only - BillingAddress compound field not queryable)
        billing_street,
        billing_city,
        billing_state,
        billing_postal_code,
        billing_country,
        billing_latitude,
        billing_longitude,

        -- Firmographics
        industry,
        annual_revenue,
        number_of_employees,

        -- PRIMARY SEGMENT FIELD (Critical!)
        hg_account_segment_c,

        -- Product Usage
        active_platform_users_c,

        -- Opportunity Counts
        count_of_open_opportunities_c,
        count_of_won_opportunities_c,
        count_of_lost_opportunities_c,

        -- Revenue & Dates
        first_win_date_c,
        current_arr_c,

        -- Team Members
        sdr_c,
        csm_c,
        account_team_c,
        executive_sponsor_c,
        sales_engineer_domain_specialist_c,

        -- Pulse / Health Tracking
        pulse_c,
        pulse_notes_c,
        pulse_notes_history_c,
        days_since_pulse_last_updated_c,
        last_pulse_update_by_c,

        -- Pendo Usage Metrics
        pendo_usage_trending_c,
        pendo_events_c,
        pendo_days_active_c,
        pendo_opp_gen_saved_searches_c,
        pendo_account_upload_c,
        pendo_create_scoring_profile_c,
        pendo_mi_saved_report_c,
        pendo_exports_c,
        pendo_account_id_c,
        pendo_days_since_last_login_c,

        -- Fivetran Metadata
        _fivetran_synced as last_synced_at,
        _fivetran_deleted

    from source

    where
        -- Remove soft deletes
        coalesce(is_deleted, false) = false
        and coalesce(_fivetran_deleted, false) = false

        -- Exclude test/dummy accounts
        and lower(name) not like '%hogwarts%'

    -- Deduplicate: Keep most recent version of each account
    qualify row_number() over (
        partition by id
        order by _fivetran_synced desc
    ) = 1
)

select * from deduplicated
