{{
    config(
        materialized='table',
        tags=['gtm', 'core', 'fact']
    )
}}

/*
    Campaign Member Fact Table

    Purpose: Track leads/contacts in campaigns - EXACT MATCH to Google Sheets specification
    Source: stg_salesforce__campaign_member
    Grain: One row per campaign member

    IMPORTANT: This model ONLY includes fields from "SFDC Objects + Fields - CampaignMember.csv"
    Field count: 49 fields from Salesforce + minimal metadata
    Note: Lead_segment__c and contact_segment__c were in CSV but don't exist in database - removed

    Google Sheets Specification: /Users/eliakemp/Downloads/SFDC Objects + Fields - CampaignMember.csv
    Last Updated: 2025-11-07
*/

SELECT
    -- Primary Key & Relationships
    id,
    campaign_id,
    lead_id,
    contact_id,
    lead_or_contact_id,
    lead_or_contact_owner_id,

    -- Campaign Member Status
    status,
    has_responded,
    first_responded_date,

    -- Person Identity (denormalized from lead/contact)
    name,
    email,
    title,
    company_or_account,

    -- Person Location
    city,
    state,
    country,

    -- Person Contact Preferences
    do_not_call,
    has_opted_out_of_email,

    -- Description
    description,

    -- Lead Source & Attribution
    lead_source,
    utm_campaign_c,
    utm_source_c,
    utm_medium_c,
    utm_content_c,
    utm_term_c,
    utm_product_c,
    campaign_entry_source_c,
    campaign_name_c,

    -- Lead/Contact Lifecycle & Status
    lead_contact_status_c,
    lead_contact_lifecycle_stage_c,
    -- lead_segment_c removed (doesn't exist in database)
    -- contact_segment_c removed (doesn't exist in database)
    account_segment_c,
    persona_c,
    seniority_c,

    -- Milestone Dates
    mql_date_c,
    original_mql_date_c,
    sql_date_c,
    original_sql_date_c,
    mel_date_c,
    original_mel_date_c,

    -- Account Matching
    matched_account_c,
    matched_account_id_c,
    matched_account_owner_c,
    matched_account_sdr_c,
    matched_account_csm_c,

    -- Campaign Member Metrics
    meeting_sat_c,
    campaign_member_c,

    -- Process Flags
    most_recent_campaign_c,

    -- Dates
    created_date,
    last_modified_date,

    -- Metadata
    last_synced_at,
    CURRENT_TIMESTAMP() as dbt_updated_at

FROM {{ ref('stg_salesforce__campaign_member') }}

-- No additional filtering - all campaign members pass through
