#! /bin/sh

set -e
set -o pipefail

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

if [ -z "${POSTGRES_HOST}" ]; then
  echo "You need to set the POSTGRES_HOST environment variable."
  exit 1
fi

if [ -z "${POSTGRES_USER}" ]; then
  echo "You need to set the POSTGRES_USER environment variable."
  exit 1
fi

# set postgres variables, if not set
if echo "${POSTGRES_DB}" | grep -qs "[@,\ ]" ; then
  export PGDATABASE="${POSTGRES_USER:-postgres}"
else
  export PGDATABASE="${PGDATABASE:-${POSTGRES_DB}}"
fi
export PGHOST="${PGHOST:-${POSTGRES_HOST}}"
export PGPORT="${PGPORT:-${POSTGRES_PORT}}"
export PGUSER="${PGUSER:-${POSTGRES_USER}}"
export PGPASSWORD="${PGPASSWORD:-${POSTGRES_PASSWORD}}"
export PGOPTIONS="${PGOPTIONS:-${POSTGRES_OPTIONS}}"

if [ -n "${S3_ENDPOINT}" ]; then
  export AWS_ARGS="--endpoint-url ${S3_ENDPOINT}"
fi

# back up each database, if none were passed
if [ -z "${POSTGRES_DB}" ] ; then
  POSTGRES_DB=${PGDATABASE:-$(psql -t -A -c "SELECT datname FROM pg_database WHERE datistemplate IS FALSE")}
fi
if [ -z "${POSTGRES_DB}" ] ; then
  echo "Did not find any databases to back up."
  exit 2
fi

# perform backup
for PGDATABASE in ${POSTGRES_DB//,/ } ; do 
  export PGDATABASE
  pg_dump | gzip | aws ${AWS_ARGS} s3 cp - s3://${S3_BUCKET}/${S3_PATH}/${PGDATABASE}_$(date +"%Y-%m-%dT%H:%M:%SZ").sql.gz || exit 2
done

# date function is very limited in busybox
function duration2seconds () {
  COUNT=${1//[[:alpha:]]*}
  UNIT=${1##*[[:digit:]]}
  case "${UNIT}" in
    S)
      echo ${COUNT}
      ;;
    M)
      echo $((COUNT*60))
      ;;
    H)
      echo $((COUNT*60*60))
      ;;
    d)
      echo $((COUNT*60*60*24))
      ;;
    w)
      echo $((COUNT*60*60*24*7))
      ;;
    m)
      echo $((COUNT*60*60*24*30))
      ;;
    y)
      echo $((COUNT*60*60*24*30*365))
      ;;
    *)
      echo ${COUNT}
      ;;
    esac
}

# refuse to prune old backups if MAX_AGE is not set
if [ -z "${MAX_AGE}" ] ; then
  "You need to set the MAX_AGE environment variable."
  exit 2
fi

# prune old backups
MAX_AGE=$(duration2seconds ${MAX_AGE})
now=$(date +%s);
older_than=$((now-MAX_AGE))
aws s3 ls s3://${S3_BUCKET}/${S3_PATH}/ | grep -v " DIR " | while read date time size filename ; do 
  created=$(date -d "$date $time" +%s); 
  if [[ $created -lt $older_than ]] ; then 
    if [ -n "${filename}" ] ; then 
      aws s3 rm s3://${S3_BUCKET}/${S3_PATH}/${filename}
    fi
  fi
done
