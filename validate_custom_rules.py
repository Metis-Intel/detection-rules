#!/usr/bin/env python3

from pathlib import Path
from detection_rules.rule_loader import RuleCollection

def validate_custom_rules():
    """Validate our custom detection rules."""
    try:
        rc = RuleCollection()

        # Test Ubuntu rule first
        print("Testing Ubuntu rule...")
        ubuntu_path = Path('custom_rules/rules/credential_access_ubuntu_successful_logon.toml')
        rc.load_files([ubuntu_path])
        print('✅ Ubuntu rule loaded successfully!')

        # Test Mimikatz rule
        print("\nTesting Mimikatz rule...")
        rc2 = RuleCollection()
        mimikatz_path = Path('custom_rules/rules/credential_access_mimikatz_detection.toml')
        rc2.load_files([mimikatz_path])
        print('✅ Mimikatz rule loaded successfully!')

        print(f'\n📊 Total rules loaded: {len(rc.rules) + len(rc2.rules)}')

        all_rules = list(rc.rules) + list(rc2.rules)
        for rule in all_rules:
            print(f'  - {rule.name}')
            print(f'    ID: {rule.id}')
            print(f'    Rule Type: {rule.contents.rule.type}')
            print(f'    Severity: {rule.contents.rule.severity}')
            print(f'    Risk Score: {rule.contents.rule.risk_score}')
            print()

        print("🎉 All custom rules validated successfully!")
        return True

    except Exception as e:
        print(f'❌ Rule validation failed: {e}')
        import traceback
        traceback.print_exc()
        return False

if __name__ == '__main__':
    validate_custom_rules()