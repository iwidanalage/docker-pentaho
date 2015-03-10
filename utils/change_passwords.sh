#!/bin/bash

set -e

if [ -f /.pentaho_dbpwd_changed ]; then
    echo "Pentaho BA Server database users' passwords already changed!"
    exit 0
fi

# Generate password
PASS=${DB_USERS_PASS:-$(pwgen -s 12 1)}
echo "=> Modifying jcr_user, hibusr and pentaho_usr passwords to ${PASS}"

cd /opt/pentaho/biserver-ce

sed -i 's/@@DB_PWD@@/'${PASS}'/g' `find ./data/${DB_TYPE} -name *.sql`
sed -i 's/@@DB_PWD@@/'${PASS}'/g' `find ./pentaho-solutions/system -name *.properties`
sed -i 's/@@DB_PWD@@/'${PASS}'/g' `find ./pentaho-solutions/system -name *.xml`
sed -i 's/@@DB_PWD@@/'${PASS}'/g' `find ./tomcat/webapps -name *.xml`

echo "Pentaho BA Server database users' passwords changed successfully!"
touch /.pentaho_dbpwd_changed   
