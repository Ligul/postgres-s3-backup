#!/bin/bash

set -e

# Check required environment variables
required_vars=(
    "POSTGRES_HOST"
    "POSTGRES_USER"
    "POSTGRES_PASSWORD"
    "POSTGRES_DB"
    "S3_BUCKET"
    "S3_ACCESS_KEY"
    "S3_SECRET_KEY"
    "S3_ENDPOINT"
)

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: Required environment variable $var is not set"
        exit 1
    fi
done

# Set Postgres password
export PGPASSWORD="$POSTGRES_PASSWORD"

# Configuration
BACKUP_DIR="/backups"
DAILY_REMOTE="$S3_BUCKET/daily"
MONTHLY_REMOTE="$S3_BUCKET/monthly"

DATE=$(date +"%Y-%m-%d")
DAY_OF_MONTH=$(date +"%d")
BACKUP_FILE="$BACKUP_DIR/backup_$DATE.sql"

# Select backup type
if [ "$DAY_OF_MONTH" -eq 1 ]; then
    BACKUP_TYPE="monthly"
else
    BACKUP_TYPE="daily"
fi

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Create backup
echo "Starting $BACKUP_TYPE backup: $BACKUP_FILE"
pg_dump -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" > "$BACKUP_FILE"
echo "$BACKUP_TYPE backup completed: $BACKUP_FILE"

# Set up rclone
if [ -f /root/.config/rclone/rclone.conf ]; then
    rm -f /root/.config/rclone/rclone.conf
fi

echo "Creating rclone configuration..."
mkdir -p /root/.config/rclone

# Set provider based on endpoint
S3_PROVIDER=${S3_PROVIDER:-"AWS"}  # Default to AWS if not specified

rclone config create s3 s3 \
    provider "$S3_PROVIDER" \
    access_key_id "$S3_ACCESS_KEY" \
    secret_access_key "$S3_SECRET_KEY" \
    endpoint "$S3_ENDPOINT" \
    region auto \
    --config /root/.config/rclone/rclone.conf \
    > /dev/null 2>&1 || { echo "Error creating rclone configuration."; exit 1; }

if [ -f /root/.config/rclone/rclone.conf ]; then
    echo "rclone configuration created successfully."
else
    echo "Error creating rclone configuration."
    exit 1
fi

# Upload backup to remote storage
if [ "$BACKUP_TYPE" == "monthly" ]; then
    echo "Uploading $BACKUP_TYPE backup to $MONTHLY_REMOTE"
    rclone copy "$BACKUP_FILE" "s3:$MONTHLY_REMOTE" -v
    echo "Monthly backup uploaded. Deleting local file."
    rm -f "$BACKUP_FILE"
else
    echo "Uploading $BACKUP_TYPE backup to $DAILY_REMOTE"
    rclone copy "$BACKUP_FILE" "s3:$DAILY_REMOTE" -v

    # Cleaning up old local daily backups
    echo "Cleaning up old local daily backups..."
    if [ $(ls "$BACKUP_DIR"/backup_*.sql 2>/dev/null | wc -l) -gt 3 ]; then
        ls -t "$BACKUP_DIR"/backup_*.sql | tail -n +4 | while read -r old_backup; do
            echo "Deleting $old_backup..."
            rm -f "$old_backup"
        done
    else
        echo "No old backups to delete."
    fi
fi

echo "Backup process completed successfully."