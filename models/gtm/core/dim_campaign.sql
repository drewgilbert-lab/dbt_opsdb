{{
    config(
        materialized='table',
        tags=['gtm', 'core', 'dimension']
    )
}}

/*
    Campaign Dimension Table

    Purpose: Campaign master data for marketing attribution - EXACT MATCH to Google Sheets specification
    Source: stg_salesforce__campaign
    Grain: One row per campaign

    IMPORTANT: This model ONLY includes fields from "SFDC Objects + Fields - Campaign.csv"
    Field count: 40 fields from Salesforce + minimal metadata
    Note: HierarchyNumberOfResponses was in CSV but doesn't exist in database - removed

    Google Sheets Specification: /Users/eliakemp/Downloads/SFDC Objects + Fields - Campaign.csv
    Last Updated: 2025-11-12
*/

SELECT
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

    -- Campaign Routing Flags
    route_to_bdr_c,
    route_to_sales_c,
    assign_to_sdrs_c,

    -- Campaign Assets
    related_asset_c,

    -- Metadata
    last_synced_at,
    CURRENT_TIMESTAMP() as dbt_updated_at

FROM {{ ref('stg_salesforce__campaign') }}

-- No additional filtering - all campaigns pass through
