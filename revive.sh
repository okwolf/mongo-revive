waitForMongo() {
  mongoStarted=false
  for i in `seq 1 30`
  do
    # Simpliest Mongo command I could find for testing if available
    if docker-compose exec mongo mongo --eval 'db.runCommand( { ping: 1 } )' &> /dev/null ; then
      mongoStarted=true
      break
    else
      echo -n '.'
      sleep 1
    fi
  done
  if [ "$mongoStarted" = false ]; then
    echo
    echo "$(tput setaf 1)Mongo couldn't start!$(tput sgr0)"
    exit 1
  fi
}

[[ $MONGO_ROOT_PASSWORD ]] || read -p "Enter root password: " MONGO_ROOT_PASSWORD
[[ $MONGO_APP_DB ]] || read -p "Enter app database: " MONGO_APP_DB
[[ $MONGO_APP_USER ]] || read -p "Enter app user name: " MONGO_APP_USER
[[ $MONGO_APP_PASSWORD ]] || read -p "Enter app user password: " MONGO_APP_PASSWORD
[[ $MONGO_ARCHIVE_URL ]] || read -p "Enter URL of backup/dump archive to restore (blank for none): " MONGO_ARCHIVE_URL

if docker-compose exec mongo mongo --eval 'db.runCommand( { ping: 1 } )' &> /dev/null ; then
  # Cleanup any existing containers
  docker-compose down
fi

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
  pwd: "$MONGO_ROOT_PASSWORD",
  roles: [ "root" ]
});
EOF
)"
# Create application user
docker-compose exec mongo mongo $MONGO_APP_DB --eval "$(cat <<EOF
db.createUser({
  user: "$MONGO_APP_USER",
  pwd: "$MONGO_APP_PASSWORD",
  roles: [ { role: "dbOwner", db: "$MONGO_APP_DB" } ]
});
EOF
)"

# Restart Mongo in production
# Auth will be enabled now
docker-compose stop
./run.sh

if [[ $MONGO_ARCHIVE_URL ]] && [[ $MONGO_ARCHIVE_URL != none ]] ; then
  waitForMongo
  # Download backup archive into /data folder on container
  docker-compose exec mongo wget -P /data $MONGO_ARCHIVE_URL
  # Restore data as our application user from the archive
  # Also verifies that application user is able to connect in the processs
  docker-compose exec mongo sh -c 'mongorestore --gzip --archive=$(ls /data/*.archive) --drop '"--db=$MONGO_APP_DB --username=$MONGO_APP_USER --password=$MONGO_APP_PASSWORD"
fi
