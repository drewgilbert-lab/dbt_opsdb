{{
    config(
        materialized='table',
        tags=['gtm', 'salesforce', 'staging']
    )
}}

/*
    Staging model for Salesforce Campaign Influence
    Source: rev_ops_prod.gtm_raw.campaign_influence (via Fivetran)

    IMPORTANT: This model ONLY includes fields specified in Google Sheets specification
    "SFDC Objects + Fields - CampaignInfluence.csv"

    Field count: 11 fields (as of 2025-11-12)
    Campaign Influence tracks multi-touch attribution linking campaigns to opportunities.
*/

with source as (
    select * from {{ source('salesforce', 'campaign_influence') }}
),

deduplicated as (
    select
        -- Primary Keys & Relationships
        id,
        campaign_id,
        opportunity_id,
        contact_id,
        campaign_member_id,
        opportunity_contact_role_id,
        model_id,

        -- Attribution Metrics
        influence,
        revenue_share,

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
