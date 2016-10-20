Files
-----

- rds_create_role.py: the lambda function, which must be included in a zip file containing psycopg2 compiled with the libpq library statically compiled in.
- create_deployment_package.sh: creates a zip file containing psycopg2 with ssl support and libpq.  Requires AWS credentials.
