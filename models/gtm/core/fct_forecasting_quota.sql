{{
    config(
        materialized='table',
        tags=['gtm', 'core', 'fact']
    )
}}

/*
    Forecasting Quota Fact Table

    Purpose: Track sales quotas - EXACT MATCH to Google Sheets specification
    Source: stg_salesforce__forecasting_quota
    Grain: One row per quota assignment

    IMPORTANT: This model ONLY includes fields from "SFDC Objects + Fields - ForecastingQuota.csv"
    Field count: 16 fields from Salesforce + minimal metadata

    Google Sheets Specification: /Users/eliakemp/Downloads/SFDC Objects + Fields - ForecastingQuota.csv
    Last Updated: 2025-11-07
*/

SELECT
    -- Primary Key & Relationships
    id,
    quota_owner_id,
    period_id,
    forecasting_type_id,

    -- Quota Amounts
    quota_amount,
    quota_quantity,

    -- Dates
    start_date,
    -- end_date not in database

    -- Product
    product_family,

    -- Flags
    is_amount,
    is_quantity,

    -- Audit Fields
    created_date,
    created_by_id,
    last_modified_date,
    last_modified_by_id,

    -- Metadata
    last_synced_at,
    CURRENT_TIMESTAMP() as dbt_updated_at

FROM {{ ref('stg_salesforce__forecasting_quota') }}

-- No additional filtering - all quotas pass through
