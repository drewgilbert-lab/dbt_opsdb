{{
    config(
        materialized='table',
        tags=['gtm', 'salesforce', 'staging']
    )
}}

/*
    Staging model for Salesforce ForecastingItem
    Source: rev_ops_prod.gtm_raw.forecasting_item (via Fivetran)

    IMPORTANT: This model ONLY includes fields specified in Google Sheets specification
    "SFDC Objects + Fields - ForecastingItem.csv"

    Field count: 20 fields (as of 2025-11-07)
    Note: StartDate and EndDate are in CSV but don't exist in database - removed
    ForecastingItem contains forecast submissions by period and category.
*/

with source as (
    select * from {{ source('salesforce', 'forecasting_item') }}
),

deduplicated as (
    select
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
        -- start_date and end_date don't exist in database (in CSV but not synced by Fivetran)
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

        -- Fivetran Metadata
        _fivetran_synced as last_synced_at,
        _fivetran_deleted

    from source

    where
        coalesce(_fivetran_deleted, false) = false

    -- Deduplicate
    qualify row_number() over (
        partition by id
        order by _fivetran_synced desc
    ) = 1
)

select * from deduplicated
