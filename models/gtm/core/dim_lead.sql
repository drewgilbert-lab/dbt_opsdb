{{
    config(
        materialized='table',
        tags=['gtm', 'core', 'dimension']
    )
}}

/*
    Lead Dimension Table

    Purpose: Lead data from Salesforce - EXACT MATCH to Google Sheets specification
    Source: stg_salesforce__lead
    Grain: One row per lead

    IMPORTANT: This model ONLY includes fields from "SFDC Objects + Fields - Lead.csv"
    Field count: 52 fields from Salesforce + minimal metadata
    Note: Address compound field not included (components not specified in CSV)

    Google Sheets Specification: /Users/eliakemp/Downloads/SFDC Objects + Fields - Lead.csv
    Last Updated: 2025-11-12
*/

SELECT
    -- Primary Keys & Relationships
    id,
    account_id_c,
    created_by_id,
    owner_id,

    -- Lead Identity
    company,
    title,
    email,
    phone,

    -- Contact Information
    agency_sdr_c,
    contact_state_c,
    department_c,
    direct_line_c,
    time_zone_c,

    -- Lead Classification
    matched_account_type_c,
    persona_c,
    position_c,

    -- Lead Status & Lifecycle
    status,
    lead_status_mapping_c,
    lead_stage_c,
    outcome_reason_c,

    -- Dates
    date_unsubscribed_c,
    dq_date_c,
    mel_date_c,
    original_mel_date_c,
    mql_date_c,
    original_mql_date_c,
    original_sal_date_c,
    sal_date_c,
    sql_date_c,

    -- Email & Communication Preferences
    has_opted_out_of_email,
    email_opt_out_date_c,
    do_not_call,

    -- Campaign Attribution
    recent_campaign_c,
    source_first_c,
    source_last_c,
    source_detail_first_c,
    source_detail_last_c,
    reporting_source_c,

    -- Marketing
    form_type_c,
    mql_description_c,

    -- Account Matching
    matched_account_owner_c,
    name_company_c,

    -- Additional Details
    description,
    microsite_url_competitive_intelligence_c,

    -- Third Party Integration
    adroll_roll_works_sourced_c,
    sync_to_marketo_c,

    -- UTM Parameters
    utm_campaign_c,
    utm_content_c,
    utm_medium_c,
    utm_source_c,
    utm_term_c,

    -- Metadata
    last_synced_at,
    CURRENT_TIMESTAMP() as dbt_updated_at

FROM {{ ref('stg_salesforce__lead') }}

-- Test data filtering applied at staging layer (stg_salesforce__lead)
-- Staging filters: Hogwarts test leads excluded
