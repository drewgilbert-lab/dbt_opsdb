{{
    config(
        materialized='table',
        tags=['gtm', 'salesforce', 'staging']
    )
}}

/*
    Staging model for Salesforce OpportunityContactRole
    Source: rev_ops_prod.gtm_raw.opportunity_contact_role (via Fivetran)

    Purpose: Link contacts to opportunities with roles
    Used for indirect activity attribution (task.who_id → contact → opportunity)

    This enables us to count activities where:
    - Task is logged on a contact (who_id)
    - That contact is associated with an opportunity
    - Captures 73% of activities that don't have direct what_id link
*/

with source as (
    select * from {{ source('salesforce', 'opportunity_contact_role') }}
),

deduplicated as (
    select
        -- Primary Key
        id as opportunity_contact_role_id,

        -- Foreign Keys
        opportunity_id,
        contact_id,

        -- Role Attributes
        role,
        is_primary,

        -- Dates
        created_date as role_created_date,

        -- Fivetran Metadata
        _fivetran_synced as last_synced_at,
        _fivetran_deleted

    from source

    where
        -- Remove soft deletes
        coalesce(is_deleted, false) = false
        and coalesce(_fivetran_deleted, false) = false

    -- Deduplicate: Take most recent version
    qualify row_number() over (
        partition by id
        order by _fivetran_synced desc
    ) = 1
)

select * from deduplicated
