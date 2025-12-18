{{
    config(
        materialized='table',
        tags=['gtm', 'core', 'fact']
    )
}}

/*
    Forecasting Item Fact Table

    Purpose: Track aggregate forecast submissions - EXACT MATCH to Google Sheets specification
    Source: stg_salesforce__forecasting_item
    Grain: One row per forecasting item (aggregate forecast)

    IMPORTANT: This model ONLY includes fields from "SFDC Objects + Fields - ForecastingItem.csv"
    Field count: 20 fields from Salesforce + minimal metadata
    Note: StartDate and EndDate were in CSV but don't exist in database - removed

    Google Sheets Specification: /Users/eliakemp/Downloads/SFDC Objects + Fields - ForecastingItem.csv
    Last Updated: 2025-11-07
*/

SELECT
    -- Primary Key & Owner
    id,
    owner_id,

    -- Forecast Amounts
    forecast_amount,
    owner_only_amount,
    amount_without_adjustments,
    amount_without_manager_adjustment,

    -- Forecast Categories
    forecast_category_name,
    forecasting_item_category,

    -- Period Information
    -- start_date and end_date not in database
    period_id,

    -- Product
    product_family,

    -- Forecast Quantities
    forecast_quantity,
    owner_only_quantity,
    quantity_without_adjustments,
    quantity_without_manager_adjustment,

    -- Flags
    has_adjustment,
    has_owner_adjustment,
    is_amount,
    is_quantity,

    -- Forecasting Type
    forecasting_type_id,

    -- Metadata
    last_synced_at,
    CURRENT_TIMESTAMP() as dbt_updated_at

FROM {{ ref('stg_salesforce__forecasting_item') }}

-- No additional filtering - all forecasting items pass through
