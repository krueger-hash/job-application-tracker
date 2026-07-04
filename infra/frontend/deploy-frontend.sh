#!/usr/bin/env bash
#
# Builds the Vite/React frontend and deploys it to an environment's S3 +
# CloudFront (the FrontendBucket / Distribution created by infra/template.yaml).
#
# This is the MANUAL / emergency path. The normal path is GitHub Actions, which
# builds the artifact ONCE and promotes the same build through staging -> prod
# (see publish_main.yml / deploy_production.yml). This script rebuilds locally
# instead, so prefer CI for anything that actually ships.
#
# Usage:
#   ./deploy-frontend.sh staging        # or: production
#
# Requires: node + npm, awscli, and an AWS profile named per environment
# (override with PROFILE=... / REGION=...).

set -euo pipefail

ENVIRONMENT="${1:-}"
[ -z "$ENVIRONMENT" ] && read -rp "Environment to deploy (staging|production): " ENVIRONMENT

case "$ENVIRONMENT" in
  staging)    PROFILE="${PROFILE:-staging}" ;;
  production) PROFILE="${PROFILE:-production}" ;;
  *) echo "Environment must be 'staging' or 'production'." >&2; exit 1 ;;
esac
REGION="${REGION:-eu-central-1}"
APP_STACK="job-application-tracker-app-${ENVIRONMENT}"

# --- Resolve the upload targets from the stack's outputs (nothing hardcoded) ---
echo "Reading outputs from $APP_STACK ..."
read_output() {
  aws cloudformation describe-stacks \
    --stack-name "$APP_STACK" --profile "$PROFILE" --region "$REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" --output text
}
BUCKET="$(read_output FrontendBucketName)"
DIST_ID="$(read_output CloudFrontDistributionId)"
DOMAIN="$(read_output CloudFrontDomainName)"

if [ -z "$BUCKET" ] || [ "$BUCKET" = "None" ]; then
  echo "Could not resolve FrontendBucketName from $APP_STACK. Is the stack deployed?" >&2
  exit 1
fi

# Resolve the frontend dir relative to this script so it works from anywhere.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="$SCRIPT_DIR/../../frontend"

# --- Build ---
echo "Building frontend ..."
( cd "$FRONTEND_DIR" && npm ci && npm run build )

# --- Upload ---
# Vite emits content-hashed asset filenames, so those are safe to cache forever
# (immutable). index.html is the un-hashed entry point and MUST stay uncached so
# new deploys are picked up immediately.
echo "Uploading to s3://$BUCKET ..."
aws s3 sync "$FRONTEND_DIR/dist/" "s3://$BUCKET/" \
  --delete --profile "$PROFILE" --region "$REGION" \
  --cache-control "public,max-age=31536000,immutable" \
  --exclude index.html
aws s3 cp "$FRONTEND_DIR/dist/index.html" "s3://$BUCKET/index.html" \
  --profile "$PROFILE" --region "$REGION" \
  --cache-control "no-cache"

# --- Invalidate the CDN so viewers get the new index.html / assets at once ---
echo "Invalidating CloudFront ($DIST_ID) ..."
aws cloudfront create-invalidation \
  --distribution-id "$DIST_ID" --paths "/*" \
  --profile "$PROFILE" --region "$REGION" >/dev/null

echo
echo "Done. $ENVIRONMENT frontend deployed: $DOMAIN"
