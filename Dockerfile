#
# Serasoft's docker image for Pentaho Business Analytics
#
# VERSION	1.0
#

FROM sramazzina/docker-base-jdk7
MAINTAINER Sergio Ramazzina, sergio.ramazzina@serasoft.it

# Set correct environment variables.
ENV HOME /root
ENV TOMCAT_HOME /opt/pentaho/biserver-ce/tomcat
ENV PENTAHO_HOME /opt/pentaho/biserver-ce
ENV REL 5.2.0.0-209

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# Make sure package repository is up to date
RUN apt-get install -f -y curl git zip pwgen postgresql && \
# Fix DB codepage from SQL-ASCII to UTF8 as required by Pentaho
    /usr/bin/pg_dropcluster --stop 9.3 main && \
    /usr/bin/pg_createcluster --start -e UTF-8 9.3 main

# ADD biserver-ce-${REL}.zip /opt/pentaho/biserver-ce.zip
# Configure Pentaho's databases
ADD v5/db/pg_hba.conf /etc/postgresql/9.3/main/pg_hba.conf
RUN chown postgres:postgres /etc/postgresql/9.3/main/pg_hba.conf

RUN useradd -m pentaho && \
    mkdir /opt/pentaho && \
    chown pentaho:pentaho /opt/pentaho && \
    su -c "curl -L http://sourceforge.net/projects/pentaho/files/Business%20Intelligence%20Server/5.2/biserver-ce-${REL}.zip/download -o /opt/pentaho/biserver-ce.zip" pentaho && \
    su -c "unzip -q /opt/pentaho/biserver-ce.zip -d /opt/pentaho/" pentaho && \
    rm /opt/pentaho/biserver-ce/promptuser.sh && \
    rm /opt/pentaho/biserver-ce.zip && \
    # Disable daemon mode for Tomcat
    sed -i -e 's/\(exec ".*"\) start/\1 run/' /opt/pentaho/biserver-ce/tomcat/bin/startup.sh

# Configure Pentaho to use Postgres Instance as metadata repository for BA system
ADD ./v5/db/dummy_quartz_table.sql /opt/pentaho/biserver-ce/data/postgresql/dummy_quartz_table.sql

RUN /etc/init.d/postgresql restart && \ 
    su postgres -c "psql -f /opt/pentaho/biserver-ce/data/postgresql/create_repository_postgresql.sql" && \
    su postgres -c "psql -f /opt/pentaho/biserver-ce/data/postgresql/create_quartz_postgresql.sql" && \
    su postgres -c "psql -f /opt/pentaho/biserver-ce/data/postgresql/create_jcr_postgresql.sql" && \
    su postgres -c "psql quartz -f /opt/pentaho/biserver-ce/data/postgresql/dummy_quartz_table.sql"

# Update pentaho configuration files to have the system to work with the selected database
ADD v5/pentaho/system/applicationContext-spring-security-hibernate.properties /opt/pentaho/biserver-ce/pentaho-solutions/system/applicationContext-spring-security-hibernate.properties
ADD v5/pentaho/system/hibernate-settings.xml /opt/pentaho/biserver-ce/pentaho-solutions/system/hibernate/hibernate-settings.xml
ADD v5/pentaho/system/quartz.properties /opt/pentaho/biserver-ce/pentaho-solutions/system/quartz/quartz.properties
ADD v5/pentaho/system/repository.xml /opt/pentaho/biserver-ce/pentaho-solutions/system/jackrabbit/repository.xml
ADD v5/tomcat/context.xml /opt/pentaho/biserver-ce/tomcat/webapps/pentaho/META-INF/context.xml
ADD v5/tomcat/web.xml /opt/pentaho/biserver-ce/tomcat/webapps/pentaho/WEB-INF/web.xml

RUN chown pentaho:pentaho -Rf /opt/pentaho

# RUN mkdir /etc/my_init.d
ADD 01_start_postgresql.sh /etc/my_init.d/01_start_postgresql.sh

RUN chmod +x /etc/my_init.d/01_start_postgresql.sh && \
     mkdir /etc/service/pentaho

ADD run /etc/service/pentaho/run
RUN chmod +x /etc/service/pentaho/run

EXPOSE 8080 5432


# Clean up APT when done.
# RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
