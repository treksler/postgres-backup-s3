FROM  alpine:3.10 AS downloader
LABEL maintainer="Risto Treksler <risto78@gmail.com>"
RUN   apk update \
      && apk add --no-cache \
          curl \
      && curl -L --insecure https://github.com/odise/go-cron/releases/download/v0.0.6/go-cron-linux.gz | zcat > /usr/local/bin/go-cron \
      && chmod u+x /usr/local/bin/go-cron
FROM  alpine:3.10
ENV   POSTGRES_DB='' \
      POSTGRES_DB_FILE='' \
      POSTGRES_HOST='postgres' \
      POSTGRES_PORT='5432' \
      POSTGRES_USER='postgres' \
      POSTGRES_USER_FILE='' \
      POSTGRES_PASSWORD='' \
      POSTGRES_PASSWORD_FILE='' \
      POSTGRES_OPTIONS='' \
      PGDATABASE='' \
      PGHOST='' \
      PGPORT='' \
      PGUSER='' \
      PGPASSWORD='' \
      PGOPTIONS='' \
      S3_ACCESS_KEY_ID='' \
      S3_SECRET_ACCESS_KEY='' \
      S3_DEFAULT_REGION='us-west-2' \
      S3_BUCKET='' \
      S3_PATH='backup' \
      S3_ENDPOINT='' \
      S3_S3V4='no' \
      SCHEDULE='' \
      MAX_AGE='10y'
RUN   apk update \
      && apk add --no-cache \
          postgresql \
          python3 \
          groff \
          less \
      && pip3 install --no-cache-dir --upgrade \
          pip \
          setuptools \
          wheel \
      && pip3 install --no-cache-dir \
          awscli

COPY --from=downloader /usr/local/bin/go-cron /usr/local/bin/
COPY bin/* /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["backup.sh"]
