# Custom Rules Directory

This directory contains custom detection rules that are synced between GitHub and Elastic Security.

## Directory Structure

```
custom_rules/
├── _config.yaml              # Configuration file for custom rules
├── rules/                     # Custom detection rules (TOML files)
├── exceptions/                # Exception lists (TOML files)
├── action_connectors/         # Action connectors (TOML files)
└── etc/                       # Supporting configuration files
    ├── deprecated_rules.json
    ├── packages.yaml
    ├── stack-schema-map.yaml
    └── version.lock.json
```

## Setup

The `_config.yaml` file references the main repository's etc directory for shared configuration files. This avoids duplication while allowing custom rules to be managed separately.

## Usage

- Rules added to `custom_rules/rules/` will be synced to Elastic Security
- Rules modified in Elastic Security will be synced back to this directory
- GitHub is the source of truth - changes made directly in Elastic will be overwritten by the next sync from GitHub

## Workflows

- **Sync to Elastic**: Runs on push to main branch
- **Sync from Elastic**: Runs daily at 2 AM UTC and can be manually triggered


