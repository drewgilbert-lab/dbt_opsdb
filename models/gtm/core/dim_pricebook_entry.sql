{{
    config(
        materialized='table',
        tags=['gtm', 'core', 'dimension']
    )
}}

/*
    Pricebook Entry Dimension

    Purpose: Product pricing by pricebook from Salesforce
    Source: stg_salesforce__pricebook_entry
    Grain: One row per pricebook entry (product x pricebook combination)

    Field count: 17 fields from Salesforce
    Specification: SFDC Objects + Fields - Price Book Entry.csv
    Last Updated: 2025-11-20

    Relationships:
    - pricebook_2_id → dim_pricebook.id
    - product_2_id → (future dim_product when added)
*/

SELECT
    -- Primary Key
    id,

    -- Entry Identity
    name,

    -- Foreign Keys
    pricebook_2_id,
    product_2_id,

    -- Pricing
    unit_price,
    use_standard_price,

    -- Product Details
    product_code,

    -- Status
    is_active,
    is_archived,

    -- Audit Fields
    created_date,
    created_by_id,
    last_modified_date,
    last_modified_by_id,
    system_modstamp,

    -- Soft Delete Flag
    is_deleted,

    -- Fivetran Metadata
    _fivetran_deleted,

    -- Metadata
    last_synced_at,
    CURRENT_TIMESTAMP() as dbt_updated_at

FROM {{ ref('stg_salesforce__pricebook_entry') }}
