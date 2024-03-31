# Postgres S3 pg_dump Container

This is a simply docker image containing the aws-cli and pg_dump 16.2. It is designed to create a directory format pg_dump of a named database, along with a dump of the globals database. The backups are combined into a single TAR and encrupted using aespipe and a signle key.

## Configuration
To configure the image to communicat with the Database engine and Amazon S3 the following files and environment variables need to be supplied to the image.

### Environment Variables

| Variable Name             | Description |
| ---                       | ---         |
| AWS_ACCESS_KEY_ID         | An Amzon IAM user access key with permissions to put and tag objects in the S3 bucket
| AWS_SECRET_ACCESS_KEY     | The secret key for the IAM user
| AWS_DEFAULT_REGION        | The AWS region that the bucket is housed in
| AWS_BUCKET                | The name of the AWS bucket
| AWS_BACKUP_SCHEDULE_TAG   | The script will tag each upload with key of "backup/schedule" and a value matching this variable. You can use S3 lifecycle to manage how long each version is kept.
| PG_HOST                   | The Postgres Database Server hostname
| PG_DB                     | The Postgres Database that will be backed up
| PG_USER                   | The username that will be used to connect to postgres to perform the pg_dump

### pgpass

A .pgpass file must be mounted in the image as /backup/.pgpass . See [pgpass](https://www.postgresql.org/docs/16/libpq-pgpass.html) for more information on how to format and use this file to authenticate to postgresql.

### encrypt.key

[aespipe](https://linux.die.net/man/1/aespipe) is used to encrypt the final TAR of the backup files. aespipe requires a key to encrypt and decrypt the file.
The image expects to find a plaintext key located at /backup/encrypt.key in the image. This key is used to encrypt the files before uploading to AWS. Make sure you have a save record of the value stored in this file, as without it you will not be able to decrypt and restore your backup.