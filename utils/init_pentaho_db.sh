#!/bin/bash

set -e

if [ -f /.pentaho_db_already_initialized ]; then
    echo "Pentaho BA Server PostgreSQL database already initialized!"
    exit 0
fi

su - postgres -c "psql -f /opt/pentaho/biserver-ce/data/postgresql/create_repository_postgresql.sql"
su - postgres -c "psql -f /opt/pentaho/biserver-ce/data/postgresql/create_quartz_postgresql.sql"
su - postgres -c "psql -f /opt/pentaho/biserver-ce/data/postgresql/create_jcr_postgresql.sql" 
su - postgres -c "psql quartz -f /opt/pentaho/biserver-ce/data/postgresql/dummy_quartz_table.sql"

echo "Pentaho BA Server PostgreSQL database initialized successfully!"
touch /.pentaho_db_already_initialized
