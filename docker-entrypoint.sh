#!/bin/bash

# Default cron schedule if not provided
CRON_SCHEDULE=${CRON_SCHEDULE:-"0 2 * * *"}

# Create cron job with the schedule
echo "$CRON_SCHEDULE /app/backup.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/backup-cron
chmod 0644 /etc/cron.d/backup-cron

# Start cron daemon
crond

# Follow the cron log
tail -f /var/log/cron.log 