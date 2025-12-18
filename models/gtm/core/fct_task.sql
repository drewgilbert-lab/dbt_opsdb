{{
    config(
        materialized='table',
        tags=['gtm', 'core', 'fact']
    )
}}

/*
    Task Fact Table

    Purpose: Track sales activities - EXACT MATCH to Google Sheets specification
    Source: stg_salesforce__task
    Grain: One row per task

    IMPORTANT: This model ONLY includes fields from "SFDC Objects + Fields - Task.csv"
    Field count: 67 fields from Salesforce + minimal metadata
    Note: Created_By_Weeks_in_the_Business__c was in CSV but doesn't exist in database - removed

    Google Sheets Specification: /Users/eliakemp/Downloads/SFDC Objects + Fields - Task.csv
    Last Updated: 2025-11-07
*/

SELECT
    -- Primary Key & Relationships
    id,
    who_id,
    what_id,
    account_id,
    owner_id,
    created_by_id,

    -- Task Attributes
    subject,
    type,
    status,
    priority,
    is_high_priority,
    is_closed,
    description,

    -- Task Dates
    activity_date,
    created_date,
    last_modified_date,
    completed_date_time,

    -- Call Fields
    call_type,
    call_duration_in_seconds,
    call_disposition,
    call_object,
    call_outcome_c,
    call_to_action_buttons_c,
    call_notes_c,
    call_answered_c,
    call_started_c,
    stage_of_call_reached_c,

    -- Meeting Fields
    meeting_type_c,
    meeting_date_c,
    meeting_outcome_c,
    meeting_outcome_reason_c,
    meeting_source_c,
    meeting_cancelled_c,
    is_no_show_c,
    next_actions_c,

    -- Prospect Fields
    prospect_persona_new_c,
    prospect_seniority_c,
    prospect_region_c,

    -- SDR Quota Fields
    sdr_quota_credit_c,
    sdr_quota_credit_details_c,
    iqm_date_c,

    -- Booker Fields
    booker_c,
    booked_by_me_c,
    booker_role_c,

    -- Sequence Fields
    sequence_name_c,
    sequence_step_number_c,
    outreach_attributed_sequence_name_c,

    -- Email Fields
    email_template_name_c,
    email_recipients_c,
    open_count_c,
    open_time_c,
    click_count_c,
    replied_at_c,
    bounced_at_c,
    bounced_reason_c,

    -- Task Timing Fields
    date_task_started_c,
    date_task_completed_c,

    -- Assignee Fields
    assigned_to_me_c,
    assigned_to_role_c,
    assignee_active_c,
    assignee_weeks_in_business_c,

    -- Creator Fields
    created_by_me_c,
    created_by_role_c,
    -- created_by_weeks_in_the_business_c removed (doesn't exist in database)

    -- Related Objects
    related_campaign_c,
    related_product_c,
    lead_matched_account_c,

    -- Task Type Name
    task_type_name_c,

    -- Metadata
    last_synced_at,
    CURRENT_TIMESTAMP() as dbt_updated_at

FROM {{ ref('stg_salesforce__task') }}

-- No additional filtering - all tasks pass through
