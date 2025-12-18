{{
    config(
        materialized='table',
        tags=['gtm', 'core', 'dimension']
    )
}}

/*
    Account Dimension

    Purpose: Account data from Salesforce - EXACT MATCH to Google Sheets specification
    Source: stg_salesforce__account
    Grain: One row per account

    IMPORTANT: This model ONLY includes fields from "SFDC Objects + Fields - Account.csv"
    Field count: 42 fields from Salesforce + minimal metadata
    Note: BillingAddress compound field excluded (components included)

    Google Sheets Specification: /Users/eliakemp/Downloads/SFDC Objects + Fields - Account.csv
    Last Updated: 2025-11-07
*/

SELECT
    -- Primary Key & Owner
    id,
    owner_id,

    -- Basic Account Info
    name,
    type,
    parent_id,

    -- Billing Address (component fields only)
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

    -- PRIMARY SEGMENT FIELD (Critical! - replaces old account_segment)
    -- Per colleague feedback: "the primary segment field is hg_account_segment__c"
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

    -- Metadata
    last_synced_at,
    CURRENT_TIMESTAMP() as dbt_updated_at

FROM {{ ref('stg_salesforce__account') }}

-- Test data filtering applied at staging layer (stg_salesforce__account)
-- Staging filters: Hogwarts test accounts excluded
