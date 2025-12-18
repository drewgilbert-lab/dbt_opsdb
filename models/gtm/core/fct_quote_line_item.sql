{{
    config(
        materialized='table',
        tags=['gtm', 'core', 'fact']
    )
}}

/*
    Quote Line Item Fact Table

    Purpose: Products on quotes
    Source: stg_salesforce__quote_line_item
    Grain: One row per quote line item

    Field count: 36 fields from Salesforce
    Specification: SFDC Objects + Fields - Quote Line Item.csv

    Note: This table is currently empty (0 rows) but structure is maintained
    for future data.

    Relationships:
    - quote_id → (future dim_quote when added)
    - pricebook_entry_id → dim_pricebook_entry.id
    - opportunity_line_item_id → fct_opportunity_line_item.id
    - product_2_id → (future dim_product when added)
*/

SELECT
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

    -- Soft Delete Flag
    is_deleted,

    -- Fivetran Metadata
    _fivetran_deleted,

    -- Metadata
    last_synced_at,
    CURRENT_TIMESTAMP() as dbt_updated_at

FROM {{ ref('stg_salesforce__quote_line_item') }}
