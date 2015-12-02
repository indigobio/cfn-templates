import boto3
import datetime
import re

SOURCE_REGION = 'us-east-1'
SOURCE_DB = 'indigo-qa2-nexus'
KEEP = 4

print('Loading function')

def bySnapshotId(snap):
  return snap['DBSnapshotIdentifier']

def byTimestamp(snap):
  return datetime.datetime.isoformat(snap['SnapshotCreateTime'])

def lambda_handler(event, context):
  source = boto3.client('rds', region_name=SOURCE_REGION)
  source_snaps = source.describe_db_snapshots(SnapshotType='automated', DBInstanceIdentifier=SOURCE_DB)['DBSnapshots']
  source_snap = sorted(source_snaps, key=bySnapshotId, reverse=True)[0]['DBSnapshotIdentifier']
  source_snap_arn = 'arn:aws:rds:%s:%s:snapshot:%s' % (SOURCE_REGION, event['account'], source_snap)
  target_snap_id = 'copy-of-%s' % (re.sub('rds:', '', source_snap))
  print('Will Copy %s to %s' % (source_snap_arn, target_snap_id))

  target = boto3.client('rds', region_name=event['region'])
  try:
    response = target.copy_db_snapshot(
      SourceDBSnapshotIdentifier=source_snap_arn,
      TargetDBSnapshotIdentifier=target_snap_id,
      CopyTags = False)
    print(response)
  except:
    raise Exception("Could not issue copy command.")

  copied_snaps = target.describe_db_snapshots(SnapshotType='manual', DBInstanceIdentifier=SOURCE_DB)['DBSnapshots']
  for snap in sorted(copied_snaps, key=byTimestamp, reverse=True)[KEEP:]:
    print('Will remove %s') % (snap['DBSnapshotIdentifier'])
    try:
      target.delete_db_snapshot(DBSnapshotIdentifier=snap['DBSnapshotIdentifier'])
    except:
      raise Exception("Could not delete snapshot " + snap['DBSnapshotIdentifier'])
      