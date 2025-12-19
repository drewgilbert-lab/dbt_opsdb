{{
    config(
        materialized='table',
        tags=['gtm', 'core', 'fact']
    )
}}

/*
    Email Message Fact Table

    Purpose: Track email engagement
    Source: stg_salesforce__email_message
    Grain: One row per email message

    Field count: 39 fields from Salesforce + minimal metadata
    Last Updated: 2025-12-18
*/

SELECT
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

    -- Metadata
    last_synced_at,
    CURRENT_TIMESTAMP() as dbt_updated_at

FROM {{ ref('stg_salesforce__email_message') }}

-- No additional filtering - all email messages pass through
