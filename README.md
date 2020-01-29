# postgres-backup-s3

Backup PostgresSQL to S3 (supports periodic backups)

## Usage

Docker:
```sh
$ docker run -e S3_ACCESS_KEY_ID=key -e S3_SECRET_ACCESS_KEY=secret -e S3_BUCKET=my-bucket -e S3_PATH=backup -e POSTGRES_DB=dbname -e POSTGRES_USER=user -e POSTGRES_PASSWORD=password -e POSTGRES_HOST=localhost treksler/postgres-backup-s3
```

Docker Compose:
```yaml
postgres:
  image: postgres
  environment:
    POSTGRES_DB: dbname
    POSTGRES_USER: user
    POSTGRES_PASSWORD: password

postgres-backup-s3:
  image: treksler/postgres-backup-s3
  environment:
    SCHEDULE: '@daily'
    MAX_AGE: 60d
    S3_REGION: us-west-2
    S3_ACCESS_KEY_ID: key
    S3_SECRET_ACCESS_KEY: secret
    S3_BUCKET: my-bucket
    S3_PATH: backup
    POSTGRES_DB: dbname
    POSTGRES_USER: user
    POSTGRES_PASSWORD: password
    POSTGRES_OPTIONS: '--schema=public --blobs'
```

### Automatic Periodic Backups

You can additionally set the `SCHEDULE` environment variable like `-e SCHEDULE="@daily"` to run the backup automatically.

More information about the scheduling can be found [here](http://godoc.org/github.com/robfig/cron#hdr-Predefined_schedules).

