{{
    config(
        materialized='table',
        tags=['gtm', 'salesforce', 'staging']
    )
}}

/*
    Staging model for Salesforce Period
    Source: rev_ops_prod.gtm_raw.period (via Fivetran)

    IMPORTANT: This model ONLY includes fields specified in Google Sheets specification
    "SFDC Objects + Fields - Period.csv"

    Field count: 11 fields (as of 2025-11-07)
    Period defines fiscal periods (months, quarters, years) used in forecasting.
*/

with source as (
    select * from {{ source('salesforce', 'period') }}
),

deduplicated as (
    select
        -- Primary Keys & Relationships
        id,
        fiscal_year_settings_id,

        -- Period Identity
        type,  -- Month, Quarter, Year
        quarter_label,
        period_label,
        fully_qualified_label,
        number,

        -- Period Dates
        start_date,
        end_date,

        -- Flags
        is_forecast_period,

        -- Fivetran Metadata
        _fivetran_synced as last_synced_at,
        _fivetran_deleted

    from source

    where
        -- No soft delete on Period table, just filter out Fivetran deletes
        coalesce(_fivetran_deleted, false) = false

    -- Deduplicate
    qualify row_number() over (
        partition by id
        order by _fivetran_synced desc
    ) = 1
)

select * from deduplicated
