# Contributing to opsDB

**Complete guide for adding and modifying GTM data warehouse models.**

---

## 1. Quick Navigation

**What do you need to do?**

| I want to... | Go to Section |
|--------------|---------------|
| Add a new Salesforce object to the warehouse | [§3 Adding New Objects](#3-adding-new-objects) |
| Add a field to an existing object | [§4 Adding Fields to Existing Objects](#4-adding-fields-to-existing-objects) |
| Understand how data flows from Salesforce | [§2 Data Flow](#2-data-flow) |
| Fix missing or incorrect data | [§5 Troubleshooting](#5-troubleshooting) |
| Learn naming conventions and standards | [§6 Standards & Conventions](#6-standards--conventions) |
| Validate my changes are accurate | [§7 Validation Checklist](#7-validation-checklist) |
| Use Claude Code to automate this | [§8 Instructions for Claude Code](#8-instructions-for-claude-code) |
| Understand Fivetran sync timing | [§9 FAQ](#9-faq) |

---

## 2. Data Flow

### How Data Moves Through opsDB

```
Salesforce (CRM)
    ↓ Fivetran (every 6 hours, automatic)
gtm_raw (exact replica, managed by Fivetran)
    ↓ dbt run (manual, YOU trigger this)
gtm_staging (cleaned, deduplicated)
    ↓ dbt run (same command)
gtm_core (business logic, ready for dashboards)
```

### Key Points

**Automatic (No Action Needed):**
- **Salesforce → gtm_raw**: Fivetran syncs every 6 hours
- **New fields in Salesforce**: Automatically appear in `gtm_raw` within 6 hours
- **New objects in Salesforce**: Automatically appear in `gtm_raw` (if Fivetran configured)

**Manual (You Must Do):**
- **gtm_raw → gtm_staging**: Create staging model (SQL file)
- **gtm_staging → gtm_core**: Create core model (SQL file)
- **Documentation**: Add field descriptions to `schema.yml`
- **Running**: Execute `dbt run` to materialize tables

**Bottom Line:** Fivetran handles Salesforce → gtm_raw. You handle gtm_raw → gtm_core.

---

## 3. Adding New Objects

**When to use this:** A new Salesforce object (e.g., Product, Contract) exists in `gtm_raw` and you need to make it available in `gtm_core`.

### Prerequisites

1. **Verify object exists in gtm_raw:**
   ```sql
   -- In Databricks SQL Editor
   SHOW TABLES IN rev_ops_prod.gtm_raw LIKE '%product%';
   SELECT * FROM rev_ops_prod.gtm_raw.product_2 LIMIT 10;
   ```

2. **Decide: Dimension or Fact?**
   - **Dimension** (use `dim_*`): Person, place, thing (e.g., Account, Contact, Product)
   - **Fact** (use `fct_*`): Event, transaction, measurement (e.g., Opportunity, Task, Invoice)

### Step 1: Create Staging Model

**File:** `models/gtm/staging/salesforce/stg_salesforce__product.sql`

```sql
{{
    config(
        materialized='table',
        tags=['gtm', 'salesforce', 'staging']
    )
}}

/*
    Staging model for Salesforce Product
    Source: rev_ops_prod.gtm_raw.product_2 (via Fivetran)

    Purpose: Clean and standardize product data from Salesforce
    Grain: One row per product
*/

with source as (
    select * from {{ source('salesforce', 'product_2') }}
),

deduplicated as (
    select
        -- Primary Key
        id,

        -- Product Details
        name,
        product_code,
        description,
        family,
        is_active,

        -- Pricing
        list_price_c,

        -- Dates
        created_date,
        last_modified_date,

        -- Fivetran Metadata
        _fivetran_synced as last_synced_at,
        _fivetran_deleted

    from source

    where
        -- Remove soft deletes
        coalesce(is_deleted, false) = false
        and coalesce(_fivetran_deleted, false) = false

        -- Exclude test data (adjust filter as needed)
        and lower(name) not like '%test%'
        and lower(name) not like '%hogwarts%'

    -- Deduplicate by primary key
    qualify row_number() over (
        partition by id
        order by _fivetran_synced desc
    ) = 1
)

select * from deduplicated
```

### Step 2: Add Source Definition

**File:** `models/gtm/staging/salesforce/src_salesforce.yml`

Add the new source table:

```yaml
  - name: product_2
    description: Salesforce Product object
    meta:
      fivetran: true
```

### Step 3: Create Core Model

**For Dimension:**

**File:** `models/gtm/core/dim_product.sql`

```sql
{{
    config(
        materialized='table',
        tags=['gtm', 'core', 'dimension']
    )
}}

/*
    Product Dimension

    Purpose: Product catalog from Salesforce
    Source: stg_salesforce__product
    Grain: One row per product
*/

SELECT
    -- Primary Key
    id,

    -- Product Identity
    name,
    product_code,
    description,
    family,

    -- Status
    is_active,

    -- Pricing
    list_price_c,

    -- Dates
    created_date,
    last_modified_date,

    -- Metadata
    last_synced_at,
    CURRENT_TIMESTAMP() as dbt_updated_at

FROM {{ ref('stg_salesforce__product') }}
```

**For Fact:**

**File:** `models/gtm/core/fct_invoice.sql`

```sql
{{
    config(
        materialized='table',
        tags=['gtm', 'core', 'fact']
    )
}}

/*
    Invoice Fact Table

    Purpose: Invoice transactions from Salesforce
    Source: stg_salesforce__invoice
    Grain: One row per invoice
*/

SELECT
    -- Primary Key
    id,

    -- Foreign Keys (relationships to dimensions)
    account_id,
    opportunity_id,

    -- Invoice Details
    invoice_number,
    invoice_date,
    due_date,
    status,

    -- Metrics
    amount,
    amount_paid,
    amount_outstanding,

    -- Dates
    created_date,
    paid_date,

    -- Metadata
    last_synced_at,
    CURRENT_TIMESTAMP() as dbt_updated_at

FROM {{ ref('stg_salesforce__invoice') }}
```

### Step 4: Document in schema.yml

**File:** `models/gtm/core/schema.yml`

Add documentation for your new model:

```yaml
  - name: dim_product
    description: |
      Product catalog from Salesforce.

      **Grain:** One row per product
      **Source:** Salesforce Product object via stg_salesforce__product

    columns:
      - name: id
        description: Primary key - Salesforce Product ID
        tests:
          - unique
          - not_null

      - name: name
        description: Product name
        tests:
          - not_null

      - name: product_code
        description: Unique product code/SKU

      - name: family
        description: Product family or category

      - name: is_active
        description: Whether product is currently active for sale

      - name: list_price_c
        description: Standard list price in USD
```

### Step 5: Run dbt

```bash
# Run just the new models
dbt run --select stg_salesforce__product dim_product

# Run with dependencies
dbt run --select +dim_product

# Test the new models
dbt test --select dim_product
```

### Step 6: Validate

```sql
-- Check row counts match
SELECT 'gtm_raw' as layer, COUNT(*) as row_count
FROM rev_ops_prod.gtm_raw.product_2
WHERE coalesce(is_deleted, false) = false

UNION ALL

SELECT 'gtm_staging' as layer, COUNT(*) as row_count
FROM rev_ops_prod.gtm_staging.stg_salesforce__product

UNION ALL

SELECT 'gtm_core' as layer, COUNT(*) as row_count
FROM rev_ops_prod.gtm_core.dim_product;

-- Check for duplicates
SELECT id, COUNT(*) as duplicate_count
FROM rev_ops_prod.gtm_core.dim_product
GROUP BY id
HAVING COUNT(*) > 1;

-- Sample data check
SELECT * FROM rev_ops_prod.gtm_core.dim_product LIMIT 10;
```

---

## 4. Adding Fields to Existing Objects

**When to use this:** You added a field to Salesforce (e.g., `Expected_Revenue__c` on Opportunity) and need it in `gtm_core`.

### Prerequisites

1. **Verify field exists in gtm_raw:**
   ```sql
   -- Check field is present (replace 'opportunity' and 'expected_revenue' with your object/field)
   SELECT expected_revenue
   FROM rev_ops_prod.gtm_raw.opportunity
   LIMIT 10;
   ```

2. **Wait for Fivetran:** If field just created in Salesforce, wait up to 6 hours for sync.

### Step 1: Add to Staging Model

**File:** `models/gtm/staging/salesforce/stg_salesforce__opportunity.sql`

Add the field to the `deduplicated` CTE's SELECT statement:

```sql
deduplicated as (
    select
        -- Primary Key & Relationships
        id,
        account_id,
        owner_id,

        -- Financial Metrics
        amount,
        arr_c,
        expected_revenue,  -- ADD THIS LINE

        -- ... rest of fields
```

**Important:** Maintain alphabetical/logical grouping with comments.

### Step 2: Add to Core Model

**File:** `models/gtm/core/fct_opportunity.sql`

Add the field in the same logical section:

```sql
SELECT
    -- Primary Key & Relationships
    id,
    account_id,
    owner_id,

    -- Financial Metrics
    amount,
    arr_c,
    expected_revenue,  -- ADD THIS LINE

    -- ... rest of fields
FROM {{ ref('stg_salesforce__opportunity') }}
```

### Step 3: Document in schema.yml

**File:** `models/gtm/core/schema.yml`

Add field documentation under the appropriate model:

```yaml
  - name: fct_opportunity
    description: Sales opportunities and pipeline data
    columns:
      # ... existing columns

      - name: expected_revenue
        description: Expected revenue amount for the opportunity based on probability
```

### Step 4: Run dbt

```bash
# Run both staging and core for this object
dbt run --select stg_salesforce__opportunity fct_opportunity

# Or run just the models that changed
dbt run --select stg_salesforce__opportunity+
```

### Step 5: Validate

```sql
-- Verify field exists and has data
SELECT
    expected_revenue,
    COUNT(*) as row_count,
    COUNT(expected_revenue) as non_null_count,
    MIN(expected_revenue) as min_value,
    MAX(expected_revenue) as max_value
FROM rev_ops_prod.gtm_core.fct_opportunity
GROUP BY expected_revenue
LIMIT 20;

-- Compare to raw layer
SELECT
    'gtm_raw' as layer,
    COUNT(expected_revenue) as non_null_count
FROM rev_ops_prod.gtm_raw.opportunity

UNION ALL

SELECT
    'gtm_core' as layer,
    COUNT(expected_revenue) as non_null_count
FROM rev_ops_prod.gtm_core.fct_opportunity;
```

---

## 5. Troubleshooting

### Issue: Field exists in Salesforce but not in gtm_raw

**Cause:** Fivetran hasn't synced yet, or field not selected for sync.

**Solution:**
1. Check Fivetran sync status (usually syncs every 6 hours)
2. Verify field is not excluded in Fivetran configuration
3. Wait for next sync cycle
4. Manually trigger Fivetran sync if urgent (via Fivetran UI)

### Issue: Field exists in gtm_raw but not in gtm_core

**Cause:** You need to manually add it to staging and core models.

**Solution:** Follow [§4 Adding Fields](#4-adding-fields-to-existing-objects)

### Issue: Row count mismatch between layers

**Cause:** Filters removing rows (soft deletes, test data, deduplication).

**Solution:**
```sql
-- Debug: Check what filters are removing rows
SELECT
    COUNT(*) as total_rows,
    SUM(CASE WHEN is_deleted THEN 1 ELSE 0 END) as deleted_rows,
    SUM(CASE WHEN lower(name) LIKE '%hogwarts%' THEN 1 ELSE 0 END) as test_rows
FROM rev_ops_prod.gtm_raw.opportunity;
```

**Expected behavior:**
- `gtm_staging` < `gtm_raw` (removes deletes, duplicates, test data)
- `gtm_core` = `gtm_staging` (same row count, just adds business logic)

### Issue: Duplicate records in core table

**Cause:** Deduplication logic missing or incorrect in staging.

**Solution:**
1. Check staging model has `qualify row_number()` clause
2. Verify partitioning by correct primary key
3. Confirm ordering by `_fivetran_synced desc`

```sql
-- Check for duplicates
SELECT id, COUNT(*) as dup_count
FROM rev_ops_prod.gtm_core.fct_opportunity
GROUP BY id
HAVING COUNT(*) > 1;
```

### Issue: Data not refreshing

**Cause:** Haven't run `dbt run` after Fivetran sync.

**Solution:**
```bash
# Refresh all models
dbt run

# Refresh specific model
dbt run --select fct_opportunity

# Force full refresh (drop and recreate)
dbt run --full-refresh
```

---

## 6. Standards & Conventions

### Model Naming

**Staging Models:**
- Pattern: `stg_salesforce__{object_name}`
- Examples: `stg_salesforce__opportunity`, `stg_salesforce__account`
- Location: `models/gtm/staging/salesforce/`

**Core Dimensions:**
- Pattern: `dim_{entity_name}`
- Examples: `dim_account`, `dim_contact`, `dim_product`
- Use for: People, places, things (nouns)
- Location: `models/gtm/core/`

**Core Facts:**
- Pattern: `fct_{event_name}`
- Examples: `fct_opportunity`, `fct_task`, `fct_invoice`
- Use for: Events, transactions, measurements
- Location: `models/gtm/core/`

### Dimension vs Fact Decision Tree

```
Is this object a person, place, or thing that describes WHO/WHAT/WHERE?
├─ YES → Use dim_*
│  Examples: Account, Contact, Product, Campaign, User
│
└─ NO → Is it an event, transaction, or measurement?
   ├─ YES → Use fct_*
   │  Examples: Opportunity, Task, Invoice, Email, Event
   │
   └─ UNSURE → Ask: Does it have metrics/measures?
      ├─ YES → Use fct_*
      └─ NO → Use dim_*
```

### Field Naming

**Primary Keys:**
- Always use: `id` (not `{object}_id` in staging/core)
- Example: `id` (in dim_account, dim_contact, etc.)

**Foreign Keys:**
- Pattern: `{referenced_object}_id`
- Examples: `account_id`, `owner_id`, `campaign_id`
- Must match the primary key name in the referenced dimension

**Field Names:**
- Use `snake_case` (lowercase with underscores)
- Remove Salesforce `__c` suffix (e.g., `arr__c` → `arr_c`)
- Keep field names descriptive and consistent
- Examples: `close_date`, `total_amount`, `is_active`

**Boolean Fields:**
- Prefix with `is_` or `has_`
- Examples: `is_active`, `is_deleted`, `has_products`

**Date Fields:**
- Suffix with `_date` or `_datetime`
- Examples: `created_date`, `last_modified_datetime`, `close_date`

### Required Patterns

**Every Staging Model Must Have:**

1. **Soft delete removal:**
   ```sql
   where
       coalesce(is_deleted, false) = false
       and coalesce(_fivetran_deleted, false) = false
   ```

2. **Deduplication:**
   ```sql
   qualify row_number() over (
       partition by id
       order by _fivetran_synced desc
   ) = 1
   ```

3. **Test data filtering:**
   ```sql
   and lower(name) not like '%hogwarts%'
   and lower(name) not like '%test%'  -- if applicable
   ```

4. **Metadata fields:**
   ```sql
   _fivetran_synced as last_synced_at,
   _fivetran_deleted
   ```

**Every Core Model Must Have:**

1. **dbt_updated_at timestamp:**
   ```sql
   CURRENT_TIMESTAMP() as dbt_updated_at
   ```

2. **Reference upstream staging:**
   ```sql
   FROM {{ ref('stg_salesforce__opportunity') }}
   ```

3. **Documentation in schema.yml:**
   - Model description
   - Grain statement
   - Primary key with tests (unique, not_null)
   - Field descriptions for key columns

### Tags

**Staging models:**
```sql
tags=['gtm', 'salesforce', 'staging']
```

**Core dimensions:**
```sql
tags=['gtm', 'core', 'dimension']
```

**Core facts:**
```sql
tags=['gtm', 'core', 'fact']
```

### Materialization

All models in opsDB use `materialized='table'`:

```sql
{{
    config(
        materialized='table',
        tags=[...]
    )
}}
```

---

## 7. Validation Checklist

Use this checklist after adding/modifying models:

### Pre-Run Checks

- [ ] Field/object exists in `gtm_raw`
- [ ] Staging model created/updated
- [ ] Core model created/updated
- [ ] Documentation added to `schema.yml`
- [ ] Tests added (unique, not_null on primary key)
- [ ] Model follows naming conventions

### Post-Run Validation

**Row Count Validation:**
```sql
-- Compare row counts across layers
SELECT 'gtm_raw' as layer, COUNT(*) as rows
FROM rev_ops_prod.gtm_raw.{object}
WHERE coalesce(is_deleted, false) = false

UNION ALL

SELECT 'gtm_staging' as layer, COUNT(*) as rows
FROM rev_ops_prod.gtm_staging.stg_salesforce__{object}

UNION ALL

SELECT 'gtm_core' as layer, COUNT(*) as rows
FROM rev_ops_prod.gtm_core.{dim_or_fct}_{object};
```

**Duplicate Check:**
```sql
-- Verify no duplicates on primary key
SELECT id, COUNT(*) as duplicate_count
FROM rev_ops_prod.gtm_core.{model_name}
GROUP BY id
HAVING COUNT(*) > 1;
```

**Null Check:**
```sql
-- Check for unexpected nulls
SELECT
    COUNT(*) as total_rows,
    COUNT(id) as non_null_id,
    COUNT({important_field}) as non_null_{field}
FROM rev_ops_prod.gtm_core.{model_name};
```

**Data Sample:**
```sql
-- Visual inspection of data
SELECT *
FROM rev_ops_prod.gtm_core.{model_name}
ORDER BY dbt_updated_at DESC
LIMIT 20;
```

**Field Comparison (for new fields):**
```sql
-- Compare raw vs core for specific field
SELECT
    'gtm_raw' as layer,
    COUNT({field_name}) as non_null_count,
    AVG({field_name}) as avg_value
FROM rev_ops_prod.gtm_raw.{object}

UNION ALL

SELECT
    'gtm_core' as layer,
    COUNT({field_name}) as non_null_count,
    AVG({field_name}) as avg_value
FROM rev_ops_prod.gtm_core.{model_name};
```

### Post-Run Checks

- [ ] Row counts match expectations (staging < raw, core = staging)
- [ ] No duplicate primary keys
- [ ] No unexpected nulls in critical fields
- [ ] Sample data looks correct
- [ ] New fields have data (if expected)
- [ ] dbt tests pass: `dbt test --select {model_name}`
- [ ] Documentation renders correctly: `dbt docs generate`

---

## 8. Instructions for Claude Code

**For your colleague:** Use these templates when asking Claude Code to add objects or fields.

### Template 1: Adding a New Object

```
Claude, I added a new Salesforce object called [OBJECT_NAME].
It's available in gtm_raw.[TABLE_NAME].

Follow CONTRIBUTING.md Section 3 to:
1. Create staging model: stg_salesforce__[object]
2. Create core model: [dim/fct]_[object]
3. Add documentation to schema.yml
4. Run dbt and validate

This object is a [dimension/fact] because [reason].

Key fields to include: [list important fields]
```

**Example:**
```
Claude, I added a new Salesforce object called Product.
It's available in gtm_raw.product_2.

Follow CONTRIBUTING.md Section 3 to:
1. Create staging model: stg_salesforce__product
2. Create core model: dim_product
3. Add documentation to schema.yml
4. Run dbt and validate

This object is a dimension because it represents products in our catalog.

Key fields to include: id, name, product_code, family, is_active, list_price_c
```

### Template 2: Adding a Field

```
Claude, I added a new field called [FIELD_NAME] to the [OBJECT] object in Salesforce.

It's available in gtm_raw.[table_name] as [field_name].

Follow CONTRIBUTING.md Section 4 to:
1. Add to stg_salesforce__[object]
2. Add to [dim/fct]_[object]
3. Document in schema.yml
4. Run dbt and validate

Field description: [what this field represents]
```

**Example:**
```
Claude, I added a new field called Expected_Revenue__c to the Opportunity object in Salesforce.

It's available in gtm_raw.opportunity as expected_revenue.

Follow CONTRIBUTING.md Section 4 to:
1. Add to stg_salesforce__opportunity
2. Add to fct_opportunity
3. Document in schema.yml
4. Run dbt and validate

Field description: Expected revenue based on opportunity amount × probability
```

### Template 3: Troubleshooting

```
Claude, I'm having an issue with [describe issue].

Check CONTRIBUTING.md Section 5 for troubleshooting steps.

Details:
- Object/Field: [name]
- Layer where issue occurs: [gtm_raw/gtm_staging/gtm_core]
- Error message (if any): [error]
```

---

## 9. FAQ

### Q: How often does Fivetran sync Salesforce data?

**A:** Every 6 hours. Fivetran automatically detects changes in Salesforce and syncs them to `gtm_raw`.

### Q: Do I need to configure Fivetran when I add a field in Salesforce?

**A:** No. Fivetran automatically detects new fields and adds them to the corresponding table in `gtm_raw`. You only need to manually add them to your staging and core models.

### Q: How do I know if a field has synced from Salesforce to gtm_raw?

**A:** Query the raw table:
```sql
SELECT [field_name]
FROM rev_ops_prod.gtm_raw.[object_name]
LIMIT 10;
```

If the field doesn't exist, wait for the next Fivetran sync (up to 6 hours) or check Fivetran UI for sync status.

### Q: Why isn't my new field showing up in dashboards?

**A:** New fields require manual steps:
1. Field must exist in `gtm_raw` (automatic via Fivetran)
2. Field must be added to staging model (manual - you do this)
3. Field must be added to core model (manual - you do this)
4. Run `dbt run` to materialize changes (manual - you do this)

If you only added the field in Salesforce, it's only in `gtm_raw`. Follow [§4 Adding Fields](#4-adding-fields-to-existing-objects).

### Q: Can I add fields that don't exist in Salesforce?

**A:** Yes, but only in the core layer. You can create calculated fields, derived metrics, or business logic fields in `gtm_core` models. These are computed from existing Salesforce fields.

Example:
```sql
-- In fct_opportunity core model
CASE
    WHEN is_won THEN 'Won'
    WHEN is_closed THEN 'Lost'
    ELSE 'Open'
END as opportunity_status
```

### Q: What if I need to add a field from a different source (not Salesforce)?

**A:** Future: When we add HubSpot, Marketo, or other sources, you'll create source-specific staging models (e.g., `stg_hubspot__contact`) and then UNION them in the core layer. Current implementation only supports Salesforce.

### Q: How do I remove a field or object?

**A:**
1. Remove from core model SQL
2. Remove from staging model SQL
3. Remove documentation from `schema.yml`
4. Run `dbt run --full-refresh` to recreate tables

**Note:** Removing from models doesn't delete from `gtm_raw` (Fivetran manages that layer).

### Q: Do staging and core need to have the same fields?

**A:** No. Staging should include ALL useful fields from the source. Core can be selective - only include fields needed for analytics. However, in practice, we tend to keep them similar for simplicity.

### Q: What's the difference between `is_deleted` and `_fivetran_deleted`?

**A:**
- `is_deleted`: Salesforce soft delete flag (record marked as deleted in SFDC)
- `_fivetran_deleted`: Fivetran hard delete flag (record was permanently deleted from SFDC)

Both should be filtered out in staging:
```sql
where
    coalesce(is_deleted, false) = false
    and coalesce(_fivetran_deleted, false) = false
```

---

## Summary

**Quick Reference Card:**

| Task | Files to Edit | Command to Run |
|------|---------------|----------------|
| Add new object | staging SQL + core SQL + schema.yml + src_salesforce.yml | `dbt run --select +{model}` |
| Add field | staging SQL + core SQL + schema.yml | `dbt run --select {staging}+ {core}+` |
| Validate changes | None (just query) | See §7 validation queries |
| Troubleshoot | Check §5 | Depends on issue |

**Key Principles:**
1. Fivetran handles Salesforce → gtm_raw (automatic)
2. You handle gtm_raw → gtm_core (manual)
3. Always deduplicate, filter deletes, remove test data
4. Document everything in schema.yml
5. Validate before considering done

**For More Information:**
- Setup: See [SETUP.md](SETUP.md)
- Architecture: See [ARCHITECTURE.md](ARCHITECTURE.md)
- Schemas: See [docs/SCHEMA_REFERENCE.md](docs/SCHEMA_REFERENCE.md)

---

**Last Updated:** 2025-12-02
**Maintained By:** Development Operations team
