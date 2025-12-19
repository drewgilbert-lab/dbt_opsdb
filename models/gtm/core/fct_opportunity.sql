{{
    config(
        materialized='table',
        tags=['gtm', 'core', 'fact']
    )
}}

/*
    Opportunity Fact Table

    Purpose: Core opportunity metrics
    Source: stg_salesforce__opportunity
    Grain: One row per opportunity

    Field count: 114 fields from Salesforce + minimal metadata
    Last Updated: 2025-12-18
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
    type,

    -- Deal Classification
    deal_type_c,
    opportunity_origin_c,
    primary_use_case_c,
    additional_use_cases_c,
    primary_use_case_implemented_c,

    -- MEDDPICC/Sales Methodology
    authority_c,
    budget_c,
    budget_approval_c,
    budget_holder_c,
    champion_c,
    compelling_event_c,
    decision_criteria_c,
    decision_maker_c,
    decision_process_c,
    economic_buyer_c,

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
    arr_renewal_closed_lost_c,
    arr_renewal_closed_won_c,
    arr_renewal_pipeline_c,
    expansion_arr_c,
    new_expansion_arr_c,
    prev_contract_arr_c,

    -- Dates
    close_date,
    created_date,
    sao_date_c,
    sqo_date_c,
    csm_requested_date_c,
    idate_c,

    -- Contract & Terms
    contract_end_or_opt_out_date_c,
    contract_last_sent_date_c,
    contract_sent_c,
    contract_start_date_c,
    term_months_c,
    termination_date_c,
    special_terms_c,

    -- Deal/Quote Management
    approved_proposal_c,
    deal_desk_notes_c,
    deal_hub_create_subscription_c,
    deal_hub_quote_id_c,
    dealroom_created_c,
    dealroom_status_c,
    purchase_order_c,
    quote_created_c,

    -- Trial
    trial_contact_role_rollup_c,
    trial_end_date_c,
    trial_request_date_c,
    trial_start_date_c,

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
    sdr_c,
    sdr_that_sourced_opp_c,
    client_advisor_review_c,
    client_advisory_request_date_c,
    sales_engineer_notes_c,

    -- Competitor/Market
    competitors_c,
    who_else_are_they_considering_c,
    tech_stack_c,

    -- Customer/ICP
    customer_reference_c,
    desired_outcome_for_client_c,
    ideal_customer_profile_c,
    full_access_platform_seat_holder_c,
    size_the_problem_c,
    secondary_business_challenge_c,

    -- Deal Details
    lost_opportunity_details_c,
    timeline_c,
    auto_renewal_c,
    po_required_c,

    -- Process/Status
    checklist_complete_c,
    engaged_procurement_c,
    risk_category_c,
    signer_c,
    next_step,
    next_steps_history_c,

    -- AI/Analytics
    four_four_ai_c,
    vitally_opportunity_pulse_c,
    vitally_opportunity_pulse_notes_c,

    -- Audit Fields
    created_by_id,

    -- Metadata
    last_synced_at,
    CURRENT_TIMESTAMP() as dbt_updated_at

FROM {{ ref('stg_salesforce__opportunity') }}

-- Test data filtering applied at staging layer (stg_salesforce__opportunity)
-- Staging filters: Hogwarts test opportunities excluded
