{{
    config(
        materialized='table',
        tags=['gtm', 'core', 'dimension']
    )
}}

/*
    Pricebook Dimension

    Purpose: Pricebook master data from Salesforce
    Source: stg_salesforce__pricebook_2
    Grain: One row per pricebook

    Field count: 16 fields from Salesforce
    Specification: SFDC Objects + Fields - Price Book.csv
    Last Updated: 2025-11-20
*/

SELECT
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

    -- Soft Delete Flag
    is_deleted,

    -- Fivetran Metadata
    _fivetran_deleted,

    -- Metadata
    last_synced_at,
    CURRENT_TIMESTAMP() as dbt_updated_at

FROM {{ ref('stg_salesforce__pricebook_2') }}
