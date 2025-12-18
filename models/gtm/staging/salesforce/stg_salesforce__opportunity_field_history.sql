{{
    config(
        materialized='table',
        tags=['gtm', 'salesforce', 'staging']
    )
}}

/*
    Staging model for Salesforce OpportunityFieldHistory
    Source: rev_ops_prod.gtm_raw.opportunity_field_history (via Fivetran)

    Purpose: Tracks all field changes on opportunities over time

    Phase 3: Stage History Models
    - Filters to StageName changes only (for stage velocity analysis)
    - Tracks 124,250 field history records across 14,751 opportunities
    - Enables temporal joins (e.g., what stage was opp in when email sent?)
*/

with source as (
    select * from {{ source('salesforce', 'opportunity_field_history') }}
),

stage_changes_only as (
    select
        -- Primary Key
        id as field_history_id,

        -- Foreign Keys
        opportunity_id,
        created_by_id as changed_by_user_id,

        -- Change Details
        field,
        old_value as previous_value,
        new_value as new_value,
        created_date as change_date,

        -- Fivetran Metadata
        _fivetran_synced as last_synced_at,
        _fivetran_deleted

    from source

    where
        -- Only track StageName changes
        field = 'StageName'

        -- Remove soft deletes
        and coalesce(is_deleted, false) = false
        and coalesce(_fivetran_deleted, false) = false

    -- Deduplicate (should not be needed, but safety)
    qualify row_number() over (
        partition by id
        order by _fivetran_synced desc
    ) = 1
)

select * from stage_changes_only
