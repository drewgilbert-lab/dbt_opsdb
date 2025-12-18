{{
    config(
        materialized='table',
        tags=['gtm', 'core', 'dimension']
    )
}}

/*
    Forecasting Period Dimension Table

    Purpose: Fiscal period master data for forecasting and quota tracking - EXACT MATCH to Google Sheets specification
    Source: stg_salesforce__period
    Grain: One row per period (month, quarter, year)

    IMPORTANT: This model ONLY includes fields from "SFDC Objects + Fields - Period.csv"
    Field count: 11 fields from Salesforce + minimal metadata

    Google Sheets Specification: /Users/eliakemp/Downloads/SFDC Objects + Fields - Period.csv
    Last Updated: 2025-11-07
*/

SELECT
    -- Primary Key
    id,

    -- Foreign Keys
    fiscal_year_settings_id,

    -- Period Identity
    type,
    quarter_label,
    period_label,
    fully_qualified_label,
    number,

    -- Period Dates
    start_date,
    end_date,

    -- Flags
    is_forecast_period,

    -- Metadata
    last_synced_at,
    CURRENT_TIMESTAMP() as dbt_updated_at

FROM {{ ref('stg_salesforce__period') }}

-- No additional filtering - all periods pass through
