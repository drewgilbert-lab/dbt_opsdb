{{
    config(
        materialized='table',
        tags=['gtm', 'core', 'dimension']
    )
}}

/*
    Contact Dimension Table

    Purpose: Contact data from Salesforce - EXACT MATCH to Google Sheets specification
    Source: stg_salesforce__contact
    Grain: One row per contact

    IMPORTANT: This model ONLY includes fields from "SFDC Objects + Fields - Contact.csv"
    Field count: 55 fields from Salesforce + minimal metadata
    Note: DoNotCall field not available in database (55 of 56 CSV fields)

    Google Sheets Specification: /Users/eliakemp/Downloads/SFDC Objects + Fields - Contact.csv
    Last Updated: 2025-11-12
*/

SELECT
    -- Primary Keys & Relationships
    id,
    owner_id,
    account_id,

    -- Contact Identity
    contact_full_id_c,
    name,
    contact_c,
    contact_source,
    contact_status_c,
    title,
    persona_c,
    sub_persona_c,
    seniority_c,
    email,
    contact_use_case_c,
    role_in_purchasing_c,
    time_zone_c,

    -- Platform User Fields
    platform_user_created_date_c,
    platform_user_last_login_c,
    platform_user_status_c,

    -- Customer Advisory Board
    cab_alternate_member_c,
    cab_primary_member_c,

    -- Email Preferences
    has_opted_out_of_email,
    email_opt_out_date_c,

    -- Engagement Flags
    referenceable_contact_c,

    -- Department
    department_c,

    -- Campaign Attribution
    recent_campaign_c,
    origin_campaign_c,
    source_first_c,
    source_last_c,
    source_detail_first_c,
    source_detail_last_c,

    -- Lifecycle Stage & Milestone Dates
    lifecycle_stage_c,
    mel_date_c,
    original_mel_date_c,
    mql_date_c,
    mql_description_c,
    original_mql_date_c,
    original_sal_date_c,
    sal_date_c,
    original_sql_date_c,
    sql_date_c,
    disqualified_reason_c,

    -- Additional Details
    description,
    -- do_not_call not available in database
    linkedin_profile_url_c,
    mailing_street,
    mailing_city,
    mailing_state,
    mailing_postal_code,
    mailing_country,
    microsite_url_competitive_intelligence_c,
    phone,

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

FROM {{ ref('stg_salesforce__contact') }}

-- No additional filtering - all contacts pass through
