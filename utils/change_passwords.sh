#!/bin/bash

set -e

if [ -f /.pentaho_dbpwd_changed ]; then
    echo "Pentaho BA Server database users' passwords already changed!"
    exit 0
fi

# Generate password
PASS=${DB_USERS_PASS:-$(pwgen -s 12 1)}
echo "=> Modifying jcr_user, hibusr and pentaho_usr passwords to ${PASS}"

sed -i 's/@@DB_PWD@@/${PASS}/g' `find . -name /opt/pentaho/biserver-ce/data/${DB_TYPE}/*.sql`
sed -i 's/@@DB_PWD@@/${PASS}/g' `find . -name /opt/pentaho/biserver-ce/system/*.properties`
sed -i 's/@@DB_PWD@@/${PASS}/g' `find . -name /opt/pentaho/biserver-ce/system/*.xml`
sed -i 's/@@DB_PWD@@/${PASS}/g' `find . -name /opt/pentaho/biserver-ce/tomcat/webapps/*.xml`

echo "Pentaho BA Server database users' passwords changed successfully!"
touch /.pentaho_dbpwd_changed   
