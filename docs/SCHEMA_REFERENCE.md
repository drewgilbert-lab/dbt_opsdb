# Schema Reference

**Complete reference for all tables, relationships, and join patterns in opsDB.**

**opsDB Design:** Multi-source GTM data warehouse. Core models unify data from all sources (current: Salesforce; future: HubSpot, Marketo, Gainsight, etc.)

For complete field-level documentation, see `models/gtm/core/schema.yml` (1,196 lines with every column documented).

---

## Quick Navigation

- [All Tables Summary](#all-tables-summary)
- [Staging Models](#staging-models-25)
- [Core Dimensions](#core-dimensions-8)
- [Core Facts](#core-facts-15)
- [Common Join Patterns](#common-join-patterns)
- [Primary & Foreign Keys](#primary--foreign-keys)

---

## All Tables Summary

| Layer | Schema | Models | Purpose |
|-------|--------|--------|---------|
| Staging | gtm_staging | 25 models | Source-specific clean data (current: Salesforce) |
| Core | gtm_core | 23 models | Unified analytics-ready (8 dimensions + 15 facts) |

**Total:** 48 models verified in production Databricks
**Architecture:** Core models designed to UNION multiple sources as they're added

---

## Staging Models (25)

All in `rev_ops_prod.gtm_staging` - source-specific clean tables.

**Current:** 25 Salesforce models (`stg_salesforce__*`)
**Future:** HubSpot models (`stg_hubspot__*`), Marketo models (`stg_marketo__*`), etc.

**Design:** One staging model per source table, organized by source system in subdirectories.

| Model | Primary Key | Row Count | Key Fields |
|-------|-------------|-----------|------------|
| stg_salesforce__account | account_id | ~10K | account_name, industry, type, owner_id |
| stg_salesforce__campaign | campaign_id | ~500 | campaign_name, type, status, start/end dates |
| stg_salesforce__campaign_influence | campaign_influence_id | ~1K | campaign_id, opportunity_id, influence % |
| stg_salesforce__campaign_member | campaign_member_id | ~50K | campaign_id, contact_id/lead_id, status |
| stg_salesforce__contact | contact_id | ~100K | name, email, title, account_id, owner_id |
| stg_salesforce__email_message | email_message_id | ~500K | subject, from/to, message_date |
| stg_salesforce__event | event_id | ~200K | subject, start/end time, who_id, what_id |
| stg_salesforce__forecasting_item | forecasting_item_id | ~5K | opportunity_id, forecast_amount, category |
| stg_salesforce__forecasting_quota | forecasting_quota_id | ~1K | owner_id, period_id, quota_amount |
| stg_salesforce__lead | lead_id | ~150K | name, company, status, rating, source, owner_id |
| stg_salesforce__opportunity | opportunity_id | ~30K | name, stage, amount, arr_c, close_date, account_id |
| stg_salesforce__opportunity_contact_role | opp_contact_role_id | ~20K | opportunity_id, contact_id, role |
| stg_salesforce__opportunity_field_history | composite | ~500K | opportunity_id, field, old/new value, date |
| stg_salesforce__period | period_id | ~100 | period_name, type, start/end dates |
| stg_salesforce__task | task_id | ~1M | subject, status, activity_date, who_id, what_id |
| stg_salesforce__user | user_id | ~500 | name, email, role, is_active |

---

## Core Dimensions (8)

All in `rev_ops_prod.gtm_core` - unified dimensions across all GTM sources.

**Multi-Source Design:** Each dimension includes a `source_system` column (e.g., 'salesforce', 'hubspot') to track data origin. Future versions will UNION staging models from multiple sources.

### 1. dim_user
**Purpose:** Users and record owners across all GTM systems

**Source Systems:** Salesforce (current), HubSpot (future)

**Key Fields:**
- `user_id` (PK) - Unique identifier
- `source_system` - Origin system ('salesforce', 'hubspot', etc.)
- `full_name`, `email` - User details
- `user_role_name`, `title` - Role info
- `is_active` - Active status

**Use:** Join from any fact with `owner_id`

---

### 2. dim_account
**Purpose:** Customer accounts and prospects (deduplicated across sources)

**Source Systems:** Salesforce (current), HubSpot (future)

**Key Fields:**
- `account_id` (PK)
- `source_system` - Origin system
- `account_name`, `industry`, `account_type`
- `annual_revenue`, `number_of_employees`
- `billing_state`, `billing_country`
- `owner_id` (FK → dim_user)

**Multi-Source Logic:** Deduplicated by company domain/name matching when multiple sources exist

**Use:** Join from opportunities, contacts, tasks

---

### 3. dim_contact
**Purpose:** Individual contacts at accounts (deduplicated across sources)

**Source Systems:** Salesforce (current), HubSpot (future), Marketo (future)

**Key Fields:**
- `contact_id` (PK)
- `source_system` - Origin system
- `account_id` (FK → dim_account)
- `full_name`, `email`, `title`
- `owner_id` (FK → dim_user)

**Multi-Source Logic:** Deduplicated by email address when multiple sources exist

**Use:** Join from campaign members, opportunity roles, tasks

---

### 4. dim_lead
**Purpose:** Unqualified leads

**Key Fields:**
- `lead_id` (PK)
- `full_name`, `company`, `email`
- `status`, `rating`, `lead_source`
- `converted_contact_id`, `converted_account_id`, `converted_opportunity_id`
- `owner_id` (FK → dim_user)

**Use:** Lead conversion analysis

---

### 5. dim_campaign
**Purpose:** Marketing campaigns

**Key Fields:**
- `campaign_id` (PK)
- `campaign_name`, `campaign_type`, `status`
- `start_date`, `end_date`
- `budgeted_cost`, `actual_cost`
- `owner_id` (FK → dim_user)

**Use:** Join from campaign members, campaign influence

---

### 6. dim_forecasting_period
**Purpose:** Time periods for forecasting

**Key Fields:**
- `period_id` (PK)
- `period_name` (e.g., "Q1 2025")
- `period_type` (Month, Quarter, Year)
- `start_date`, `end_date`

**Use:** Join from forecasting quotas/items

---

## Core Facts (15)

All in `rev_ops_prod.gtm_core` - metrics and events.

### 1. fct_opportunity ⭐ (Most Important)
**Purpose:** Sales opportunities with deal metrics

**Grain:** One row per opportunity

**Key Metrics:**
- `amount` - Deal value (USD)
- `arr_c` - Annual Recurring Revenue
- `arr_churn_c` - ARR churn
- `probability` - Win probability %
- `expected_revenue` - amount × probability

**Key Dimensions:**
- `opportunity_name`, `stage_name`, `close_date`
- `is_won`, `is_closed` - Status
- `forecast_category`

**Foreign Keys:**
- `account_id` → dim_account
- `owner_id` → dim_user

**Row Count:** ~30,000

---

### 2. fct_task
**Purpose:** Sales activities (calls, emails, todos)

**Grain:** One row per task

**Key Metrics:**
- `activity_date` - Due date
- `completed_date` - Completion date
- `call_duration_seconds` - Call length

**Key Dimensions:**
- `subject`, `status`, `priority`
- `task_subtype` (Call, Email, Meeting)
- `is_closed`

**Foreign Keys:**
- `who_id` → dim_contact or dim_lead (polymorphic)
- `what_id` → dim_account or fct_opportunity (polymorphic)
- `owner_id` → dim_user

**Row Count:** ~1,000,000

---

### 3. fct_event
**Purpose:** Calendar events and meetings

**Grain:** One row per event

**Key Metrics:**
- `start_datetime`, `end_datetime`
- `duration_minutes`

**Key Dimensions:**
- `subject`, `event_type`, `location`

**Foreign Keys:**
- `who_id` → dim_contact or dim_lead (polymorphic)
- `what_id` → dim_account or fct_opportunity (polymorphic)
- `owner_id` → dim_user

**Row Count:** ~200,000

---

### 4. fct_email_message
**Purpose:** Email communications

**Grain:** One row per email

**Key Metrics:**
- `message_date`
- `open_count`, `click_count` (if tracked)

**Key Dimensions:**
- `subject`, `from_address`, `to_address`, `status`

**Foreign Keys:**
- `related_to_id` (polymorphic)

**Row Count:** ~500,000

---

### 5. fct_campaign_member
**Purpose:** Campaign membership

**Grain:** One row per contact-campaign relationship

**Key Metrics:**
- `first_responded_date`

**Key Dimensions:**
- `status` (Sent, Responded, Attended)
- `member_type` (Contact, Lead)

**Foreign Keys:**
- `campaign_id` → dim_campaign
- `contact_id` → dim_contact (if converted)
- `lead_id` → dim_lead (if not converted)

**Row Count:** ~50,000

---

### 6. fct_campaign_influence
**Purpose:** Marketing attribution to opportunities

**Grain:** One row per campaign-opportunity influence

**Key Metrics:**
- `influence` - Influence % (0-100)
- `influence_amount` - opportunity amount × influence %

**Key Dimensions:**
- `model_name` (First Touch, Last Touch, Multi-Touch)

**Foreign Keys:**
- `campaign_id` → dim_campaign
- `opportunity_id` → fct_opportunity
- `contact_id` → dim_contact

**Row Count:** ~1,000

---

### 7. fct_forecasting_quota
**Purpose:** Sales quotas by period

**Grain:** One row per user-period quota

**Key Metrics:**
- `quota_amount` - Quota (USD)
- `quota_quantity` - # of deals

**Foreign Keys:**
- `owner_id` → dim_user
- `period_id` → dim_forecasting_period

**Row Count:** ~1,000

---

### 8. fct_forecasting_item
**Purpose:** Individual forecast submissions

**Grain:** One row per forecasted opportunity

**Key Metrics:**
- `forecast_amount`
- `forecast_quantity`

**Key Dimensions:**
- `forecast_category` (Pipeline, Best Case, Commit, Closed)

**Foreign Keys:**
- `opportunity_id` → fct_opportunity
- `owner_id` → dim_user
- `period_id` → dim_forecasting_period

**Row Count:** ~5,000

---

## Common Join Patterns

### Pattern 1: Opportunities with Context
```sql
-- Get opportunities with account and owner info
SELECT
    o.opportunity_name,
    o.stage_name,
    o.amount,
    o.close_date,
    a.account_name,
    a.industry,
    u.full_name as owner_name
FROM rev_ops_prod.gtm_core.fct_opportunity o
LEFT JOIN rev_ops_prod.gtm_core.dim_account a
    ON o.account_id = a.account_id
LEFT JOIN rev_ops_prod.gtm_core.dim_user u
    ON o.owner_id = u.user_id
WHERE o.is_closed = false
ORDER BY o.amount DESC
LIMIT 100;
```

### Pattern 2: Activity Tracking
```sql
-- Recent activities with contact and account
SELECT
    t.subject,
    t.status,
    t.activity_date,
    c.full_name as contact_name,
    c.email as contact_email,
    a.account_name,
    u.full_name as rep_name
FROM rev_ops_prod.gtm_core.fct_task t
LEFT JOIN rev_ops_prod.gtm_core.dim_contact c
    ON t.who_id = c.contact_id
LEFT JOIN rev_ops_prod.gtm_core.dim_account a
    ON c.account_id = a.account_id
LEFT JOIN rev_ops_prod.gtm_core.dim_user u
    ON t.owner_id = u.user_id
WHERE t.activity_date >= CURRENT_DATE - INTERVAL 7 DAYS
ORDER BY t.activity_date DESC;
```

### Pattern 3: Pipeline by Stage
```sql
-- Sales pipeline analysis
SELECT
    o.stage_name,
    COUNT(*) as opportunity_count,
    SUM(o.amount) as total_pipeline,
    SUM(o.expected_revenue) as weighted_pipeline,
    AVG(o.amount) as avg_deal_size,
    COUNT(DISTINCT o.account_id) as unique_accounts,
    COUNT(DISTINCT o.owner_id) as unique_owners
FROM rev_ops_prod.gtm_core.fct_opportunity o
WHERE o.is_closed = false
GROUP BY o.stage_name
ORDER BY total_pipeline DESC;
```

### Pattern 4: Campaign Performance
```sql
-- Campaign ROI analysis
SELECT
    c.campaign_name,
    c.campaign_type,
    c.actual_cost,
    COUNT(DISTINCT cm.contact_id) as total_members,
    COUNT(DISTINCT CASE WHEN cm.status = 'Responded' THEN cm.contact_id END) as responded,
    COUNT(DISTINCT ci.opportunity_id) as influenced_opps,
    SUM(ci.influence_amount) as influenced_pipeline,
    SUM(CASE WHEN o.is_won THEN ci.influence_amount ELSE 0 END) as influenced_revenue
FROM rev_ops_prod.gtm_core.dim_campaign c
LEFT JOIN rev_ops_prod.gtm_core.fct_campaign_member cm
    ON c.campaign_id = cm.campaign_id
LEFT JOIN rev_ops_prod.gtm_core.fct_campaign_influence ci
    ON c.campaign_id = ci.campaign_id
LEFT JOIN rev_ops_prod.gtm_core.fct_opportunity o
    ON ci.opportunity_id = o.opportunity_id
GROUP BY c.campaign_name, c.campaign_type, c.actual_cost;
```

### Pattern 5: Lead Conversion Funnel
```sql
-- Lead to opportunity conversion
SELECT
    l.lead_source,
    l.status,
    COUNT(*) as total_leads,
    COUNT(l.converted_contact_id) as converted_to_contact,
    COUNT(l.converted_opportunity_id) as created_opportunity,
    SUM(CASE WHEN o.is_won THEN 1 ELSE 0 END) as won_opportunities,
    SUM(o.amount) as total_pipeline_created
FROM rev_ops_prod.gtm_core.dim_lead l
LEFT JOIN rev_ops_prod.gtm_core.fct_opportunity o
    ON l.converted_opportunity_id = o.opportunity_id
GROUP BY l.lead_source, l.status
ORDER BY total_leads DESC;
```

### Pattern 6: Rep Performance
```sql
-- Sales rep activity and pipeline
SELECT
    u.full_name,
    u.user_role_name,
    COUNT(DISTINCT o.opportunity_id) as open_opportunities,
    SUM(o.amount) as total_pipeline,
    COUNT(DISTINCT t.task_id) as activities_last_30d,
    COUNT(DISTINCT e.event_id) as meetings_last_30d
FROM rev_ops_prod.gtm_core.dim_user u
LEFT JOIN rev_ops_prod.gtm_core.fct_opportunity o
    ON u.user_id = o.owner_id AND o.is_closed = false
LEFT JOIN rev_ops_prod.gtm_core.fct_task t
    ON u.user_id = t.owner_id 
    AND t.activity_date >= CURRENT_DATE - INTERVAL 30 DAYS
LEFT JOIN rev_ops_prod.gtm_core.fct_event e
    ON u.user_id = e.owner_id
    AND e.start_datetime >= CURRENT_TIMESTAMP - INTERVAL 30 DAYS
WHERE u.is_active = true
GROUP BY u.full_name, u.user_role_name
ORDER BY total_pipeline DESC;
```

---

## Primary & Foreign Keys

### Star Schema Relationships

```
dim_user (PK: user_id)
    ├─ fct_opportunity (FK: owner_id)
    ├─ fct_task (FK: owner_id)
    ├─ fct_event (FK: owner_id)
    ├─ dim_account (FK: owner_id)
    ├─ dim_contact (FK: owner_id)
    ├─ dim_lead (FK: owner_id)
    └─ dim_campaign (FK: owner_id)

dim_account (PK: account_id)
    ├─ fct_opportunity (FK: account_id)
    ├─ fct_task (FK: what_id, polymorphic)
    ├─ fct_event (FK: what_id, polymorphic)
    └─ dim_contact (FK: account_id)

dim_contact (PK: contact_id)
    ├─ fct_task (FK: who_id, polymorphic)
    ├─ fct_event (FK: who_id, polymorphic)
    ├─ fct_campaign_member (FK: contact_id)
    └─ fct_campaign_influence (FK: contact_id)

fct_opportunity (PK: opportunity_id)
    ├─ fct_campaign_influence (FK: opportunity_id)
    ├─ fct_forecasting_item (FK: opportunity_id)
    ├─ fct_task (FK: what_id, polymorphic)
    └─ fct_event (FK: what_id, polymorphic)

dim_campaign (PK: campaign_id)
    ├─ fct_campaign_member (FK: campaign_id)
    └─ fct_campaign_influence (FK: campaign_id)
```

### Polymorphic Relationships

**who_id** (person reference):
- Can reference `dim_contact.contact_id` OR `dim_lead.lead_id`
- Used in: fct_task, fct_event

**what_id** (object reference):
- Can reference `dim_account.account_id` OR `fct_opportunity.opportunity_id`
- Used in: fct_task, fct_event

**Query pattern for polymorphic:**
```sql
-- Join to both tables, one will be NULL
SELECT
    t.subject,
    COALESCE(c.full_name, l.full_name) as person_name,
    COALESCE(a.account_name, o.opportunity_name) as related_object
FROM fct_task t
LEFT JOIN dim_contact c ON t.who_id = c.contact_id
LEFT JOIN dim_lead l ON t.who_id = l.lead_id
LEFT JOIN dim_account a ON t.what_id = a.account_id
LEFT JOIN fct_opportunity o ON t.what_id = o.opportunity_id;
```

---

## Quick Reference

### Finding Data

**All opportunities for an account:**
```sql
SELECT * FROM fct_opportunity WHERE account_id = '<account_id>';
```

**All activities for a contact:**
```sql
SELECT * FROM fct_task WHERE who_id = '<contact_id>';
```

**All campaigns for a contact:**
```sql
SELECT c.* 
FROM fct_campaign_member cm
JOIN dim_campaign c ON cm.campaign_id = c.campaign_id
WHERE cm.contact_id = '<contact_id>';
```

**All opportunities owned by a user:**
```sql
SELECT * FROM fct_opportunity WHERE owner_id = '<user_id>';
```

**Converted leads:**
```sql
SELECT * FROM dim_lead WHERE converted_contact_id IS NOT NULL;
```

---

## Field-Level Documentation

For complete column descriptions, data types, and business logic:

**See:** `models/gtm/core/schema.yml` (1,196 lines)

Every field in all 23 core models is documented with:
- Description
- Data type
- Relationships
- Use cases
- Tests

---

## Next Steps

**Understand architecture:**
→ [ARCHITECTURE.md](../ARCHITECTURE.md) - Complete system overview

**Get started:**
→ [QUICKSTART.md](../QUICKSTART.md) - 5-minute setup

**Make changes:**
→ [CONTRIBUTING.md](../CONTRIBUTING.md) - Add fields and models

**Development workflows:**
→ [DEVELOPMENT.md](DEVELOPMENT.md) - Best practices

---

**Last Updated:** 2025-12-02
**Total Models:** 48 (25 staging + 23 core)
**Full Documentation:** models/gtm/core/schema.yml
