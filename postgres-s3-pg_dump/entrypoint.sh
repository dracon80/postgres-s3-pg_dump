#!/bin/bash

# Check if PG_DB is defined
if [ -z "$PG_DB" ]; then
    echo "Error: PG_DB environment variable is not defined" >&2
    exit 1
fi
# Check if PG_HOST is defined
if [ -z "$PG_HOST" ]; then
    echo "Error: PG_HOST environment variable is not defined" >&2
    exit 1
fi
# Check if PG_USER is defined
if [ -z "$PG_USER" ]; then
    echo "Error: PG_USER environment variable is not defined" >&2
    exit 1
fi
# Set default value for PG_PORT if not defined
: ${PG_PORT:=5432}

#Confirm pgpass file exists and has correct permissions
pgpass_file="/backup/.pgpass"
if [ ! -f "$pgpass_file" ]; then
    echo "Error: File '$pgpass_file' does not exist." >&2
    exit 1
fi
# Check if the file is owned by the current user
if [ "$(stat -c '%U' "$pgpass_file")" != "$(whoami)" ]; then
    echo "Error: File '$pgpass_file' is not owned by the current user."
    exit 1
fi
# Check if the file is readable only by the owner
if [ $(stat -c %a "$pgpass_file") -ne 600 ]; then
    echo "Error: File '$pgpass_file' must have permissions of 0600 for user $(whoami)" >&2
    exit 1
fi

#Attempt to backup the database to a compressed custom archive
result=$(pg_dump -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" --no-password \
    --clean --if-exists --create --file "$PG_DB-backup" \
    --format=directory --jobs=2 --compress=0 2>&1)

exit_status=$?

# Check the exit status of pg_dump
if [ $exit_status -eq 0 ]; then
    echo "Database backup completed successfully."
else
    echo "Error: $result - code: $exit_status" >&2
    exit 1
fi

result=$(pg_dumpall -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" --no-password \
    --file "$PG_HOST-globals" --globals-only 2>&1)

exit_status=$?

# Check the exit status of pg_dump
if [ $exit_status -eq 0 ]; then
    echo "Globals backup completed successfully."
else
    echo "Error: $result - code: $exit_status" >&2
    exit 1
fi

#Tar and compress the files
tar -cz "$PG_DB-backup" "$PG_HOST-globals" | aespipe -P encrypt.key -e AES256 -C 10000 > "$PG_DB-backup.enc"
rm -rf "$PG_DB-backup" "$PG_HOST-globals"

#To Decrypt the encrypted file just run the following command.
#aespipe -d -P encrypt.key -e AES256 -C 10000 < backup.enc > backup.sql

#upload the file to S3
result=$(aws s3api put-object --bucket $AWS_BUCKET --key "$PG_DB-backup.enc" --body "$PG_DB-backup.enc" --tagging backup/schedule=$AWS_BACKUP_SCHEDULE_TAG 2>&1)

exit_status=$?

# Check the exit status of aws upload
if [ $exit_status -eq 0 ]; then
    echo "Encrypted backup successfully uploaded to S3 bucket - $AWS_BUCKET"
else
    echo "Error: $result - code: $exit_status" >&2
    exit 1
fi