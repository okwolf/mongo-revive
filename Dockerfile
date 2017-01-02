FROM mongo:3.2.6

RUN apt-get update && apt-get install -y openssl wget ca-certificates
RUN openssl req -newkey rsa:2048 -new -x509 -days 365 -subj "/C=US/ST=Denial/L=Anytown/O=Evil Corp/CN=www.example.com" \
-nodes -out /etc/ssl/certs/mongodb.crt -keyout /etc/ssl/private/mongodb.key
RUN cat /etc/ssl/private/mongodb.key /etc/ssl/certs/mongodb.crt > /etc/ssl/mongodb.pem