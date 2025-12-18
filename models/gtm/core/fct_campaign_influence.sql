{{
    config(
        materialized='table',
        tags=['gtm', 'core', 'fact']
    )
}}

/*
    Campaign Influence Fact Table

    Purpose: Multi-touch attribution linking campaigns to opportunities - EXACT MATCH to Google Sheets specification
    Source: stg_salesforce__campaign_influence
    Grain: One row per campaign-opportunity influence record

    IMPORTANT: This model ONLY includes fields from "SFDC Objects + Fields - CampaignInfluence.csv"
    Field count: 11 fields from Salesforce + minimal metadata

    Google Sheets Specification: /Users/eliakemp/Downloads/SFDC Objects + Fields - CampaignInfluence.csv
    Last Updated: 2025-11-12
*/

SELECT
    -- Primary Key & Relationships
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

    -- Metadata
    last_synced_at,
    CURRENT_TIMESTAMP() as dbt_updated_at

FROM {{ ref('stg_salesforce__campaign_influence') }}

-- No additional filtering - all campaign influence records pass through
