# creates base setup for localstack
samlocal deploy \
   -t infra/base/template.yaml \
   --stack-name job-application-tracker-base-staging \
   --region eu-central-1 \
   --resolve-s3 \
   --capabilities CAPABILITY_IAM \
   --parameter-overrides Environment=staging UseLocalStack=true

### powershell command
: <<'COMMENT'
samlocal deploy `
   -t infra/base/template.yaml `
   --stack-name job-application-tracker-base-staging `
   --region eu-central-1 `
   --resolve-s3 `
   --capabilities CAPABILITY_IAM `
   --parameter-overrides Environment=staging UseLocalStack=true`
COMMENT