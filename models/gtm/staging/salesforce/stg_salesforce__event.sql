{{
    config(
        materialized='table',
        tags=['gtm', 'salesforce', 'staging']
    )
}}

/*
    Staging model for Salesforce Event
    Source: rev_ops_prod.gtm_raw.event (via Fivetran)

    IMPORTANT: This model ONLY includes fields specified in Google Sheets specification
    "SFDC Objects + Fields - Event.csv"

    Field count: 24 fields (as of 2025-11-07)
    Events represent meetings and calendar activities.
*/

with source as (
    select * from {{ source('salesforce', 'event') }}
),

deduplicated as (
    select
        -- Primary Key & Relationships
        id,
        who_id,  -- Lead or Contact ID
        what_id,  -- Related To (Account, Opportunity, etc.)
        account_id,
        owner_id,
        created_by_id,

        -- Event Attributes
        subject,
        type,
        location,
        description,

        -- Event Timing
        start_date_time,
        end_date_time,
        activity_date,
        activity_date_time,
        duration_in_minutes,

        -- Event Flags
        is_all_day_event,
        is_private,
        show_as,

        -- Recurrence Fields
        is_recurrence,
        recurrence_type,
        recurrence_interval,
        recurrence_end_date_only,

        -- Dates
        created_date,
        last_modified_date,

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
