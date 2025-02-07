# PostgreSQL S3 Backup Docker Image

This Docker image provides automated PostgreSQL database backups to any S3-compatible storage (AWS S3, Cloudflare R2, MinIO, etc.).

## Features

- Daily and monthly backups
- Configurable backup schedule via cron
- Automatic cleanup of old daily backups
- Support for any S3-compatible storage

## Required Environment Variables

- `POSTGRES_HOST` - PostgreSQL host address
- `POSTGRES_USER` - PostgreSQL user
- `POSTGRES_PASSWORD` - PostgreSQL password
- `POSTGRES_DB` - PostgreSQL database name
- `S3_BUCKET` - S3 bucket name
- `S3_ACCESS_KEY` - S3 access key
- `S3_SECRET_KEY` - S3 secret key
- `S3_ENDPOINT` - S3 endpoint URL (e.g., `https://s3.amazonaws.com` for AWS)

## Optional Environment Variables

- `CRON_SCHEDULE` - Cron schedule for backups (default: "0 2 * * *" - 2 AM daily)
- `S3_PROVIDER` - S3 provider name (default: "AWS", other options: "Cloudflare", "Minio", etc.)

## Usage

### Docker Compose Example (AWS S3)

```yaml
version: '3.8'

services:
  backup:
    image: postgres-s3-backup
    environment:
      POSTGRES_HOST: db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: your_password
      POSTGRES_DB: your_database
      S3_BUCKET: your-bucket
      S3_ACCESS_KEY: your_access_key
      S3_SECRET_KEY: your_secret_key
      S3_ENDPOINT: https://s3.amazonaws.com
      CRON_SCHEDULE: "0 2 * * *"  # Optional: runs at 2 AM daily
    volumes:
      - backup-data:/backups

volumes:
  backup-data:
```

### Using with Cloudflare R2

To use with Cloudflare R2, set the following environment variables:

```yaml
    environment:
      # ... PostgreSQL settings ...
      S3_BUCKET: your-r2-bucket
      S3_ACCESS_KEY: your_r2_access_key
      S3_SECRET_KEY: your_r2_secret_key
      S3_ENDPOINT: https://xxx.r2.cloudflarestorage.com
      S3_PROVIDER: Cloudflare
```

## Backup Schedule

- Daily backups are stored in the `daily` folder in your S3 bucket
- Monthly backups (taken on the 1st of each month) are stored in the `monthly` folder
- The last 3 daily backups are kept locally

## Building the Image

```bash
docker build -t postgres-s3-backup .
```

## Supported S3-Compatible Services

The image has been tested with:
- Amazon S3
- Cloudflare R2
- MinIO

Other S3-compatible services should work as well by setting the appropriate endpoint and provider.