{{
    config(
        materialized='table',
        tags=['gtm', 'salesforce', 'staging']
    )
}}

/*
    Staging model for Salesforce Pricebook2 (Price Book)
    Source: rev_ops_prod.gtm_raw.pricebook_2 (via Fivetran)

    Field count: 16 fields (as of 2025-11-20)
    Specification: SFDC Objects + Fields - Price Book.csv

    Transformations:
    - Remove soft deletes (is_deleted = true, _fivetran_deleted = true)
    - Deduplicate by ID (keep most recent _fivetran_synced)
*/

with source as (
    select * from {{ source('salesforce', 'pricebook_2') }}
),

deduplicated as (
    select
        -- Primary Key
        id,

        -- Pricebook Identity
        name,
        description,

        -- Status & Classification
        is_active,
        is_standard,
        is_archived,

        -- Audit Fields
        created_date,
        created_by_id,
        last_modified_date,
        last_modified_by_id,
        system_modstamp,
        last_viewed_date,
        last_referenced_date,

        -- Soft Delete Flag (for reference)
        is_deleted,

        -- Fivetran Metadata
        _fivetran_synced as last_synced_at,
        _fivetran_deleted

    from source

    where
        -- Remove soft deletes
        coalesce(is_deleted, false) = false
        and coalesce(_fivetran_deleted, false) = false

    -- Deduplicate
    qualify row_number() over (
        partition by id
        order by _fivetran_synced desc
    ) = 1
)

select * from deduplicated
