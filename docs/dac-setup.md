# Detection as Code (DaC) Pipeline Setup Guide

This guide explains how to set up and use the Detection as Code pipeline for syncing detection rules between GitHub and Elastic Security.

## Overview

The DaC pipeline provides bidirectional synchronization between:
- **GitHub** (source of truth) - where rules are developed and version controlled
- **Elastic Security** (deployment target) - where rules are deployed and can be modified

## Architecture

```
┌─────────────┐                    ┌──────────────────┐
│   GitHub    │                    │  Elastic Security │
│  (Source)   │                    │ (sub.metis.us.com)│
└──────┬───────┘                    └────────┬─────────┘
       │                                     │
       │  Push to main branch               │
       ├───────────────────────────────────>│
       │                                     │
       │  Daily sync / Manual trigger        │
       │<───────────────────────────────────┤
       │                                     │
```

### Workflows

1. **Sync to Elastic** (`sync-to-elastic.yml`)
   - Triggers: Push to main branch, manual dispatch
   - Action: Syncs rules from GitHub to Elastic Security
   - Validates rules before syncing
   - Overwrites existing rules in Elastic

2. **Sync from Elastic** (`sync-from-elastic.yml`)
   - Triggers: Daily at 2 AM UTC, manual dispatch
   - Action: Exports rules from Elastic and creates a PR in GitHub
   - Only exports custom rules (not prebuilt rules)
   - Creates a pull request for review

## Prerequisites

1. **Elastic Security Instance**
   - Access to Kibana at `https://sub.metis.us.com`
   - API key with permissions to read/write detection rules

2. **GitHub Repository**
   - Repository with detection-rules codebase
   - GitHub Actions enabled
   - Secrets configured (see Configuration section)

3. **Python Environment**
   - Python 3.13+
   - Detection rules CLI installed

## Configuration

### GitHub Secrets

Configure the following secrets in your GitHub repository settings:

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Add the following secrets:

| Secret Name | Description | Example |
|------------|-------------|---------|
| `ELASTIC_KIBANA_URL` | Full URL to your Kibana instance | `https://sub.metis.us.com` |
| `ELASTIC_API_KEY` | API key for Elastic authentication | `your-api-key-here` |
| `ELASTIC_SPACE` | Kibana space (optional, defaults to 'default') | `default` |

### Creating an API Key

1. Log in to Kibana at `https://sub.metis.us.com`
2. Navigate to **Management** → **Stack Management** → **API Keys**
3. Click **Create API key**
4. Provide a name (e.g., "GitHub Actions DaC")
5. Set appropriate permissions:
   - `kibana_admin` or specific detection rules permissions
6. Copy the API key and add it to GitHub Secrets

### Local Configuration (Optional)

For local testing, create a `.detection-rules-cfg.json` file in the repository root:

```json
{
  "kibana_url": "https://sub.metis.us.com",
  "api_key": "your-api-key-here",
  "space": "default"
}
```

**Note:** This file is gitignored and should not be committed.

## Directory Structure

```
detection-rules/
├── custom_rules/              # Custom rules directory
│   ├── _config.yaml           # Configuration for custom rules
│   ├── rules/                 # Detection rules (TOML files)
│   ├── exceptions/            # Exception lists (TOML files)
│   └── action_connectors/     # Action connectors (TOML files)
├── .github/
│   ├── workflows/
│   │   ├── sync-to-elastic.yml    # GitHub → Elastic workflow
│   │   └── sync-from-elastic.yml  # Elastic → GitHub workflow
│   └── dac-config.example.json    # Example configuration
└── docs/
    └── dac-setup.md           # This file
```

## Usage

### Adding a New Rule

1. Create a new TOML file in `custom_rules/rules/`
2. Use the CLI to create the rule:
   ```bash
   python -m detection_rules create-rule custom_rules/rules/my_new_rule.toml
   ```
3. Test the rule:
   ```bash
   CUSTOM_RULES_DIR=custom_rules python -m detection_rules test
   ```
4. Commit and push to main branch
5. The workflow will automatically sync to Elastic

### Modifying a Rule

1. Edit the TOML file in `custom_rules/rules/`
2. Test the changes:
   ```bash
   CUSTOM_RULES_DIR=custom_rules python -m detection_rules test
   ```
3. Commit and push to main branch
4. The workflow will automatically sync to Elastic

### Syncing from Elastic

Rules modified directly in Elastic Security will be synced back to GitHub:

1. The scheduled workflow runs daily at 2 AM UTC
2. Or manually trigger via **Actions** → **Sync Rules from Elastic** → **Run workflow**
3. A pull request will be created with the changes
4. Review and merge the PR to incorporate changes

**Important:** GitHub is the source of truth. Changes made directly in Elastic will be overwritten by the next sync from GitHub unless you merge the PR.

## Workflow Details

### Sync to Elastic Workflow

**Triggers:**
- Push to main branch (when `custom_rules/**` or `rules/**` files change)
- Manual workflow dispatch

**Steps:**
1. Checkout repository
2. Set up Python 3.13
3. Install dependencies
4. Validate rules (run tests)
5. Sync custom rules to Elastic
6. Sync exceptions (if present)
7. Sync action connectors (if present)

**Configuration:**
- Uses `CUSTOM_RULES_DIR` environment variable (default: `custom_rules`)
- Overwrites existing rules in Elastic (`-o` flag)
- Includes exceptions and action connectors

### Sync from Elastic Workflow

**Triggers:**
- Scheduled: Daily at 2 AM UTC
- Manual workflow dispatch

**Steps:**
1. Checkout repository
2. Set up Python 3.13
3. Install dependencies
4. Export custom rules from Elastic
5. Import rules to repository
6. Check for changes
7. Create pull request (if changes detected)

**Configuration:**
- Only exports custom rules (`-cro` flag)
- Includes exceptions and action connectors
- Preserves local creation and updated dates
- Skips errors during export/import

## Conflict Resolution

### When GitHub and Elastic Have Different Versions

1. **GitHub → Elastic Sync:**
   - GitHub version always wins
   - Elastic version is overwritten
   - No conflicts (overwrite flag used)

2. **Elastic → GitHub Sync:**
   - Creates a PR with Elastic changes
   - Manual review required
   - Merge PR to incorporate changes
   - If PR is not merged, Elastic changes will be overwritten on next GitHub sync

### Best Practices

1. **Always develop in GitHub:**
   - Make changes in the repository
   - Test locally before pushing
   - Push to main to deploy

2. **Review Elastic sync PRs:**
   - Check what changed in Elastic
   - Determine if changes should be kept
   - Merge or close PR accordingly

3. **Avoid direct Elastic edits:**
   - Use GitHub as the primary interface
   - Direct Elastic edits will be overwritten

## Troubleshooting

### Workflow Fails to Authenticate

**Problem:** Workflow fails with authentication errors

**Solutions:**
- Verify `ELASTIC_API_KEY` secret is set correctly
- Check API key has not expired
- Ensure API key has required permissions
- Verify `ELASTIC_KIBANA_URL` is correct

### Rules Not Syncing

**Problem:** Rules in `custom_rules/rules/` are not syncing to Elastic

**Solutions:**
- Check workflow is triggered (push to main or manual)
- Verify `CUSTOM_RULES_DIR` environment variable is set
- Check workflow logs for errors
- Ensure rules are valid TOML files
- Verify rules pass validation tests

### Import Errors

**Problem:** Rules fail to import with validation errors

**Solutions:**
- Run validation locally: `python -m detection_rules test`
- Check rule schema compliance
- Review error messages in workflow logs
- Use `-ske` (skip errors) flag if needed (not recommended)

### PR Not Created

**Problem:** Sync from Elastic doesn't create a PR

**Solutions:**
- Check if there are actual changes (workflow may complete successfully with no changes)
- Verify workflow has `contents: write` and `pull-requests: write` permissions
- Check workflow logs for errors
- Ensure `GITHUB_TOKEN` has sufficient permissions

### Rules Overwritten Unexpectedly

**Problem:** Rules in Elastic are overwritten when they shouldn't be

**Solutions:**
- Remember: GitHub is the source of truth
- Changes in Elastic will be overwritten by GitHub sync
- To keep Elastic changes, merge the PR created by Elastic sync
- Consider using tags or metadata to identify rule sources

## Advanced Configuration

### Custom Schedule

To change the sync schedule, edit `.github/workflows/sync-from-elastic.yml`:

```yaml
on:
  schedule:
    - cron: '0 2 * * *'  # Change this line
```

Cron format: `minute hour day month day-of-week`

### Custom Rules Directory

To use a different directory, update the workflow files:

```yaml
env:
  CUSTOM_RULES_DIR: your_custom_directory
```

And set the environment variable when running CLI commands:

```bash
CUSTOM_RULES_DIR=your_custom_directory python -m detection_rules test
```

### Excluding Rules from Sync

Add rules to `.gitignore` or use workflow path filters to exclude specific rules from syncing.

## Security Considerations

1. **API Keys:**
   - Store in GitHub Secrets (never commit)
   - Rotate regularly
   - Use least privilege principle

2. **Repository Access:**
   - Limit who can modify workflows
   - Review PRs before merging
   - Use branch protection rules

3. **Rule Validation:**
   - Always validate rules before syncing
   - Review changes in PRs
   - Test in non-production first

## Support and Resources

- [DaC Reference Documentation](https://dac-reference.readthedocs.io/en/latest/)
- [Detection Rules CLI Documentation](CLI.md)
- [Custom Rules Management](docs-dev/custom-rules-management.md)
- [GitHub Issues](https://github.com/elastic/detection-rules/issues)

## Next Steps

1. Configure GitHub Secrets
2. Test the workflows manually
3. Add your first custom rule
4. Monitor sync operations
5. Review and merge PRs from Elastic sync

