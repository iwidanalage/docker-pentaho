#
# Serasoft's docker image for Pentaho Business Analytics
#
# VERSION	1.1
#

# Ideal solution is to change to devmapper for storage 
# Add the following line to /etc/docker/default
# DOCKER_OPTS="--storage-driver=devicemapper"
# then restart the docker service
# see here if you have existing containers you need to backup
# http://muehe.org/posts/switching-docker-from-aufs-to-devicemapper/

FROM serasoft/docker-base-jdk7
MAINTAINER Sergio Ramazzina, sergio.ramazzina@serasoft.it

# Set correct environment variables.
ENV HOME /root
ENV TOMCAT_HOME /opt/pentaho/biserver-ce/tomcat
ENV PENTAHO_HOME /opt/pentaho/biserver-ce
ENV BASE_REL 5.3
ENV REV 0.0-213
ENV DB_TYPE postgresql

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# =============================== Start Image Customization ===================

# Added workaround for AUFS bug as documented at the following URL
# https://github.com/docker/docker/issues/783#issuecomment-56013588
RUN echo "mkdir /etc/ssl/private-copy; mv /etc/ssl/private/* /etc/ssl/private-copy/; rm -r /etc/ssl/private; mv /etc/ssl/private-copy /etc/ssl/private; chmod -R 0700 /etc/ssl/private; chown -R postgres /etc/ssl/private" >> /etc/my_init.d/00_regen_ssh_host_keys.sh

# Make sure package repository is up to date before installing postgres as Pentaho's
# work database
RUN apt-get install -f -y curl git zip pwgen postgresql && \
# Fix DB codepage from SQL-ASCII to UTF8 as required by Pentaho
    /usr/bin/pg_dropcluster --stop 9.3 main && \
    /usr/bin/pg_createcluster --start -e UTF-8 9.3 main

# Configure Pentaho's databases
ADD v5/db/pg_hba.conf /etc/postgresql/9.3/main/pg_hba.conf
RUN chown postgres:postgres /etc/postgresql/9.3/main/pg_hba.conf

RUN useradd -m pentaho && \
    mkdir /opt/pentaho

ADD biserver-ce-$BASE_REL.$REV.zip /opt/pentaho/biserver-ce.zip

RUN chown -Rf pentaho:pentaho /opt/pentaho && \
#    su -c "curl -L http://sourceforge.net/projects/pentaho/files/Business%20Intelligence%20Server/${BASE_REL}/biserver-ce-${BASE_REL}.${REV}.zip/download -o /opt/pentaho/biserver-ce.zip" pentaho && \
    su -c "unzip -q /opt/pentaho/biserver-ce.zip -d /opt/pentaho/" pentaho && \
    rm /opt/pentaho/biserver-ce/promptuser.sh && \
    rm /opt/pentaho/biserver-ce.zip && \
    # Disable daemon mode for Tomcat
    sed -i -e 's/\(exec ".*"\) start/\1 run/' /opt/pentaho/biserver-ce/tomcat/bin/startup.sh

# Change password in script files
ADD utils/change_passwords.sh /opt/pentaho/biserver-ce/utils/change_passwords.sh 
ADD v5/db/${DB_TYPE}/create_jcr_${DB_TYPE}.sql /opt/pentaho/biserver-ce/data/${DB_TYPE}/create_jcr_${DB_TYPE}.sql
ADD v5/db/${DB_TYPE}/create_quartz_${DB_TYPE}.sql /opt/pentaho/biserver-ce/data/${DB_TYPE}/create_quartz_${DB_TYPE}.sql
ADD v5/db/${DB_TYPE}/create_repository_${DB_TYPE}.sql /opt/pentaho/biserver-ce/data/${DB_TYPE}/create_repository_${DB_TYPE}.sql

ADD v5/pentaho/system/${DB_TYPE}/applicationContext-spring-security-hibernate.properties /opt/pentaho/biserver-ce/pentaho-solutions/system/applicationContext-spring-security-hibernate.properties
ADD v5/pentaho/system/${DB_TYPE}/hibernate-settings.xml /opt/pentaho/biserver-ce/pentaho-solutions/system/hibernate/hibernate-settings.xml
ADD v5/pentaho/system/${DB_TYPE}/quartz.properties /opt/pentaho/biserver-ce/pentaho-solutions/system/quartz/quartz.properties
ADD v5/pentaho/system/${DB_TYPE}/repository.xml /opt/pentaho/biserver-ce/pentaho-solutions/system/jackrabbit/repository.xml
ADD v5/pentaho/system/${DB_TYPE}/postgresql.hibernate.cfg.xml /opt/pentaho/biserver-ce/pentaho-solutions/system/hibernate/postgresql.hibernate.cfg.xml

ADD v5/tomcat/${DB_TYPE}/context.xml /opt/pentaho/biserver-ce/tomcat/webapps/pentaho/META-INF/context.xml
ADD v5/tomcat/web.xml /opt/pentaho/biserver-ce/tomcat/webapps/pentaho/WEB-INF/web.xml

# Set password to generated value
RUN /opt/pentaho/biserver-ce/utils/change_passwords.sh

# Configure Pentaho to use Postgres Instance as metadata repository for BA system
ADD ./v5/db/dummy_quartz_table.sql /opt/pentaho/biserver-ce/data/postgresql/dummy_quartz_table.sql

RUN /etc/init.d/postgresql restart && \ 
    su postgres -c "psql -f /opt/pentaho/biserver-ce/data/postgresql/create_repository_postgresql.sql" && \
    su postgres -c "psql -f /opt/pentaho/biserver-ce/data/postgresql/create_quartz_postgresql.sql" && \
    su postgres -c "psql -f /opt/pentaho/biserver-ce/data/postgresql/create_jcr_postgresql.sql" && \
    su postgres -c "psql quartz -f /opt/pentaho/biserver-ce/data/postgresql/dummy_quartz_table.sql"

# RUN chown pentaho:pentaho -Rf /opt/pentaho

# RUN mkdir /etc/my_init.d
ADD 01_start_postgresql.sh /etc/my_init.d/01_start_postgresql.sh

RUN chmod +x /etc/my_init.d/01_start_postgresql.sh && \
     mkdir /etc/service/pentaho

ADD run /etc/service/pentaho/run
RUN chmod +x /etc/service/pentaho/run

# Expose Pentaho and PostgreSQL ports
EXPOSE 8080 5432


# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
