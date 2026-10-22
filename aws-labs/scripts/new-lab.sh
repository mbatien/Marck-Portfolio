#!/usr/bin/env bash
# Create a new lab folder from the template.
# Usage: ./aws-labs/scripts/new-lab.sh <lab-name>
#   e.g. ./aws-labs/scripts/new-lab.sh rds-mysql-engine-upgrade
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <lab-name>" >&2
  exit 1
fi

name="$1"
if [[ ! "$name" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "Use lowercase letters, numbers and dashes only, e.g. s3-copy-local-file" >&2
  exit 1
fi

labs_dir="$(cd "$(dirname "$0")/.." && pwd)"
dir="$labs_dir/$name"

if [[ -e "$dir" ]]; then
  echo "$dir already exists" >&2
  exit 1
fi

mkdir -p "$dir"
title="$(echo "$name" | tr '-' ' ')"
sed -e "s/{{TITLE}}/${title^}/" -e "s/{{DATE}}/$(date +%Y-%m-%d)/" \
  "$labs_dir/templates/LAB_TEMPLATE.md" > "$dir/README.md"

cat > "$dir/commands.sh" <<'EOF'
#!/usr/bin/env bash
# AWS CLI commands used in this lab, in the order I ran them.
# Replace account IDs, usernames and keys with placeholders before committing.
EOF
chmod +x "$dir/commands.sh"

echo "Created $dir"
echo "Next: fill in README.md and commands.sh, then add a row to aws-labs/README.md"
