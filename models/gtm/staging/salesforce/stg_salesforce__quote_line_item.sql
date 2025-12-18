{{
    config(
        materialized='table',
        tags=['gtm', 'salesforce', 'staging']
    )
}}

/*
    Staging model for Salesforce QuoteLineItem (Quote Line Items)
    Source: rev_ops_prod.gtm_raw.quote_line_item (via Fivetran)

    Field count: 36 fields (as of 2025-11-20)
    Specification: SFDC Objects + Fields - Quote Line Item.csv

    Note: This table is currently empty (0 rows) but structure is maintained
    for future data.

    Transformations:
    - Remove soft deletes (is_deleted = true, _fivetran_deleted = true)
    - Deduplicate by ID (keep most recent _fivetran_synced)
*/

with source as (
    select * from {{ source('salesforce', 'quote_line_item') }}
),

deduplicated as (
    select
        -- Primary Key
        id,

        -- Foreign Keys
        quote_id,
        pricebook_entry_id,
        opportunity_line_item_id,
        product_2_id,

        -- Line Item Identity
        line_number,
        sort_order,

        -- Description
        description,

        -- Pricing & Quantity
        quantity,
        unit_price,
        list_price,
        discount,
        subtotal,
        total_price,

        -- Date
        service_date,

        -- Scheduling
        has_schedule,
        has_revenue_schedule,
        has_quantity_schedule,

        -- NetSuite Integration
        netsuite_conn_discount_item_c,
        netsuite_conn_net_suite_item_id_import_c,
        netsuite_conn_net_suite_item_key_id_c,
        netsuite_conn_pushed_from_net_suite_c,

        -- DealHub Fields
        dealhub_quantity_c,
        dealhub_duration_c,

        -- Custom Fields
        item_net_price_c,
        arr_c,

        -- Audit Fields
        created_date,
        created_by_id,
        last_modified_date,
        last_modified_by_id,
        system_modstamp,
        last_viewed_date,
        last_referenced_date,

        -- Soft Delete Flag (for reference)
        is_deleted,

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
