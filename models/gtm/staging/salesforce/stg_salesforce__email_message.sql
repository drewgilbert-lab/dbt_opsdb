{{
    config(
        materialized='table',
        tags=['gtm', 'salesforce', 'staging']
    )
}}

/*
    Staging model for Salesforce Email Message
    Source: rev_ops_prod.gtm_raw.email_message (via Fivetran)

    IMPORTANT: This model ONLY includes fields specified in Google Sheets specification
    "SFDC Objects + Fields - EmailMessage.csv"

    Field count: 25 fields (as of 2025-11-07)
    Email Message tracks emails with engagement metrics.
*/

with source as (
    select * from {{ source('salesforce', 'email_message') }}
),

deduplicated as (
    select
        -- Primary Key & Relationships
        id,
        related_to_id,
        activity_id,
        created_by_id,

        -- Email Identity
        subject,
        message_identifier,
        thread_identifier,

        -- Email Content
        text_body,
        html_body,
        headers,

        -- Email Addresses
        from_name,
        from_address,
        to_address,
        cc_address,
        bcc_address,

        -- Email Direction
        incoming,

        -- Email Status
        status,

        -- Attachments
        has_attachment,

        -- Engagement Tracking
        is_tracked,
        is_opened,
        is_bounced,
        first_opened_date,
        last_opened_date,

        -- Email Dates
        message_date,
        created_date,

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
