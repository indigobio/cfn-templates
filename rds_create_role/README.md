Files
-----

rds_create_role.py - the lambda function, which must be included in a zip file containing psycopg2 compiled with the libpq library statically compiled in.
create_deployment_package.sh - creates a zip file containing psycopg2 and libpq
rds_create_role.zip - a completed deployment package for your AWS lambda.

To add the lambda function to the deployment package:

    zip -f rds_create_role.zip rds_create_role.py
