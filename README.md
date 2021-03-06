# Mongo Revive
This will aid in spinning up a new MongoDB instance using Docker Compose, setting up root and app users, and optionally restoring data to the app user database. This instance will have TLS enabled, although it will use a self-signed cert generated as part of building the image. The usage of version 3.2.6 and MongoDB options chosen are inspired by parse-server's recommendations.
## Prerequisites
Begin by installing [Docker](https://www.docker.com) or if you already have Docker but not Docker Compose (AKA CoreOS) see [this Gist](https://gist.github.com/marszall87/ee7c5ea6f6da9f8968dd).

## Usage
The primary usage of this project is first to clone this repo:
```
git clone https://github.com/okwolf/mongo-revive.git
```
Then change into the newly cloned repo and start the revive process:
```
cd mongo-revive && ./revive.sh
```
You'll be prompted for required values not already set in your environment:
```
Enter root password: @PasswordMoreS3cure3ThanThi5
Enter app database: dev
Enter app user name: app
Enter app user password: S3cur3AppPa55w0rd
Enter URL of backup/dump archive to restore (blank for none): https://blob.storage/some.database.archive
```
For reference here is a table of all available variables:

| Variable              | Required|Meaning|
| ----------------------|:-------:|-------|
| MONGO_ROOT_PASSWORD   | YES     | The root account will have super cow powers and the username of root, but it needs a secure password from you! |
| MONGO_APP_DB          | YES     | This database will exist with the below user and password as the owner. If you use a backup, make sure it's for the same db. |
| MONGO_APP_USER        | YES     | This user should be used for connecting your app to the db for its data. This user will have full ownership over this data, but no additional permissions. |
| MONGO_APP_PASSWORD    | YES     | Password for the application user above. |
| MONGO_ARCHIVE_URL     | NO      | URL to download archive from and restore to app db using app user and password set previously. To create an archive to use with this command, use the following type of command: `mongodump --gzip --archive=$(date +%F_%H-%M-%S).archive --host=database.url --ssl --db=dev --username=app --password=S3cur3AppPa55w0rd`. A special reserved value of `none` may be used for automatically bypassing this feature when automating running of Mongo Revive. |

Once this completes your MongoDB instance will be up and running (with your archived data if given). Authentication will be enabled with your secure passwords so it is now safe to open access to port 27017 from the outside world (firewall). You may now test connecting to your new MongoDB instance using a connection string like this:
```
mongodb://app:S3cur3AppPa55w0rd@database.url:27017/dev?ssl=true
```