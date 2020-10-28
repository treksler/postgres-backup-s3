#! /bin/sh

set -e

if [ -z "${S3_ACCESS_KEY_ID}" ]; then
  echo "You need to set the S3_ACCESS_KEY_ID environment variable."
  exit 1
fi

if [ -z "${S3_SECRET_ACCESS_KEY}" ]; then
  echo "You need to set the S3_SECRET_ACCESS_KEY environment variable."
  exit 1
fi

if [ -z "${S3_BUCKET}" ]; then
  echo "You need to set the S3_BUCKET environment variable."
  exit 1
fi

# write aws configuration to file
if [ "${S3_S3V4}" == "yes" ]; then
  aws configure set default.s3.signature_version s3v4
fi

if [ -n "${S3_ACCESS_KEY_ID}" ]; then
  aws configure set aws_access_key_id ${S3_ACCESS_KEY_ID}
fi

if [ -n "${S3_SECRET_ACCESS_KEY}" ]; then
  aws configure set aws_secret_access_key ${S3_SECRET_ACCESS_KEY}
fi

if [ -n "${S3_DEFAULT_REGION}" ]; then
  aws configure set region ${S3_DEFAULT_REGION}
fi

# run backup.sh, if no command was passed
if [ -z "$@" ] ; then
  set -- /bin/sh /usr/local/bin/backup.sh
fi

# run on a schedule, if specified
if [ -n "${SCHEDULE}" ]; then
  set -- /usr/local/bin/go-cron "$SCHEDULE" "$@"
fi

# run command
exec "$@"
