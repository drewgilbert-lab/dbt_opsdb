{{
    config(
        materialized='table',
        tags=['gtm', 'salesforce', 'staging']
    )
}}

/*
    Staging model for Salesforce User
    Source: rev_ops_prod.gtm_raw.user (via Fivetran)

    IMPORTANT: This model ONLY includes fields specified in Google Sheets specification
    "SFDC Objects + Fields - User.csv"

    Field count: 15 fields (as of 2025-11-07)
    Users represent employees and Salesforce org members for owner resolution.
*/

with source as (
    select * from {{ source('salesforce', 'user') }}
),

deduplicated as (
    select
        -- Primary Key
        id,

        -- User Identity
        name,

        -- User Status
        is_active,

        -- Relationships
        manager_id,
        user_role_id,
        contact_id,
        profile_id,

        -- User Organization
        role_name_c,
        department,
        title,

        -- Contact Info
        sender_email,
        city,
        state,
        time_zone_sid_key,

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
