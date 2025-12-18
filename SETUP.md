# opsDB Setup Guide

Complete guide for setting up your opsDB development environment for GTM data transformations in Databricks.

## Prerequisites

- **Python 3.9+** installed
- **Databricks workspace access** to `hginsights-rev-ops-prod`
- **Databricks SQL Warehouse** access (ID: `04baa17dc9cb9ee6`)
- **Unity Catalog permissions** for `rev_ops_prod` catalog
- **Source system access** (currently: Salesforce via Fivetran)

## Installation Steps

### 1. Clone Repository

```bash
git clone <your-opsdb-repo-url>
cd opsDB
```

### 2. Install Python Dependencies

```bash
# Install dbt-databricks and dependencies
pip install -r requirements.txt
```

This installs:
- `dbt-databricks==1.8.6` - dbt adapter for Databricks
- `databricks-sdk==0.17.0` - Databricks Python SDK
- `wheel==0.44.0` - Build tool

### 3. Install dbt Packages

```bash
# Install dbt_utils and elementary packages
dbt deps
```

This downloads:
- `dbt_utils` (1.3.0) - Common dbt macros
- `elementary` (0.19.3) - Data quality monitoring

### 4. Configure Databricks Connection

#### Step 4a: Set Up OAuth Authentication

The recommended authentication method is **OAuth** for secure, interactive access.

```bash
# Install Databricks CLI (if not already installed)
pip install databricks-cli

# Authenticate via browser
databricks auth login --host https://hginsights-rev-ops-prod.cloud.databricks.com
```

This will:
1. Open your browser
2. Prompt you to log in to Databricks
3. Store credentials in `~/.databricks/cfg`

#### Step 4b: Create dbt Profile

Copy the template to your home directory:

```bash
cp profiles.yml.template ~/.dbt/profiles.yml
```

Edit `~/.dbt/profiles.yml`:

```yaml
opsdb:
  target: gtm_dev
  outputs:
    gtm_dev:
      type: databricks
      catalog: rev_ops_prod
      schema: gtm_staging
      host: hginsights-rev-ops-prod.cloud.databricks.com
      http_path: /sql/1.0/warehouses/04baa17dc9cb9ee6
      auth_type: oauth
      threads: 4

    gtm_prod:
      type: databricks
      catalog: rev_ops_prod
      schema: gtm_core
      host: hginsights-rev-ops-prod.cloud.databricks.com
      http_path: /sql/1.0/warehouses/04baa17dc9cb9ee6
      auth_type: oauth
      threads: 4
```

**Configuration Parameters:**

- `type`: `databricks` - Use Databricks adapter
- `catalog`: `rev_ops_prod` - Unity Catalog name
- `schema`: Target schema (gtm_staging for dev, gtm_core for prod)
- `host`: Databricks workspace URL
- `http_path`: SQL Warehouse endpoint
- `auth_type`: `oauth` - Use OAuth authentication
- `threads`: `4` - Number of concurrent connections

### 5. Verify Connection

```bash
# Test dbt connection
dbt debug
```

**Expected output:**
```
Running with dbt=1.8.6
dbt version: 1.8.6
python version: 3.9.x
...
Connection test: [OK connection ok]
```

If you see errors, see [Troubleshooting](#troubleshooting) below.

### 6. Run Your First Transformation

```bash
# Run all models
dbt run

# Run specific model
dbt run --select fct_opportunity

# Run staging layer only
dbt run --select models/gtm/staging
```

## Alternative Authentication Methods

### Personal Access Token (PAT)

If OAuth doesn't work, you can use a Personal Access Token:

1. **Generate PAT in Databricks:**
   - Go to Databricks workspace
   - User Settings → Developer → Access Tokens
   - Generate New Token
   - Copy token (you won't see it again!)

2. **Update profiles.yml:**
   ```yaml
   gtm_dev:
     type: databricks
     catalog: rev_ops_prod
     schema: gtm_staging
     host: hginsights-rev-ops-prod.cloud.databricks.com
     http_path: /sql/1.0/warehouses/04baa17dc9cb9ee6
     token: <your-personal-access-token>
     threads: 4
   ```

3. **Security Warning:** Never commit `profiles.yml` with tokens to git!

### Environment Variables

For CI/CD pipelines, use environment variables:

```bash
export DBT_DATABRICKS_HOST="hginsights-rev-ops-prod.cloud.databricks.com"
export DBT_DATABRICKS_HTTP_PATH="/sql/1.0/warehouses/04baa17dc9cb9ee6"
export DBT_DATABRICKS_TOKEN="<your-token>"
export DBT_DATABRICKS_CATALOG="rev_ops_prod"
export DBT_DATABRICKS_SCHEMA="gtm_staging"
```

Update `profiles.yml`:
```yaml
gtm_dev:
  type: databricks
  catalog: "{{ env_var('DBT_DATABRICKS_CATALOG') }}"
  schema: "{{ env_var('DBT_DATABRICKS_SCHEMA') }}"
  host: "{{ env_var('DBT_DATABRICKS_HOST') }}"
  http_path: "{{ env_var('DBT_DATABRICKS_HTTP_PATH') }}"
  token: "{{ env_var('DBT_DATABRICKS_TOKEN') }}"
  threads: 4
```

## Common dbt Commands

### Running Models

```bash
# Run all models
dbt run

# Run specific model
dbt run --select fct_opportunity

# Run model and its dependencies
dbt run --select +fct_opportunity

# Run model and downstream models
dbt run --select fct_opportunity+

# Run all models in a directory
dbt run --select models/gtm/staging

# Run models matching a tag
dbt run --select tag:gtm

# Run in full-refresh mode (drop and recreate)
dbt run --full-refresh
```

### Testing Models

```bash
# Run all tests
dbt test

# Test specific model
dbt test --select fct_opportunity

# Test relationships only
dbt test --select test_type:relationships

# Test unique constraints
dbt test --select test_type:unique
```

### Building Documentation

```bash
# Generate documentation
dbt docs generate

# Serve documentation locally
dbt docs serve
```

### Listing Resources

```bash
# List all models
dbt ls --select models

# List staging models
dbt ls --select models/gtm/staging

# Show model dependencies
dbt ls --select +fct_opportunity --resource-type model
```

### Compiling SQL

```bash
# Compile without running
dbt compile

# Compile specific model
dbt compile --select fct_opportunity

# View compiled SQL
cat target/compiled/opsdb/models/gtm/core/fct_opportunity.sql
```

## Project Configuration

### dbt_project.yml

Key configurations:

```yaml
name: opsdb
version: 1.0.0
config-version: 2

# Model paths
model-paths: ["models"]
analysis-paths: ["analyses"]
test-paths: ["tests"]
seed-paths: ["seeds"]
macro-paths: ["macros"]

# Target paths
target-path: "target"
clean-targets:
  - "target"
  - "dbt_packages"

# Model configs
models:
  opsdb:
    gtm:
      staging:
        +schema: gtm_staging
        +materialized: table
      core:
        +schema: gtm_core
        +materialized: table
      mart:
        +schema: gtm_mart
        +materialized: table
```

### Custom Schema Names

The `generate_schema_name` macro enables custom schema names:

```sql
-- Staging models → rev_ops_prod.gtm_staging
-- Core models → rev_ops_prod.gtm_core
-- Mart models → rev_ops_prod.gtm_mart
```

## Databricks SQL Warehouse

**Warehouse ID:** `04baa17dc9cb9ee6`

**HTTP Path:** `/sql/1.0/warehouses/04baa17dc9cb9ee6`

To find this in Databricks:
1. Go to SQL → SQL Warehouses
2. Click on your warehouse
3. Copy "Server hostname" and "HTTP path" from Connection Details

## Unity Catalog Structure

```
rev_ops_prod (catalog)
├── gtm_raw (schema) - Fivetran-managed Salesforce tables
├── gtm_staging (schema) - Cleaned, deduplicated tables
├── gtm_core (schema) - Business logic dimensions and facts
└── gtm_mart (schema) - Future analytics layer
```

## Data Refresh Schedule

| Process | Time (PST) | Frequency |
|---------|------------|-----------|
| Fivetran sync | 21:49 | Daily |
| dbt transformations | 21:59 | Daily |

- **gtm_raw:** Updated daily at 21:49 PST (Fivetran)
- **gtm_staging/gtm_core:** Updated daily at 21:59 PST (dbt)
- **Manual runs:** You can run `dbt run` anytime for immediate refresh

## Troubleshooting

### Error: "Connection refused" or "Could not connect"

**Solution:**
1. Verify you're authenticated: `databricks auth login`
2. Check SQL Warehouse is running in Databricks UI
3. Verify `host` and `http_path` in `profiles.yml`
4. Test connection: `dbt debug`

### Error: "Catalog 'rev_ops_prod' does not exist"

**Solution:**
1. Verify you have access to Unity Catalog
2. Check permissions in Databricks
3. Contact admin for catalog access

### Error: "OAuth token expired"

**Solution:**
```bash
# Re-authenticate
databricks auth login --host https://hginsights-rev-ops-prod.cloud.databricks.com
```

### Error: "Schema 'gtm_staging' does not exist"

**Solution:**
Schemas are created automatically by dbt when you run models. If this fails:
1. Verify you have CREATE SCHEMA permission
2. Check `catalog` and `schema` in `profiles.yml`
3. Run with debug: `dbt run --debug`

### Error: "Compilation Error in model <name>"

**Solution:**
1. Check compiled SQL: `cat target/compiled/opsdb/models/gtm/core/<name>.sql`
2. Test SQL directly in Databricks SQL editor
3. Verify all upstream models exist: `dbt ls --select +<name>`
4. Run with debug: `dbt compile --select <name> --debug`

### Error: "Database Error: Table not found"

**Cause:** Source table doesn't exist in gtm_raw or staging table not yet created

**Solution:**
1. Check source exists: `SELECT * FROM rev_ops_prod.gtm_raw.opportunity LIMIT 1`
2. Run staging first: `dbt run --select models/gtm/staging`
3. Then run core: `dbt run --select models/gtm/core`

### Error: "Thread error: relation does not exist"

**Cause:** Trying to run models in wrong order (core before staging)

**Solution:**
```bash
# dbt automatically handles dependencies, but you can force order:
dbt run --select models/gtm/staging models/gtm/core
```

### Performance Issues: Models running slowly

**Solution:**
1. Increase threads in profiles.yml: `threads: 8`
2. Check SQL Warehouse size (upgrade if needed)
3. Add `WHERE` filters to large staging tables
4. Use incremental materialization for large facts

### dbt debug fails with "Could not find profile"

**Solution:**
1. Verify `~/.dbt/profiles.yml` exists: `cat ~/.dbt/profiles.yml`
2. Check profile name matches dbt_project.yml: `profile: opsdb`
3. Verify YAML syntax is valid

### Models run but tables not appearing in Databricks

**Solution:**
1. Verify schema: `SHOW SCHEMAS IN rev_ops_prod`
2. Verify tables: `SHOW TABLES IN rev_ops_prod.gtm_core`
3. Check dbt output for errors
4. Refresh Databricks UI (Ctrl+R)

## Best Practices

### 1. Development Workflow

```bash
# 1. Pull latest code
git pull

# 2. Install/update packages
dbt deps

# 3. Test connection
dbt debug

# 4. Run models
dbt run --select <your_model>

# 5. Test models
dbt test --select <your_model>

# 6. Verify in Databricks
# Query the table directly in Databricks SQL
```

### 2. Adding New Fields

See README.md "Adding a New Field to Existing Model" section.

### 3. Code Organization

- Staging models: Clean and standardize only
- Core models: Add business logic, joins, calculations
- Mart models: Pre-aggregated analytics tables (future)

### 4. Documentation

Always document new models in `schema.yml`:

```yaml
models:
  - name: your_new_model
    description: What this model does
    columns:
      - name: id
        description: Primary key
        tests:
          - unique
          - not_null
```

### 5. Version Control

```bash
# Never commit these:
- target/
- dbt_packages/
- logs/
- ~/.dbt/profiles.yml (contains credentials)

# Always commit these:
- models/
- macros/
- dbt_project.yml
- packages.yml
- requirements.txt
```

## Getting Help

1. **Check dbt logs:** `cat logs/dbt.log`
2. **View compiled SQL:** `target/compiled/opsdb/models/...`
3. **Run with debug:** `dbt run --debug`
4. **Test in Databricks:** Copy compiled SQL and run directly
5. **Review schema.yml:** Field definitions and relationships

## Next Steps

Once set up:

1. ✅ Run all models: `dbt run`
2. ✅ Verify in Databricks: Check `gtm_staging` and `gtm_core` schemas
3. ✅ Generate docs: `dbt docs generate && dbt docs serve`
4. ✅ Start making changes: Add fields, create models, write tests

---

**Last Updated:** 2025-11-18
