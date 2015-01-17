docker-pentaho
==============

Pentaho BA Server is the world's leader Open Source Business Analytics server.
This docker container contains a standard Pentaho BA server distribution backed with
a PostgreSQL database instead of the demo HSQL database.

This distribution is based on the full fledged phusion/base-image distribution.

Usage
-----

To create the image execute the following command from the docker-pentaho folder:

	docker build --rm=true -t serasoft/docker-pentaho .

To run the image and bind the exposed ports run the following command:

	docker run -d -p 8080:8080 -p 5432:5432 serasoft/docker-pentaho
