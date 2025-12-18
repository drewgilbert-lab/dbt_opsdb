{{
    config(
        materialized='table',
        tags=['gtm', 'salesforce', 'staging']
    )
}}

/*
    Staging model for Salesforce ForecastingQuota
    Source: rev_ops_prod.gtm_raw.forecasting_quota (via Fivetran)

    IMPORTANT: This model ONLY includes fields specified in Google Sheets specification
    "SFDC Objects + Fields - ForecastingQuota.csv"

    Field count: 15 fields (as of 2025-11-07)
    Note: EndDate is in CSV but doesn't exist in database - removed
    ForecastingQuota defines sales quotas for reps by period and product family.
*/

with source as (
    select * from {{ source('salesforce', 'forecasting_quota') }}
),

deduplicated as (
    select
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
        -- end_date doesn't exist in database (in CSV but not synced by Fivetran)

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
