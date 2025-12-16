# Branch Strategy for Detection Rules Repository

This repository uses a multi-environment branch strategy with the following branches:

## Branch Structure

- **`main`** - Primary development branch (source of truth)
- **`dev`** - Development environment branch
- **`stage`** - Staging environment branch  
- **`prod`** - Production environment branch

## Branch Creation

To create the environment branches, you can use one of the provided scripts:

### Using Bash (Linux/Mac/Git Bash)

```bash
./scripts/create-branches.sh
```

### Using PowerShell (Windows)

```powershell
.\scripts\create-branches.ps1
```

### Manual Creation

If you prefer to create branches manually:

```bash
# Ensure you're on the main branch
git checkout main

# Create and switch to each branch
git checkout -b dev
git checkout main

git checkout -b stage
git checkout main

git checkout -b prod
git checkout main

# Push branches to remote
git push -u origin dev
git push -u origin stage
git push -u origin prod
```

## Workflow Integration

The DaC sync workflows can be configured to target different branches:

- **Development**: Sync `dev` branch to development Elastic instance
- **Staging**: Sync `stage` branch to staging Elastic instance
- **Production**: Sync `prod` branch to production Elastic instance

## Branch Protection

It's recommended to set up branch protection rules in GitHub:

1. Go to **Settings** → **Branches**
2. Add rules for each environment branch:
   - **dev**: Require pull request reviews (optional)
   - **stage**: Require pull request reviews
   - **prod**: Require pull request reviews, require status checks

## Typical Workflow

1. **Development**: Work happens on `main` or feature branches
2. **Promotion**: Merge `main` → `dev` → `stage` → `prod`
3. **Testing**: Test in each environment before promoting
4. **Deployment**: Each branch syncs to its corresponding Elastic instance

## Updating Workflows for Multi-Environment

To use different branches for different environments, update the workflows:

### Example: Sync to Dev Environment

```yaml
on:
  push:
    branches:
      - dev
    paths:
      - 'custom_rules/**'
```

### Example: Sync to Prod Environment

```yaml
on:
  push:
    branches:
      - prod
    paths:
      - 'custom_rules/**'
```

You can also use different GitHub Secrets for each environment:
- `ELASTIC_KIBANA_URL_DEV`
- `ELASTIC_KIBANA_URL_STAGE`
- `ELASTIC_KIBANA_URL_PROD`

