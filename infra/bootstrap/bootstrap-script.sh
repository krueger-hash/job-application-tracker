#!/usr/bin/env bash
#
# Bootstraps the GitHub Actions OIDC provider + deploy role in BOTH accounts.
# Matches the job-application-tracker bootstrap template (params: GitHubRepo,
# Environment). Run once; idempotent (safe to re-run).
#
# Usage:
#   ./bootstrap.sh [owner/repo]
#   ./bootstrap.sh krueger-hash/job-application-tracker
#
# Override via env vars if needed:
#   STAGING_PROFILE (default: staging)   PROD_PROFILE (default: prod)
#   REGION (default: eu-central-1)       STACK_NAME (default: github-oidc)
#   ROLE_NAME (default: GitHubActionsDeploymentRole)

set -euo pipefail

# ---- Config (override via env vars) ----------------------------------------
STAGING_PROFILE="${STAGING_PROFILE:-staging}"
PROD_PROFILE="${PROD_PROFILE:-production}"
REGION="${REGION:-eu-central-1}"
STACK_NAME="${STACK_NAME:-github-oidc}"
ROLE_NAME="${ROLE_NAME:-GitHubActionsDeploymentRole}"   # must match RoleName in the template

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${TEMPLATE:-$SCRIPT_DIR/github-oidc.yaml}"

# repo defaults to the value baked into the template; override with arg 1
GITHUB_REPO="${1:-krueger-hash/job-application-tracker}"

# ---- Pretty output helpers -------------------------------------------------
info()  { printf '\033[0;34m▶ %s\033[0m\n' "$*"; }
ok()    { printf '\033[0;32m✓ %s\033[0m\n' "$*"; }
fail()  { printf '\033[0;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

# ---- Preflight -------------------------------------------------------------
command -v aws >/dev/null 2>&1 || fail "AWS CLI not found. Install it first."
[ -f "$TEMPLATE" ] || fail "Template not found at: $TEMPLATE (set TEMPLATE=... if it's named differently)"

check_auth() {
  local profile="$1"
  aws sts get-caller-identity --profile "$profile" --query Account --output text 2>/dev/null \
    || fail "Can't authenticate profile '$profile'. If you use SSO, run:  aws sso login --profile $profile"
}

info "Checking credentials for both profiles..."
STAGING_ACCT="$(check_auth "$STAGING_PROFILE")"
PROD_ACCT="$(check_auth "$PROD_PROFILE")"
ok "staging profile → account $STAGING_ACCT"
ok "prod profile    → account $PROD_ACCT"

[ "$STAGING_ACCT" = "$PROD_ACCT" ] && fail "Both profiles point at the SAME account ($STAGING_ACCT)."

# ---- Deploy helper (tolerates the 'No changes' non-zero exit) --------------
deploy_stack() {
  local profile="$1" env_value="$2"
  local output status
  set +e
  output="$(aws cloudformation deploy \
    --template-file "$TEMPLATE" \
    --stack-name "$STACK_NAME" \
    --capabilities CAPABILITY_NAMED_IAM \
    --region "$REGION" \
    --profile "$profile" \
    --parameter-overrides \
      "GitHubRepo=$GITHUB_REPO" \
      "Environment=$env_value" 2>&1)"
  status=$?
  set -e
  if [ $status -ne 0 ]; then
    if echo "$output" | grep -q "No changes to deploy"; then
      ok "Already up to date (no changes)."
    else
      printf '%s\n' "$output" >&2
      fail "Deploy failed for profile '$profile'."
    fi
  else
    ok "Stack deployed."
  fi
}

# IAM role ARNs are deterministic: arn:aws:iam::<account>:role/<RoleName>
STAGING_ROLE="arn:aws:iam::${STAGING_ACCT}:role/${ROLE_NAME}"
PROD_ROLE="arn:aws:iam::${PROD_ACCT}:role/${ROLE_NAME}"

# ---- Run it ----------------------------------------------------------------
echo
info "Bootstrapping PROD ($PROD_ACCT) — Environment=production"
deploy_stack "$PROD_PROFILE" "production"

echo
info "Bootstrapping STAGING ($STAGING_ACCT) — Environment=staging"
deploy_stack "$STAGING_PROFILE" "staging"



# ---- Report ----------------------------------------------------------------
echo
ok "Done. Add these as GitHub environment variables (Settings → Environments):"
echo
echo "  staging     → AWS_DEPLOY_ROLE_ARN = $STAGING_ROLE"
echo "  production  → AWS_DEPLOY_ROLE_ARN = $PROD_ROLE"
echo
echo "  Also set AWS_REGION = $REGION on both environments."