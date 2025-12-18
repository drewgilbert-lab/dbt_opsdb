{{
    config(
        materialized='table',
        tags=['gtm', 'salesforce', 'staging']
    )
}}

/*
    Staging model for Salesforce OpportunityLineItem (Opportunity Products)
    Source: rev_ops_prod.gtm_raw.opportunity_line_item (via Fivetran)

    Field count: 88 fields (as of 2025-11-20)
    Specification: SFDC Objects + Fields - Opportunity Product.csv

    Transformations:
    - Remove soft deletes (is_deleted = true, _fivetran_deleted = true)
    - Deduplicate by ID (keep most recent _fivetran_synced)
*/

with source as (
    select * from {{ source('salesforce', 'opportunity_line_item') }}
),

deduplicated as (
    select
        -- Primary Key
        id,

        -- Foreign Keys
        opportunity_id,
        pricebook_entry_id,
        product_2_id,

        -- Line Item Identity
        name,
        sort_order,
        product_code,
        product_code_c,

        -- Pricing & Quantity
        quantity,
        unit_price,
        list_price,
        discount,
        total_price,

        -- Dates
        service_date,
        created_date,
        last_modified_date,
        last_viewed_date,
        last_referenced_date,

        -- Product Details
        description,
        product_type_c,
        type_c,
        product_status_c,
        product_description_c,

        -- Revenue & ARR
        product_arr_c,
        prior_product_arr_c,
        new_product_arr_c,
        expansion_product_arr_c,
        churn_product_arr_c,
        product_list_price_c,

        -- Dates - Product
        product_start_date_override_c,
        product_end_date_override_c,
        dh_product_start_date_c,
        dh_product_end_date_c,

        -- Scheduling
        has_schedule,
        has_revenue_schedule,
        has_quantity_schedule,
        can_use_quantity_schedule,
        can_use_revenue_schedule,
        recalculate_total_price,

        -- Pricing Flags
        non_standard_pricing_c,
        promotional_pricing_c,
        promotional_pricing_line_description_c,
        recurring_revenue_item_c,

        -- Users & Capacity
        of_users_database_size_c,
        dh_users_c,
        of_reader_licenses_c,

        -- Products & Technology
        of_technology_products_c,
        hg_4_sf_product_c,
        hg_4_sf_includes_discover_companies_c,
        intent_topics_c,

        -- Location & Access
        access_level_c,
        dh_location_type_c,
        dh_number_of_locations_c,
        dh_locations_c,

        -- Partner
        partner_split_c,
        partner_split_amount_c,

        -- NetSuite Integration
        netsuite_conn_discount_item_c,
        netsuite_conn_start_date_c,
        netsuite_conn_end_date_c,
        netsuite_conn_from_contract_item_id_c,
        netsuite_conn_item_category_c,
        netsuite_conn_list_rate_c,
        netsuite_conn_net_suite_item_id_import_c,
        netsuite_conn_net_suite_item_key_id_c,
        netsuite_conn_pushed_from_net_suite_c,
        netsuite_conn_term_contract_pricing_type_c,
        netsuite_conn_terms_c,
        netsuite_conn_user_entered_sales_price_c,

        -- Celigo Integration
        celigo_sfnsio_contract_item_id_c,
        celigo_sfnsio_contract_term_c,
        celigo_sfnsio_end_date_c,
        celigo_sfnsio_list_rate_c,
        celigo_sfnsio_net_suite_line_id_c,
        celigo_sfnsio_start_date_c,
        celigo_sfnsio_item_pricing_type_c,

        -- DealHub Fields
        deal_hub_duration_c,
        deal_hub_quantity_c,
        deal_hub_total_net_price_c,

        -- Other Custom Fields
        account_id_c,
        year_c,
        term_c,
        delete_c,

        -- Audit Fields
        created_by_id,
        last_modified_by_id,
        system_modstamp,

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
