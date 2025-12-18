{{
    config(
        materialized='table',
        tags=['gtm', 'salesforce', 'staging']
    )
}}

/*
    Staging model for Salesforce Campaign Member
    Source: rev_ops_prod.gtm_raw.campaign_member (via Fivetran)

    IMPORTANT: This model ONLY includes fields specified in Google Sheets specification
    "SFDC Objects + Fields - CampaignMember.csv"

    Field count: 49 fields (as of 2025-11-07)
    Note: Lead_segment__c and contact_segment__c are in CSV but don't exist in database - removed
    Campaign Members link leads/contacts to campaigns with status tracking.
*/

with source as (
    select * from {{ source('salesforce', 'campaign_member') }}
),

deduplicated as (
    select
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
        -- lead_segment_c doesn't exist in database (in CSV but not synced by Fivetran)
        -- contact_segment_c doesn't exist in database (in CSV but not synced by Fivetran)
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
