FROM alpine:3.21

RUN apk add --no-cache bash postgresql-client rclone dcron

WORKDIR /app

COPY backup.sh /app/backup.sh
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/backup.sh /app/docker-entrypoint.sh

# Create backup directory
RUN mkdir -p /backups && \
    touch /var/log/cron.log

# Default environment variables
ENV CRON_SCHEDULE="0 2 * * *"

ENTRYPOINT ["/app/docker-entrypoint.sh"]
