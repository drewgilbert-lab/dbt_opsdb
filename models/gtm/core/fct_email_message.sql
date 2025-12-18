{{
    config(
        materialized='table',
        tags=['gtm', 'core', 'fact']
    )
}}

/*
    Email Message Fact Table

    Purpose: Track email engagement - EXACT MATCH to Google Sheets specification
    Source: stg_salesforce__email_message
    Grain: One row per email message

    IMPORTANT: This model ONLY includes fields from "SFDC Objects + Fields - EmailMessage.csv"
    Field count: 25 fields from Salesforce + minimal metadata

    Google Sheets Specification: /Users/eliakemp/Downloads/SFDC Objects + Fields - EmailMessage.csv
    Last Updated: 2025-11-07
*/

SELECT
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

    -- Metadata
    last_synced_at,
    CURRENT_TIMESTAMP() as dbt_updated_at

FROM {{ ref('stg_salesforce__email_message') }}

-- No additional filtering - all email messages pass through
