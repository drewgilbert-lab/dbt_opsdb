{{
    config(
        materialized='table',
        tags=['gtm', 'salesforce', 'staging']
    )
}}

/*
    Staging model for Salesforce Email Message
    Source: rev_ops_prod.gtm_raw.email_message (via Fivetran)

    Field count: 39 fields (as of 2025-12-18)
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
        from_id,
        parent_id,
        reply_to_email_message_id,

        -- Email Identity
        name,
        subject,
        message_identifier,
        thread_identifier,
        client_thread_identifier,

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

        -- Email Classification
        automation_type,
        is_client_managed,
        is_externally_visible,
        source,

        -- Attachments
        has_attachment,
        attachment_ids,

        -- Engagement Tracking
        is_tracked,
        is_opened,
        is_bounced,
        first_opened_date,
        last_opened_date,

        -- Weflow Tracking
        weflow_tracking_weflow_last_open_date_c,
        weflow_tracking_weflow_open_count_c,

        -- Email Dates
        message_date,
        created_date,

        -- Audit Fields
        last_modified_by_id,
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
