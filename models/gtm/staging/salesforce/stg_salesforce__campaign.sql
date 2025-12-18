{{
    config(
        materialized='table',
        tags=['gtm', 'salesforce', 'staging']
    )
}}

/*
    Staging model for Salesforce Campaign
    Source: rev_ops_prod.gtm_raw.campaign (via Fivetran)

    IMPORTANT: This model ONLY includes fields specified in Google Sheets specification
    "SFDC Objects + Fields - Campaign.csv"

    Field count: 40 fields (as of 2025-11-07)
    Note: HierarchyNumberOfResponses is in CSV but doesn't exist in database - removed
    Campaigns represent marketing initiatives for attribution and ROI analysis.
*/

with source as (
    select * from {{ source('salesforce', 'campaign') }}
),

deduplicated as (
    select
        -- Primary Key & Relationships
        id,
        parent_id,
        owner_id,
        record_type_id,
        created_by_id,
        last_modified_by_id,

        -- Campaign Identity
        name,
        description,
        type,
        status,
        is_active,

        -- Campaign Categorization
        channel_c,
        source_c,
        source_detail_c,
        program_c,
        db_campaign_tactic_c,
        marketing_or_sales_generated_c,

        -- Campaign Dates
        start_date,
        end_date,
        created_date,
        last_modified_date,
        last_activity_date,

        -- Campaign Costs
        budgeted_cost,
        actual_cost,
        cost_per_response_c,

        -- Campaign Expected Revenue
        expected_revenue,
        expected_response,

        -- Campaign Metrics (Salesforce rollup fields)
        number_sent,
        number_of_leads,
        number_of_converted_leads,
        number_of_contacts,
        number_of_responses,
        number_of_opportunities,
        number_of_won_opportunities,
        amount_all_opportunities,
        amount_won_opportunities,
        -- hierarchy_number_of_responses doesn't exist in database (in CSV but not synced by Fivetran)

        -- Campaign Routing Flags
        route_to_bdr_c,
        route_to_sales_c,
        assign_to_sdrs_c,

        -- Campaign Assets
        related_asset_c,

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
