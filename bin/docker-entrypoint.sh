#! /bin/sh

set -e

# read values from file, if available
if [ -f "${POSTGRES_DB_FILE}" ] ; then
  export POSTGRES_DB="$(cat ${POSTGRES_DB_FILE})"
fi
if [ -f "${POSTGRES_USER_FILE}" ] ; then
  export POSTGRES_USER="$(cat ${POSTGRES_USER_FILE})"
fi
if [ -f "${POSTGRES_PASSWORD_FILE}" ] ; then
  export POSTGRES_PASSWORD="$(cat ${POSTGRES_PASSWORD_FILE})"
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

# set postgres variables, if not set
export PGDATABASE="${PGDATABASE:-${POSTGRES_DB}}"
export PGHOST="${PGHOST:-${POSTGRES_HOST}}"
export PGPORT="${PGPORT:-${POSTGRES_PORT}}"
export PGUSER="${PGUSER:-${POSTGRES_USER}}"
export PGPASSWORD="${PGPASSWORD:-${POSTGRES_PASSWORD}}"
export PGOPTIONS="${PGOPTIONS:-${POSTGRES_OPTIONS}}"

# write postgres configuration to file
#echo "${POSTGRES_HOST}:${POSTGRES_PORT}:*:${POSTGRES_USER}:${POSTGRES_PASSWORD}" >> ~/.pgpass
#chmod 0600 ~/.pgpass

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
