{{
    config(
        materialized='table',
        tags=['gtm', 'core', 'fact', 'adroll', 'config']
    )
}}

/*
    RollWorks Account Field Mapping Configuration Table

    Purpose: Configuration mapping RollWorks fields to Salesforce account fields
    Source: stg_salesforce__adroll_ad_roll_account_field_mapping_c
    Grain: One row per field mapping configuration

    Field count: 13 fields from Salesforce
    Specification: SFDC Objects + Fields - RollWorks Account Field Mapping.csv

    Note: This table is currently empty (0 rows) but structure is maintained
    for future field mapping configurations.

    Use Cases:
    - Field mapping configuration for RollWorks integration
    - Documentation of custom field mappings
    - Integration setup reference
*/

SELECT
    -- Primary Key
    id,

    -- Record Identity
    name,
    owner_id,

    -- Field Mapping Configuration
    adroll_roll_works_customer_field_c,
    adroll_sfdc_account_field_c,

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

FROM {{ ref('stg_salesforce__adroll_ad_roll_account_field_mapping_c') }}
