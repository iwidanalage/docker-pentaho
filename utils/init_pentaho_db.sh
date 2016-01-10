#!/bin/bash

set -e

if [ -f /.pentaho_db_already_initialized ]; then
    echo "Pentaho BA Server PostgreSQL database already initialized!"
    exit 0
fi

DB_HOST=${PENTAHO_DB_PORT_5432_TCP_ADDR:-'localhost'}
DB_PORT=${PENTAHO_DB_PORT_5432_TCP_PORT:-5432}

echo "Referenced Postgres Host - Host: ${DB_HOST}, Port: ${DB_PORT}"

if [ ${DB_HOST} != 'localhost' ]; then
	echo "Generating .pgpass file to connect to Postgres Host"
	echo '${DB_HOST}:${DB_PORT}:*:postgres:${POSTGRES_PWD}' > /var/lib/postgresql/.pgpass
	chmod 600 /var/lib/postgresql/.pgpass
	chown postgres:postgres /var/lib/postgresql/.pgpass
fi

su - postgres -c "psql -f /opt/pentaho/biserver-ce/data/postgresql/create_repository_postgresql.sql"
su - postgres -c "psql -f /opt/pentaho/biserver-ce/data/postgresql/create_quartz_postgresql.sql"
su - postgres -c "psql -f /opt/pentaho/biserver-ce/data/postgresql/create_jcr_postgresql.sql" 
su - postgres -c "psql quartz -f /opt/pentaho/biserver-ce/data/postgresql/dummy_quartz_table.sql"

echo "Pentaho BA Server PostgreSQL database initialized successfully!"
touch /.pentaho_db_already_initialized
