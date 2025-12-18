{{
    config(
        materialized='table',
        tags=['gtm', 'salesforce', 'staging', 'adroll']
    )
}}

/*
    Staging model for Salesforce adroll__AdRoll_Account_Field_Mapping__c
    Source: rev_ops_prod.gtm_raw.adroll_ad_roll_account_field_mapping_c (via Fivetran)

    Field count: 13 fields (as of 2025-11-20)
    Specification: SFDC Objects + Fields - RollWorks Account Field Mapping.csv

    Purpose: Configuration table mapping RollWorks customer fields to SFDC account fields.
    This table is currently empty (0 rows) but structure is maintained for future use.

    Transformations:
    - Remove soft deletes (is_deleted = true, _fivetran_deleted = true)
    - Deduplicate by ID (keep most recent _fivetran_synced)
*/

with source as (
    select * from {{ source('salesforce', 'adroll_ad_roll_account_field_mapping_c') }}
),

deduplicated as (
    select
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
