# opsDB - Operations Database & GTM Data Warehouse

**Independent dbt project for Salesforce GTM data transformations in Databricks**

## Documentation Navigation

| Task | Document |
|------|----------|
| **Getting started / Setup** | [SETUP.md](SETUP.md) |
| **Understand architecture** | [ARCHITECTURE.md](ARCHITECTURE.md) |
| **Add new objects/fields** | [CONTRIBUTING.md](CONTRIBUTING.md) |
| **Query tables / See schemas** | [docs/SCHEMA_REFERENCE.md](docs/SCHEMA_REFERENCE.md) |

---

## Overview

opsDB is a self-contained data transformation project that processes GTM data in Databricks. This repository is fully independent with zero external dependencies, enabling anyone to clone, modify, and deploy transformations.

### What's Inside

- **48 SQL models** transforming Salesforce data through staging → core layers
- **25 Salesforce objects** (Opportunity, Account, Contact, Lead, Campaign, Products, RollWorks, etc.)
- **Complete documentation** with field definitions and ERD diagrams
- **dbt configurations** for Databricks Unity Catalog
- **Verified accuracy** - all models tested against production Databricks

## Architecture

```
Fivetran → gtm_raw → gtm_staging → gtm_core → gtm_mart (future)
            (Salesforce)   (Clean)      (Business Logic)  (Analytics)
```

### Data Layers

1. **Raw Layer** (`gtm_raw`) - Fivetran-managed Salesforce tables
2. **Staging Layer** (`gtm_staging`) - Cleaned, deduplicated, standardized
3. **Core Layer** (`gtm_core`) - Business logic with dimensions and facts
4. **Mart Layer** (`gtm_mart`) - Future analytics layer (placeholder)

### Models

**Dimensions (8):**
- `dim_user` - Salesforce users and owners
- `dim_account` - Customer accounts
- `dim_contact` - Contact information
- `dim_lead` - Lead records
- `dim_campaign` - Marketing campaigns
- `dim_forecasting_period` - Forecasting periods
- `dim_pricebook` - Product price books
- `dim_pricebook_entry` - Product pricing by price book

**Facts (15):**
- `fct_opportunity` - Sales opportunities (deals, ARR metrics)
- `fct_opportunity_line_item` - Products on opportunities (88 fields)
- `fct_quote_line_item` - Products on quotes
- `fct_task` - Sales activities
- `fct_event` - Calendar events and meetings
- `fct_email_message` - Email communications
- `fct_campaign_member` - Campaign membership
- `fct_campaign_influence` - Campaign attribution
- `fct_forecasting_quota` - Sales quotas
- `fct_forecasting_item` - Forecast items
- `fct_adroll_user_summary` - RollWorks user-level advertising metrics
- `fct_adroll_account_summary` - RollWorks account-level ABM metrics
- `fct_adroll_tracking_data` - Daily RollWorks tracking data
- `fct_adroll_tracking_aggregation` - Aggregated RollWorks metrics
- `fct_adroll_field_mapping` - RollWorks field mapping config

## Quick Start

### Setup Steps

```bash
# 1. Install
pip install -r requirements.txt && dbt deps

# 2. Configure
cp profiles.yml.template ~/.dbt/profiles.yml
# Edit ~/.dbt/profiles.yml with your details

# 3. Authenticate
databricks auth login --host https://hginsights-rev-ops-prod.cloud.databricks.com

# 4. Run
dbt run
```

**Done!** You now have 48 analytics-ready tables in Databricks.

**Need detailed setup help?** See **[SETUP.md](SETUP.md)** for OAuth authentication and troubleshooting.

## Data Quality & Filtering

### Test Data Exclusion

**opsDB automatically filters test/dummy data at the staging layer** to ensure accurate analytics and dashboards.

**Current filters:**
- **Accounts:** `name NOT LIKE '%hogwarts%'`
- **Opportunities:** `name NOT LIKE '%hogwarts%'`
- **Leads:** `company NOT LIKE '%hogwarts%'`

**Where filters are applied:**
- **Staging layer** (`stg_salesforce__*` models) - Primary filtering
- **Core layer** (`dim_*` and `fct_*` models) - Automatically inherits filtered data

**Impact:** Test accounts like "Hogwarts School of Witchcraft and Wizardry" and their related opportunities, contacts, tasks, and events are excluded from all analytics.

**To add new test patterns:**
Edit the `WHERE` clause in staging models:
```sql
-- In models/gtm/staging/salesforce/stg_salesforce__account.sql
and lower(name) not like '%hogwarts%'
and lower(name) not like '%newtest%'  -- Add new pattern
```

---

## Common Operations

### Adding a Field to Existing Model

Example: Adding `expected_revenue` field to `fct_opportunity`

1. **Check if field exists in raw layer**
   ```sql
   SELECT expected_revenue FROM rev_ops_prod.gtm_raw.opportunity LIMIT 10;
   ```

2. **Add to staging model** (`models/gtm/staging/salesforce/stg_salesforce__opportunity.sql`)
   ```sql
   SELECT
       id AS opportunity_id,
       amount,
       expected_revenue,  -- ADD THIS LINE
       ...
   FROM {{ source('salesforce', 'opportunity') }}
   ```

3. **Add to core model** (`models/gtm/core/fct_opportunity.sql`)
   ```sql
   SELECT
       opportunity_id,
       amount,
       expected_revenue,  -- ADD THIS LINE
       ...
   FROM {{ ref('stg_salesforce__opportunity') }}
   ```

4. **Document in schema.yml** (`models/gtm/core/schema.yml`)
   ```yaml
   - name: expected_revenue
     description: Expected revenue for the opportunity
   ```

5. **Run transformations**
   ```bash
   dbt run --select stg_salesforce__opportunity fct_opportunity
   ```

6. **Verify in Databricks**
   ```sql
   SELECT expected_revenue FROM rev_ops_prod.gtm_core.fct_opportunity LIMIT 10;
   ```

### Creating a New Model

1. Create SQL file in appropriate directory
   - Staging: `models/gtm/staging/salesforce/stg_salesforce__<object>.sql`
   - Core: `models/gtm/core/dim_<name>.sql` or `fct_<name>.sql`

2. Use dbt Jinja functions:
   ```sql
   {{ config(materialized='table', tags=['gtm', 'core', 'dimension']) }}

   SELECT
       id,
       name,
       ...
   FROM {{ ref('stg_salesforce__<source>') }}
   ```

3. Add documentation to `models/gtm/core/schema.yml`

4. Run the new model:
   ```bash
   dbt run --select <model_name>
   ```

### Querying Data

**Via Databricks SQL Editor:**
1. Navigate to https://hginsights-rev-ops-prod.cloud.databricks.com
2. Go to SQL Editor
3. Query tables in `rev_ops_prod.gtm_core` or `rev_ops_prod.gtm_staging`

**Common Queries:**
```sql
-- Opportunities with account context
SELECT
    o.opportunity_name,
    o.stage_name,
    o.amount,
    a.account_name,
    a.industry
FROM rev_ops_prod.gtm_core.fct_opportunity o
LEFT JOIN rev_ops_prod.gtm_core.dim_account a
    ON o.account_id = a.account_id
WHERE o.is_closed = false;

-- All available tables
SELECT table_name
FROM rev_ops_prod.information_schema.tables
WHERE table_schema IN ('gtm_staging', 'gtm_core');
```

See **[docs/SCHEMA_REFERENCE.md](docs/SCHEMA_REFERENCE.md)** for more join patterns and table details.

### Running Tests

```bash
# Run all tests
dbt test

# Test specific model
dbt test --select fct_opportunity
```

## Project Structure

```
opsDB/
├── README.md                 # This file - start here
├── SETUP.md                  # Databricks connection setup
├── ARCHITECTURE.md           # Complete system architecture
├── dbt_project.yml           # dbt configuration
├── packages.yml              # dbt dependencies
├── requirements.txt          # Python dependencies
├── profiles.yml.template     # Databricks connection template
│
├── models/gtm/
│   ├── staging/salesforce/
│   │   ├── src_salesforce.yml            # Source definitions
│   │   ├── stg_salesforce.yml            # Staging tests
│   │   └── stg_salesforce__*.sql         # 25 staging models
│   ├── core/
│   │   ├── schema.yml                    # Complete field docs (1,969 lines)
│   │   ├── dim_*.sql                     # 8 dimension models
│   │   └── fct_*.sql                     # 15 fact models
│   └── mart/
│       └── schema.yml                    # Future analytics layer
│
├── macros/
│   └── generate_schema_name.sql          # Custom schema naming
│
└── docs/
    └── SCHEMA_REFERENCE.md               # All tables + join patterns
```

## Data Sources

All data originates from **Salesforce** via **Fivetran**, which syncs to the `rev_ops_prod.gtm_raw` schema in Databricks.

**Source Objects:**
- Account, Contact, Lead, User
- Opportunity, Campaign, Campaign Member, Campaign Influence
- Task, Event, Email Message
- Forecasting Item, Forecasting Quota, Period
- Opportunity Contact Role, Opportunity Field History
- Pricebook, Pricebook Entry, Opportunity Line Item, Quote Line Item
- RollWorks User Summary, Account Summary, Tracking Data, Tracking Aggregation, Field Mapping

## Key Features

✅ **Zero dependencies** - fully self-contained repository
✅ **Complete independence** - modify models, add fields, create objects without restrictions
✅ **Verified accuracy** - all 48 models tested against Databricks
✅ **Comprehensive docs** - 100% field documentation in schema.yml (240+ fields documented)
✅ **Modern dbt** - uses dbt-databricks 1.8.6 with Unity Catalog
✅ **OAuth authentication** - secure Databricks connection
✅ **Column descriptions** - All field descriptions synced to Databricks Unity Catalog

## Common dbt Commands

```bash
# Run all models
dbt run

# Run specific model with dependencies
dbt run --select +fct_opportunity

# Run only staging layer
dbt run --select models/gtm/staging

# Full refresh (rebuild from scratch)
dbt run --full-refresh

# Compile SQL without running
dbt compile --select fct_opportunity

# Generate documentation
dbt docs generate
dbt docs serve
```

## Troubleshooting

### Connection Issues

```bash
# Verify Databricks authentication
databricks auth login

# Test dbt connection
dbt debug

# Check profiles.yml configuration
cat ~/.dbt/profiles.yml
```

### Model Failures

```bash
# Run with verbose logging
dbt run --select <model> --debug

# Check compiled SQL
cat target/compiled/opsdb/models/gtm/core/<model>.sql

# Test in Databricks SQL directly
# Copy compiled SQL and run in Databricks SQL editor
```

### Field Not Found Errors

1. Verify field exists in raw layer (Fivetran schema)
2. Check field is in staging model
3. Verify field is in core model
4. Run both staging and core models in order

See **SETUP.md** for more troubleshooting steps.

## Contributing

When modifying models:

1. **Add fields**: Update staging → core → run → verify
2. **Create models**: Follow naming conventions (stg_, dim_, fct_)
3. **Document**: Add column descriptions to schema.yml
4. **Test**: Run `dbt test` before committing
5. **Verify**: Check Databricks tables directly

## Package Dependencies

- **dbt-utils** (1.3.0) - Common dbt utility macros
- **elementary** (0.19.3) - Data quality monitoring

Install with: `dbt deps`

## License

Internal project - not for external distribution

## Documentation

### Essential Guides
- **[SETUP.md](SETUP.md)** - Databricks OAuth setup and troubleshooting
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Complete system architecture and data flow
- **[docs/SCHEMA_REFERENCE.md](docs/SCHEMA_REFERENCE.md)** - All 48 tables with join patterns

### Field Documentation
- **[models/gtm/core/schema.yml](models/gtm/core/schema.yml)** - Complete field definitions (1,969 lines, 240+ fields documented)

---

**Last Updated:** 2025-11-20
**dbt Version:** 1.8.6
**Databricks Catalog:** rev_ops_prod
**Total Models:** 48 (25 staging + 23 core)
