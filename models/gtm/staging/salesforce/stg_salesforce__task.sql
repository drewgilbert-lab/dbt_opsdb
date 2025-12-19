{{
    config(
        materialized='table',
        tags=['gtm', 'salesforce', 'staging']
    )
}}

/*
    Staging model for Salesforce Task
    Source: rev_ops_prod.gtm_raw.task (via Fivetran)

    Field count: 82 fields (as of 2025-12-18)
    Note: Created_By_Weeks_in_the_Business__c is in CSV but doesn't exist in database - removed
    Tasks track sales activities including calls, emails, and meetings.
*/

with source as (
    select * from {{ source('salesforce', 'task') }}
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

        -- Task Attributes
        subject,
        type,
        status,
        priority,
        is_high_priority,
        is_closed,
        description,

        -- Record Structure
        child_record_c,
        is_recurrence,

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
        call_recording_url_2_c,

        -- Meeting Fields
        meeting_type_c,
        meeting_date_c,
        meeting_outcome_c,
        meeting_outcome_reason_c,
        meeting_source_c,
        meeting_cancelled_c,
        is_no_show_c,
        next_actions_c,
        meeting_booked_source_c,
        meeting_conversion_status_c_c,

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

        -- Sequence Fields (Outreach/Salesloft)
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

        -- Weflow Integration
        weflow_weflow_calendar_event_data_c,
        weflow_weflow_calendar_event_id_c,
        weflow_weflow_calendar_original_event_id_c,
        weflow_weflow_email_message_id_c,
        weflow_weflow_email_original_message_id_c,
        weflow_weflow_task_email_last_open_date_c,
        weflow_weflow_task_email_open_count_c,

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
        -- created_by_weeks_in_the_business_c doesn't exist in database (in CSV but not synced by Fivetran)

        -- Related Objects
        related_campaign_c,
        related_product_c,
        lead_matched_account_c,

        -- Task Type Name
        task_type_name_c,

        -- Activity Fields
        activity_c,
        activity_id_full_c,

        -- Automation/Renewal
        automated_renewal_notification_c,

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
