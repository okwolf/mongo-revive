waitForMongo() {
  for i in `seq 1 30`
  do
    # Simpliest Mongo command I could find for testing if available
    if docker-compose exec mongo mongo --eval 'db.runCommand( { ping: 1 } )' > /dev/null ; then
      break
    else
      echo -n '.'
      sleep 1
    fi
  done
}

[ -n "$ROOT_PASSWORD" ] || read -p "Enter root password: " ROOT_PASSWORD
[ -n "$APP_DB" ] || read -p "Enter app database: " APP_DB
[ -n "$APP_USER" ] || read -p "Enter app user name: " APP_USER
[ -n "$APP_PASSWORD" ] || read -p "Enter app user password: " APP_PASSWORD
[ -n "$BACKUP_URL" ] || read -p "Enter URL of backup/dump archive to restore: " BACKUP_URL

# Cleanup any existing containers
docker-compose down
# Build the latest
docker-compose build
# Start Mongo in setup configuration, no auth
docker-compose -f setup.yml up -d
# Wait until we're able to connect to Mongo
waitForMongo

# Create root user
docker-compose exec mongo mongo admin --eval "$(cat <<EOF
db.createUser({
  user: "root",
  pwd: "$ROOT_PASSWORD",
  roles: [ "root" ]
});
EOF
)"
# Create application user
docker-compose exec mongo mongo $APP_DB --eval "$(cat <<EOF
db.createUser({
  user: "$APP_USER",
  pwd: "$APP_PASSWORD",
  roles: [ { role: "dbOwner", db: "$APP_DB" } ]
});
EOF
)"

# Restart Mongo in production
# Auth will be enabled now
docker-compose stop
./run.sh
waitForMongo

# Download backup archive into /data folder on container
docker-compose exec mongo wget -P /data $BACKUP_URL
# Restore data as our application user from the archive
# Also verifies that application user is able to connect in the processs
docker-compose exec mongo sh -c 'mongorestore --gzip --archive=$(ls /data/*.archive) --drop '"--db=$APP_DB -u=$APP_USER -p=$APP_PASSWORD"