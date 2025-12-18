{{
    config(
        materialized='table',
        tags=['gtm', 'core', 'fact']
    )
}}

/*
    Opportunity Fact Table

    Purpose: Core opportunity metrics - EXACT MATCH to Google Sheets specification
    Source: stg_salesforce__opportunity
    Grain: One row per opportunity

    IMPORTANT: This model ONLY includes fields from "SFDC Objects + Fields - Opportunity.csv"
    Field count: 52 fields from Salesforce + minimal metadata

    Google Sheets Specification: /Users/eliakemp/Downloads/SFDC Objects + Fields - Opportunity.csv
    Last Updated: 2025-11-18
*/

SELECT
    -- Primary Key & Relationships
    id,
    account_id,
    owner_id,
    campaign_id,
    partner_account_c,

    -- Opportunity Identity
    name,

    -- Deal Classification
    deal_type_c,
    opportunity_origin_c,
    primary_use_case_c,

    -- Stage & Status
    stage_name,
    is_closed,
    is_won,
    qualified_opportunity_c,

    -- Financial Metrics
    amount,
    arr_c,
    arr_churn_c,
    new_arr_c,
    arr_expansion_c,
    arr_renewal_c,
    forecasted_renewal_arr_c,
    new_expansion_arr_pipeline_c,
    total_list_price_c,
    total_discount_c,
    contract_term_c,

    -- Dates
    close_date,
    created_date,
    sao_date_c,
    sqo_date_c,
    csm_requested_date_c,

    -- Forecasting
    forecast_category,
    forecast_category_name,

    -- Velocity Metrics
    days_to_close_c,
    days_in_current_stage_c,
    opp_age_c,
    deal_cycle_c,

    -- Lead Source Attribution
    lead_source,
    lead_source_detail_c,
    secondary_lead_source_c,
    latest_lead_source_c,
    latest_lead_source_detail_c,
    latest_reporting_source_c,
    latest_secondary_lead_source_c,

    -- Team & Process
    csm_c,
    sales_engineer_user_c,
    sales_engineer_c,

    -- Deal Details
    lost_opportunity_details_c,
    timeline_c,
    auto_renewal_c,
    po_required_c,

    -- Audit Fields
    created_by_id,

    -- Metadata
    last_synced_at,
    CURRENT_TIMESTAMP() as dbt_updated_at

FROM {{ ref('stg_salesforce__opportunity') }}

-- Test data filtering applied at staging layer (stg_salesforce__opportunity)
-- Staging filters: Hogwarts test opportunities excluded
