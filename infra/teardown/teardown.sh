#!/usr/bin/env bash
#
# Tears down an environment's app + base stacks to pause costs (~$0).
# Leaves the OIDC bootstrap stack intact (it's free and needed to redeploy).
#
# Usage:
#   ./teardown.sh production      # or: staging
#
# WARNING: the base stack contains RDS with DeletionPolicy: Delete, so the
# DATABASE AND ALL ITS DATA ARE DELETED. Fine for testing environments;
# change the DeletionPolicy to Snapshot first if you need to keep the data.

set -euo pipefail

ENVIRONMENT="${1:-}"
[ -z "$ENVIRONMENT" ] && read -rp "Environment to tear down (staging|production): " ENVIRONMENT

case "$ENVIRONMENT" in
  staging)    PROFILE="${PROFILE:-staging}" ;;
  production) PROFILE="${PROFILE:-production}" ;;
  *) echo "Environment must be 'staging' or 'production'." >&2; exit 1 ;;
esac
REGION="${REGION:-eu-central-1}"
APP_STACK="job-application-tracker-app-${ENVIRONMENT}"
BASE_STACK="job-application-tracker-base-${ENVIRONMENT}"

echo "About to DELETE in profile '$PROFILE' ($REGION):"
echo "  - $APP_STACK   (Lambda + API)"
echo "  - $BASE_STACK  (VPC + RDS — DATABASE AND ALL DATA WILL BE LOST)"
echo "  (the free OIDC bootstrap stack is left intact)"
read -rp "Type '$ENVIRONMENT' to confirm: " CONFIRM
[ "$CONFIRM" != "$ENVIRONMENT" ] && { echo "Aborted."; exit 1; }

delete_stack() {
  local name="$1"
  if aws cloudformation describe-stacks --stack-name "$name" --profile "$PROFILE" --region "$REGION" >/dev/null 2>&1; then
    echo "Deleting $name ..."
    aws cloudformation delete-stack --stack-name "$name" --profile "$PROFILE" --region "$REGION"
    echo "  waiting for deletion to finish (RDS + VPC ENIs can take several minutes) ..."
    aws cloudformation wait stack-delete-complete --stack-name "$name" --profile "$PROFILE" --region "$REGION"
    echo "  done: $name deleted"
  else
    echo "  ($name not found — skipping)"
  fi
}

# App first (it imports the base stack's exports), then base.
delete_stack "$APP_STACK"
delete_stack "$BASE_STACK"

echo
echo "$ENVIRONMENT is torn down. Only the free OIDC bootstrap remains, so cost is ~\$0."