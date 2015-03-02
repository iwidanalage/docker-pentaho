#!/bin/bash

set -e

if [ -f /.pentaho_dbpwd_changed ]; then
    echo "Pentaho BA Server database users' passwords already changed!"
    exit 0
fi

# Generate password
PASS=${DB_USERS_PASS:-$(pwgen -s 12 1)}
echo $PASS
echo "=> Modifying jcr_user, hibusr and pentaho_usr passwords to ${PASS}"
./set_new_db_password.sh $PASS

echo "Pentaho BA Server database users' passwords changed successfully!"
touch /.pentaho_dbpwd_changed   
