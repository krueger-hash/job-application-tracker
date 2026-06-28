# creates base setup for aws
sam deploy \
   -t infra/base/template.yaml \
   --stack-name job-application-tracker-base-staging \
   --region eu-central-1 \
   --resolve-s3 \
   --capabilities CAPABILITY_IAM \
   --parameter-overrides Environment=staging \
   --profile staging

# powershell command
: <<'COMMENT'
sam deploy `
   -t base/template.yaml `
   --stack-name job-application-tracker-base-staging `
   --region eu-central-1 `
   --resolve-s3 `
   --capabilities CAPABILITY_IAM `
   --parameter-overrides Environment=staging `
   --profile staging
COMMENT