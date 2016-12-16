import json
import boto3
from psycopg2 import connect
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT


"""  IAM policy:
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Sid": "Stmt1475849820226",
            "Action": [
                "rds:DescribeDBInstances"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:rds:*"
        },
        {
            "Action": [
                "ec2:CreateNetworkInterface"
            ],
            "Resource": [
                "*"
            ],
        "Effect": "Allow"
        }
    ]
}
"""

print('Loading function')

def lambda_handler(event, context):
  cfnMsgParams = {}
  print("Event received: " + json.dumps(event))
  for record in event['Records']:
    if 'Sns' in record:
      msg = record['Sns']['Message'].encode('ascii', 'replace')
      for line in str.split(msg, '\n'):
        if '=' not in line:
          continue
        key, value = str.split(line, '=')
        key = key.replace('\'', '')
        value = value.replace('\'', '')
        cfnMsgParams[key] = value

  if cfnMsgParams['ResourceStatus'] == 'CREATE_COMPLETE':
    region = str.split(cfnMsgParams['StackId'], ':')[3]

    if cfnMsgParams['ResourceType'] == 'AWS::RDS::DBInstance':

      # Construct the ARN of the RDS DB Instance
      arn = ':'.join(['arn', 'aws', 'rds', region, cfnMsgParams['Namespace'], 'db', cfnMsgParams['PhysicalResourceId']])

      # Snag Master Username & Password from CloudFormation notification message
      RDSResourceProperties = json.loads(cfnMsgParams['ResourceProperties'])
      master_pw = RDSResourceProperties['MasterUserPassword']
      master_un = RDSResourceProperties['MasterUsername']
      db_name   = RDSResourceProperties['DBName']

      try:
        # Use the IAM policy, above, to query AWS for the DBInstance Endpoint Address
        rds = boto3.client('rds')
        instance = rds.describe_db_instances(DBInstanceIdentifier = arn)['DBInstances'][0]
        host = instance['Endpoint']['Address']
      except:
        raise Exception('Could not query AWS for DBInstance Endpoint Address')

      for tag in RDSResourceProperties['Tags']:
        if tag['Key'] == 'AppPassword':
          app_pw = tag['Value']
        if tag['Key'] == 'AppUsername':
          app_un = tag['Value']

      try:
        pg = connect(user=master_un, host=host, password=master_pw, dbname=db_name)
        pg.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
      except:
        raise Exception('Could not connect to PostgreSQL at ' + host)

      cursor = pg.cursor()
      cursor.execute('select rolname from pg_roles where rolname = \'' + app_un + '\';');
      if len(cursor.fetchall()) > 0:
        print app_un + ' role already exists. Exiting.'
      else:
        try:
          cursor.execute('CREATE ROLE ' + app_un + ' WITH LOGIN PASSWORD \'' + app_pw + '\'')
          print 'Created role ' + app_un + ' with password ' + app_pw
        except:
          raise Exception('Could not create role ' + app_un)

      # Non-privileged users cannot create extensions.
      cursor.execute('CREATE EXTENSION "hstore";')
      cursor.execute('CREATE EXTENSION "uuid-ossp";')

      cursor.close()
      pg.close()
