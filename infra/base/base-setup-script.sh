### Run from the root
#### Creates the base setup for staging and production aws environments.

# AWS BASE SETUP SETUP STAGING
### creates base setup for aws
sam deploy \
   -t infra/base/template.yaml \
   --stack-name job-application-tracker-base-staging \
   --region eu-central-1 \
   --resolve-s3 \
   --capabilities CAPABILITY_IAM \
   --parameter-overrides Environment=staging \
   --profile staging

### powershell command
: <<'COMMENT'
sam deploy `
   -t infra/base/template.yaml `
   --stack-name job-application-tracker-base-staging `
   --region eu-central-1 `
   --resolve-s3 `
   --capabilities CAPABILITY_IAM `
   --parameter-overrides Environment=staging `
   --profile staging
COMMENT

# AWS BASE SETUP SETUP PRODUCTION
### creates base setup for aws
sam deploy \
   -t infra/base/template.yaml \
   --stack-name job-application-tracker-base-production \
   --region eu-central-1 \
   --resolve-s3 \
   --capabilities CAPABILITY_IAM \
   --parameter-overrides Environment=production \
   --profile production

### powershell command
: <<'COMMENT'
sam deploy `
   -t infra/base/template.yaml `
   --stack-name job-application-tracker-base-production `
   --region eu-central-1 `
   --resolve-s3 `
   --capabilities CAPABILITY_IAM `
   --parameter-overrides Environment=production `
   --profile production
COMMENT