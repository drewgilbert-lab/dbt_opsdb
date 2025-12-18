# opsDB Architecture

**Complete architectural overview of the opsDB GTM data warehouse.**

---

## Table of Contents

- [Overview](#overview)
- [Data Flow](#data-flow)
- [Architecture Layers](#architecture-layers)
- [Technology Stack](#technology-stack)
- [Schema Design](#schema-design)
- [All Models Reference](#all-models-reference)
- [Unity Catalog Structure](#unity-catalog-structure)
- [Data Refresh & Scheduling](#data-refresh--scheduling)
- [Security & Access](#security--access)

---

## Overview

**opsDB** is an independent dbt project that transforms GTM (Go-To-Market) data from multiple sources in Databricks. It provides a unified, analytics-ready data warehouse for sales, marketing, and revenue operations.

### Key Characteristics

- **Platform:** Databricks with Unity Catalog
- **Transformation Tool:** dbt 1.8.6
- **Data Sources:** Multi-source GTM warehouse (current: Salesforce; future: HubSpot, Marketo, Gainsight, etc.)
- **Current Models:** 48 total (25 staging + 23 core)
- **Architecture:** Medallion (Bronze → Silver → Gold) with source-specific staging
- **Design Philosophy:** Extensible architecture for adding new GTM sources
- **Independence:** Zero dependencies on company-wide repos

### What Problems Does opsDB Solve?

1. **GTM data is scattered across systems** → Centralized multi-source warehouse
2. **Raw source data is messy** → Staging layer cleans and deduplicates per source
3. **Analysts need unified view** → Core layer creates single source of truth across all GTM tools
4. **Joining across sources is complex** → Pre-built star schema with unified dimensions
5. **Data quality issues** → Soft deletes removed, nulls handled, types standardized

---

## Data Flow

```
┌───────────────┬───────────────┬───────────────┬───────────────┐
│   SALESFORCE  │    HUBSPOT    │    MARKETO    │   GAINSIGHT   │
│  (Current)    │   (Future)    │   (Future)    │   (Future)    │
│               │               │               │               │
│  CRM Data     │  Marketing    │  Email        │  Customer     │
│  Opps, Acts   │  Contacts     │  Campaigns    │  Health       │
└───────┬───────┴───────┬───────┴───────┬───────┴───────┬───────┘
        │               │               │               │
        │ Fivetran      │ Fivetran      │ Fivetran      │ Fivetran
        │ (Daily 21:49) │               │               │
        ↓               ↓               ↓               ↓
┌──────────────────────────────────────────────────────────────────┐
│                    LAYER 1: gtm_raw                               │
│                    (Bronze Layer - Source-Specific)               │
│                                                                   │
│  Catalog:  rev_ops_prod                                           │
│  Schema:   gtm_raw                                                │
│  Tables:   Raw tables from all GTM sources                        │
│            - Salesforce: 16 tables (current)                      │
│            - HubSpot: TBD (future)                                │
│            - Marketo: TBD (future)                                │
│  Owner:    Fivetran/Source systems (read-only for dbt)            │
│                                                                   │
│  Characteristics:                                                 │
│  ✓ Exact replica of source systems                                │
│  ✓ No transformations                                             │
│  ✓ Source-specific schemas and naming                             │
│  ✓ Includes deleted records                                       │
│  ✓ May contain duplicates                                         │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         │ dbt run (staging models)
                         │ - Deduplicate per source
                         │ - Remove soft deletes
                         │ - Standardize naming per source
                         │ - Cast data types
                         ↓
┌──────────────────────────────────────────────────────────────────┐
│                   LAYER 2: gtm_staging                            │
│                   (Silver Layer - Source-Specific Clean)          │
│                                                                   │
│  Catalog:  rev_ops_prod                                           │
│  Schema:   gtm_staging                                            │
│  Models:   Source-specific staging models                         │
│            - stg_salesforce__* (25 models - current)              │
│            - stg_hubspot__* (future)                              │
│            - stg_marketo__* (future)                              │
│  Owner:    dbt                                                    │
│                                                                   │
│  Characteristics:                                                 │
│  ✓ One staging model per source table                             │
│  ✓ Maintains source-specific logic                                │
│  ✓ Deduplicated (latest record only)                              │
│  ✓ Soft deletes removed                                           │
│  ✓ Column naming standardized (snake_case)                        │
│  ✓ No business logic (just cleaning)                              │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         │ dbt run (core models)
                         │ - UNION across sources
                         │ - Add source_system column
                         │ - Apply unified business logic
                         │ - Create star schema
                         ↓
┌──────────────────────────────────────────────────────────────────┐
│                    LAYER 3: gtm_core                              │
│                    (Gold Layer - Unified Multi-Source)            │
│                                                                   │
│  Catalog:  rev_ops_prod                                           │
│  Schema:   gtm_core                                               │
│  Models:   23 core models (8 dims + 15 facts)                     │
│  Owner:    dbt                                                    │
│                                                                   │
│  Characteristics:                                                 │
│  ✓ Unified view across ALL GTM sources                            │
│  ✓ Star schema design (dimensions + facts)                        │
│  ✓ source_system column tracks origin                             │
│  ✓ Business logic applied consistently                            │
│  ✓ Calculated fields (ARR, pipeline, conversion)                  │
│  ✓ Denormalized for analytics                                     │
│  ✓ Foreign keys to dimensions                                     │
│  ✓ Ready for BI tools and analysis                                │
│                                                                   │
│  Example: dim_contact unions Salesforce + HubSpot contacts        │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         │ Future: dbt run (mart models)
                         │ - Pre-aggregated metrics
                         │ - Report-specific tables
                         ↓
┌──────────────────────────────────────────────────────────────────┐
│                    LAYER 4: gtm_mart                              │
│                    (Gold Layer - Analytics)                       │
│                                                                   │
│  Catalog:  rev_ops_prod                                           │
│  Schema:   gtm_mart                                               │
│  Models:   0 (placeholder for future)                             │
│  Owner:    dbt                                                    │
│                                                                   │
│  Future Use Cases:                                                │
│  • Pre-aggregated dashboards                                      │
│  • Time-series metrics                                            │
│  • Report-specific rollups                                        │
└──────────────────────────────────────────────────────────────────┘
                         │
                         ↓
                  BI TOOLS & ANALYSTS
         (Databricks SQL, Tableau, Looker, etc.)
```

---

## Architecture Layers

### Layer 1: gtm_raw (Bronze) - Source System Replication

**Purpose:** Exact replica of all GTM source systems

**Managed By:** Fivetran / Source connectors (automated sync)

**Current Tables:** 16 Salesforce objects (future: HubSpot, Marketo, Gainsight tables)
- account
- campaign
- campaign_influence
- campaign_member
- contact
- email_message
- event
- forecasting_item
- forecasting_quota
- lead
- opportunity
- opportunity_contact_role
- opportunity_field_history
- period
- task
- user

**Characteristics:**
- ✓ No transformations applied
- ✓ Source-specific schemas and naming conventions
- ✓ Includes deleted records (`is_deleted = true/false`)
- ✓ May contain duplicate rows
- ✓ Column names as-is from source (PascalCase, mixed formats)
- ✓ Raw data types (no casting)
- ✓ Full historical data
- ✓ Each source maintains its own tables

**Access:** Read-only for dbt, managed by ingestion tools

---

### Layer 2: gtm_staging (Silver) - Source-Specific Data Quality

**Purpose:** Clean, deduplicated, standardized data per source system

**Managed By:** dbt (via source-specific staging models)

**Current Models:** 16 Salesforce staging models (`stg_salesforce__*`)
**Future Models:** HubSpot (`stg_hubspot__*`), Marketo (`stg_marketo__*`), etc.

**Design Pattern:** One staging model per source table, organized by source system

**Transformation Logic:**

```sql
-- Example: stg_salesforce__opportunity.sql
WITH source AS (
    SELECT * FROM {{ source('salesforce', 'opportunity') }}
    WHERE NOT is_deleted  -- Remove soft deletes
),

deduped AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY id
            ORDER BY _fivetran_synced DESC
        ) AS row_num
    FROM source
)

SELECT
    -- IDs (snake_case)
    id AS opportunity_id,
    account_id,
    owner_id,

    -- Business fields (snake_case)
    name AS opportunity_name,
    stage_name,
    amount,
    close_date,

    -- Calculated fields
    CASE
        WHEN is_won THEN 'Won'
        WHEN is_closed THEN 'Lost'
        ELSE 'Open'
    END AS opportunity_status,

    -- Metadata
    created_date,
    last_modified_date,
    _fivetran_synced AS last_synced_at

FROM deduped
WHERE row_num = 1  -- Keep only latest record
```

**Characteristics:**
- ✓ Deduplicated by primary key
- ✓ Soft deletes removed (`is_deleted = false`)
- ✓ Column names standardized (snake_case)
- ✓ Data types cast properly
- ✓ No business logic (just cleaning)
- ✓ One-to-one mapping with source tables

**Models:**
1. `stg_salesforce__account`
2. `stg_salesforce__campaign`
3. `stg_salesforce__campaign_influence`
4. `stg_salesforce__campaign_member`
5. `stg_salesforce__contact`
6. `stg_salesforce__email_message`
7. `stg_salesforce__event`
8. `stg_salesforce__forecasting_item`
9. `stg_salesforce__forecasting_quota`
10. `stg_salesforce__lead`
11. `stg_salesforce__opportunity`
12. `stg_salesforce__opportunity_contact_role`
13. `stg_salesforce__opportunity_field_history`
14. `stg_salesforce__period`
15. `stg_salesforce__task`
16. `stg_salesforce__user`

---

### Layer 3: gtm_core (Gold) - Unified Business Logic

**Purpose:** Unified, analytics-ready star schema combining ALL GTM sources

**Managed By:** dbt (via `dim_*.sql` and `fct_*.sql` models)

**Models:** 23 core models (8 dimensions + 15 facts)

**Schema Design:** Star schema with source tracking

**Multi-Source Strategy:**
- Core models UNION data from multiple source staging tables
- `source_system` column tracks origin (e.g., 'salesforce', 'hubspot')
- Unified business logic applied consistently across sources
- Primary keys include source prefix when needed (e.g., `sfdc_123`, `hubspot_456`)

#### Dimensions (6 models)

Unified dimensions combining data from all GTM sources.

**1. dim_user** - Users and record owners across all systems
- Primary key: `user_id`
- Source systems: Salesforce (current), HubSpot (future)
- Contains: Name, email, role, title, is_active, source_system
- Used for: Opportunity owners, task assignments, activity tracking

**2. dim_account** - Customer accounts and prospects
- Primary key: `account_id`
- Source systems: Salesforce (current), HubSpot (future)
- Contains: Name, industry, type, ownership, billing info, source_system
- Used for: Opportunity relationships, contact affiliations
- Multi-source: Deduplicated by company domain/name matching

**3. dim_contact** - Individual contacts at accounts
- Primary key: `contact_id`
- Source systems: Salesforce (current), HubSpot (future), Marketo (future)
- Contains: Name, email, title, account relationship, source_system
- Used for: Campaign members, opportunity roles, activities
- Multi-source: Deduplicated by email address

**4. dim_lead** - Unqualified leads not yet converted
- Primary key: `lead_id`
- Source systems: Salesforce (current), HubSpot (future)
- Contains: Name, company, status, source, rating, source_system
- Used for: Lead conversion analysis, marketing attribution

**5. dim_campaign** - Marketing campaigns
- Primary key: `campaign_id`
- Source systems: Salesforce (current), HubSpot (future), Marketo (future)
- Contains: Name, type, status, start/end dates, source_system
- Used for: Campaign influence, member tracking

**6. dim_forecasting_period** - Forecasting time periods
- Primary key: `period_id`
- Source systems: Salesforce (current)
- Contains: Name, start/end dates, type (month/quarter/year)
- Used for: Forecasting quotas and items

#### Facts (8 models)

Transactional or event-based tables with metrics and foreign keys to dimensions.

**1. fct_opportunity** - Sales opportunities (deals)
- Grain: One row per opportunity
- Dimensions: account_id, owner_id, campaign_id
- Metrics: amount, arr_c, arr_churn_c, probability
- Use cases: Pipeline analysis, revenue forecasting, win rate

**2. fct_task** - Sales activities (calls, emails, todos)
- Grain: One row per task
- Dimensions: account_id, owner_id, who_id (contact/lead)
- Metrics: activity_date, completion_date
- Use cases: Activity tracking, rep productivity, account coverage

**3. fct_event** - Calendar events and meetings
- Grain: One row per event
- Dimensions: account_id, owner_id, who_id (contact/lead)
- Metrics: start_datetime, end_datetime, duration_minutes
- Use cases: Meeting analysis, time tracking

**4. fct_email_message** - Email communications
- Grain: One row per email
- Dimensions: related_to_id (account/opportunity)
- Metrics: email_date, open_count, click_count
- Use cases: Email engagement, outreach effectiveness

**5. fct_campaign_member** - Campaign membership
- Grain: One row per contact-campaign relationship
- Dimensions: campaign_id, contact_id, lead_id
- Metrics: first_responded_date, status
- Use cases: Campaign effectiveness, member engagement

**6. fct_campaign_influence** - Campaign attribution to opportunities
- Grain: One row per campaign-opportunity influence
- Dimensions: campaign_id, opportunity_id, contact_id
- Metrics: influence_amount, influence_percent
- Use cases: Marketing attribution, ROI analysis

**7. fct_forecasting_quota** - Sales quotas by period
- Grain: One row per user-period quota
- Dimensions: owner_id, period_id
- Metrics: quota_amount, quota_quantity
- Use cases: Quota vs. attainment, forecast accuracy

**8. fct_forecasting_item** - Individual forecast submissions
- Grain: One row per forecasted opportunity
- Dimensions: opportunity_id, owner_id, period_id
- Metrics: forecast_amount, forecast_quantity, forecast_category
- Use cases: Forecast accuracy, pipeline commit

---

### Layer 4: gtm_mart (Future) - Analytics

**Purpose:** Pre-aggregated, report-ready tables

**Status:** Placeholder (no models yet)

**Future Use Cases:**
- Sales velocity by stage
- Pipeline health metrics
- Lead conversion funnels
- Time-series aggregations
- Executive dashboards

---

## Technology Stack

### Core Technologies

**dbt (Data Build Tool) 1.8.6**
- SQL-based transformation framework
- Jinja templating for dynamic SQL
- Built-in testing and documentation
- Dependency management and orchestration

**Databricks**
- Lakehouse platform (data warehouse + data lake)
- Unity Catalog for governance
- SQL Warehouses for compute
- Delta Lake for ACID transactions

**Unity Catalog**
- Three-level namespace: `catalog.schema.table`
- Fine-grained access control
- Data lineage tracking
- Metadata management

**Fivetran (External)**
- Automated data ingestion
- Salesforce → Databricks sync
- Change Data Capture (CDC)
- Managed service (not in this repo)

### Language & Dependencies

**Python 3.9+**
- dbt-databricks adapter
- databricks-sdk for authentication

**dbt Packages**
- `dbt_utils 1.3.0` - Common macros and helpers
- `elementary 0.19.3` - Data quality monitoring

**Custom Macros**
- `generate_schema_name.sql` - Custom schema naming logic

---

## Schema Design

### Star Schema Architecture

```
        ┌──────────────┐
        │  dim_user    │
        │ (user_id PK) │
        └──────┬───────┘
               │
        ┌──────┴───────────────────────────┐
        │                                   │
┌───────▼───────┐                  ┌───────▼────────┐
│  dim_account  │                  │ fct_opportunity│
│(account_id PK)│◄─────────────────┤                │
└───────┬───────┘                  │ • opportunity_id
        │                          │ • account_id FK
        │                          │ • owner_id FK
        │                          │ • amount
┌───────▼───────┐                  │ • arr_c
│  dim_contact  │                  │ • close_date
│(contact_id PK)│                  └────────────────┘
└───────┬───────┘
        │
        │
┌───────▼───────┐
│   fct_task    │
│               │
│ • task_id     │
│ • who_id FK   │
│ • owner_id FK │
│ • account_id FK
└───────────────┘
```

### Key Relationships

**Opportunity → Account (Many-to-One)**
```sql
FROM fct_opportunity o
LEFT JOIN dim_account a ON o.account_id = a.account_id
```

**Opportunity → User/Owner (Many-to-One)**
```sql
FROM fct_opportunity o
LEFT JOIN dim_user u ON o.owner_id = u.user_id
```

**Task → Contact/Lead (Many-to-One)**
```sql
FROM fct_task t
LEFT JOIN dim_contact c ON t.who_id = c.contact_id
LEFT JOIN dim_lead l ON t.who_id = l.lead_id
```

**Campaign Member → Campaign + Contact (Many-to-One each)**
```sql
FROM fct_campaign_member cm
LEFT JOIN dim_campaign c ON cm.campaign_id = c.campaign_id
LEFT JOIN dim_contact ct ON cm.contact_id = ct.contact_id
```

See [docs/SCHEMA_REFERENCE.md](docs/SCHEMA_REFERENCE.md) for complete join examples.

---

## All Models Reference

### Staging Models (16)

| Model | Source Table | Rows (approx) | Purpose |
|-------|--------------|---------------|---------|
| stg_salesforce__account | account | ~10K | Clean account data |
| stg_salesforce__campaign | campaign | ~500 | Clean campaign data |
| stg_salesforce__campaign_influence | campaign_influence | ~1K | Clean campaign influence |
| stg_salesforce__campaign_member | campaign_member | ~50K | Clean campaign membership |
| stg_salesforce__contact | contact | ~100K | Clean contact data |
| stg_salesforce__email_message | email_message | ~500K | Clean email data |
| stg_salesforce__event | event | ~200K | Clean calendar events |
| stg_salesforce__forecasting_item | forecasting_item | ~5K | Clean forecast items |
| stg_salesforce__forecasting_quota | forecasting_quota | ~1K | Clean quotas |
| stg_salesforce__lead | lead | ~150K | Clean lead data |
| stg_salesforce__opportunity | opportunity | ~30K | Clean opportunity data |
| stg_salesforce__opportunity_contact_role | opportunity_contact_role | ~20K | Clean opp contact roles |
| stg_salesforce__opportunity_field_history | opportunity_field_history | ~500K | Clean field history |
| stg_salesforce__period | period | ~100 | Clean periods |
| stg_salesforce__task | task | ~1M | Clean task data |
| stg_salesforce__user | user | ~500 | Clean user data |

### Core Models (14)

| Model | Type | Grain | Key Dimensions | Key Metrics |
|-------|------|-------|----------------|-------------|
| dim_user | Dimension | User | user_id | - |
| dim_account | Dimension | Account | account_id | - |
| dim_contact | Dimension | Contact | contact_id | - |
| dim_lead | Dimension | Lead | lead_id | - |
| dim_campaign | Dimension | Campaign | campaign_id | - |
| dim_forecasting_period | Dimension | Period | period_id | - |
| fct_opportunity | Fact | Opportunity | account_id, owner_id | amount, arr_c, arr_churn_c |
| fct_task | Fact | Task/Activity | account_id, owner_id, who_id | activity_date |
| fct_event | Fact | Event/Meeting | account_id, owner_id, who_id | start_datetime, duration |
| fct_email_message | Fact | Email | related_to_id | email_date, opens, clicks |
| fct_campaign_member | Fact | Campaign Member | campaign_id, contact_id | first_responded_date |
| fct_campaign_influence | Fact | Campaign Influence | campaign_id, opportunity_id | influence_amount |
| fct_forecasting_quota | Fact | Quota | owner_id, period_id | quota_amount |
| fct_forecasting_item | Fact | Forecast Item | opportunity_id, owner_id | forecast_amount |

---

## Unity Catalog Structure

```
rev_ops_prod (catalog)
├── gtm_raw (schema) - Fivetran-managed Salesforce tables
│   ├── account
│   ├── campaign
│   ├── contact
│   ├── lead
│   ├── opportunity
│   ├── task
│   ├── event
│   ├── user
│   └── ... (16 tables total)
│
├── gtm_staging (schema) - dbt staging models
│   ├── stg_salesforce__account
│   ├── stg_salesforce__campaign
│   ├── stg_salesforce__contact
│   ├── stg_salesforce__lead
│   ├── stg_salesforce__opportunity
│   ├── stg_salesforce__task
│   ├── stg_salesforce__event
│   ├── stg_salesforce__user
│   └── ... (16 tables total)
│
├── gtm_core (schema) - dbt core models (star schema)
│   ├── dim_user
│   ├── dim_account
│   ├── dim_contact
│   ├── dim_lead
│   ├── dim_campaign
│   ├── dim_forecasting_period
│   ├── fct_opportunity
│   ├── fct_task
│   ├── fct_event
│   ├── fct_email_message
│   ├── fct_campaign_member
│   ├── fct_campaign_influence
│   ├── fct_forecasting_quota
│   └── fct_forecasting_item
│
└── gtm_mart (schema) - Future analytics layer
    └── (empty - placeholder)
```

**Full table paths:**
- Raw: `rev_ops_prod.gtm_raw.opportunity`
- Staging: `rev_ops_prod.gtm_staging.stg_salesforce__opportunity`
- Core: `rev_ops_prod.gtm_core.fct_opportunity`

---

## Data Refresh & Scheduling

### Automated Daily Sync

**Fivetran Sync:**
- Frequency: Daily at 21:49 PST
- Method: Incremental sync with Change Data Capture
- Destination: `gtm_raw` schema
- Management: External Fivetran service

**dbt Transformations:**
- Frequency: Daily at 21:59 PST (10 minutes after Fivetran sync)
- Command: `dbt run`
- Duration: ~4-5 minutes for full refresh
- Trigger: Automated schedule

### Data Freshness

- **gtm_raw**: Updated daily at 21:49 PST (Fivetran)
- **gtm_staging**: Updated daily at 21:59 PST (dbt)
- **gtm_core**: Updated daily at 21:59 PST (dbt)

**To manually refresh data (if needed):**
```bash
dbt run
```

### Schedule Summary

| Process | Time (PST) | Frequency |
|---------|------------|-----------|
| Fivetran sync | 21:49 | Daily |
| dbt transformations | 21:59 | Daily |

---

## Security & Access

### Authentication

**OAuth (Recommended)**
- Browser-based authentication
- Credentials managed by Databricks
- Token stored in `~/.databricks/cfg`
- Expires periodically (re-auth required)

**Personal Access Token (Alternative)**
- Manual token generation in Databricks UI
- Token stored in `~/.dbt/profiles.yml`
- Never commit tokens to git!

### Authorization (Unity Catalog)

**Required Permissions:**

**Read Access:**
- `USE CATALOG` on `rev_ops_prod`
- `USE SCHEMA` on `gtm_raw`
- `SELECT` on all tables in `gtm_raw`

**Write Access:**
- `USE SCHEMA` on `gtm_staging` and `gtm_core`
- `CREATE TABLE` on `gtm_staging` and `gtm_core`
- `MODIFY` on tables in `gtm_staging` and `gtm_core`

**SQL Warehouse Access:**
- Access to warehouse ID `04baa17dc9cb9ee6`

**Grant Example:**
```sql
-- Grant read access to gtm_raw
GRANT USE CATALOG ON CATALOG rev_ops_prod TO `user@company.com`;
GRANT USE SCHEMA ON SCHEMA rev_ops_prod.gtm_raw TO `user@company.com`;
GRANT SELECT ON SCHEMA rev_ops_prod.gtm_raw TO `user@company.com`;

-- Grant write access to gtm_staging and gtm_core
GRANT USE SCHEMA ON SCHEMA rev_ops_prod.gtm_staging TO `user@company.com`;
GRANT CREATE TABLE ON SCHEMA rev_ops_prod.gtm_staging TO `user@company.com`;
```

### Data Governance

- **Ownership**: Rev Ops team owns `gtm_*` schemas
- **Lineage**: Unity Catalog tracks all dependencies
- **Auditing**: All queries logged in Databricks
- **Data Classification**: Internal use only (not for external sharing)

---

## Next Steps

**Understand the data:**
→ [docs/SCHEMA_REFERENCE.md](docs/SCHEMA_REFERENCE.md) - All tables with examples

**Get it running:**
→ [QUICKSTART.md](QUICKSTART.md) - 5-minute setup

**Make changes:**
→ [CONTRIBUTING.md](CONTRIBUTING.md) - Add fields and models

**Learn workflows:**
→ [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) - Development patterns

---

**Last Updated:** 2025-12-02
**dbt Version:** 1.8.6
**Total Models:** 48 (25 staging + 23 core)
**Databricks Catalog:** rev_ops_prod
