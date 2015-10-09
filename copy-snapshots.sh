#!/bin/bash

region=${1-'us-east-1'}
to=${2-'us-west-2'}
me=$$

function get_backup_ids() {
  backups=$(aws ec2 describe-snapshots \
              --region $region \
              --filters Name=tag-key,Values=backup_id \
              --query 'Snapshots[].Tags[?Key==`backup_id`].Value' \
              --output text | sort | uniq)
  echo $backups | awk '{print $NF}'
}

function get_snapshots() {
  snapshots=$(aws ec2 describe-snapshots \
                --region $region \
                --filters Name=tag-key,Values=backup_id Name=tag-value,Values=$1 \
                --query 'Snapshots[].SnapshotId' \
                --output text)
  echo $snapshots
}

function get_last_backup() {
  echo $(get_backup_ids)
}

function copy_snapshot() {
  new_snap=$(aws ec2 copy-snapshot \
    --source-region $region \
    --source-snapshot-id $1 \
    --description "Copy of $snapshot ($backup_id) from $region" \
    --destination-region $to \
    --query 'SnapshotId' \
    --region $to \
    --output text)
  echo $new_snap
}

function poll() {
  while [ -p /tmp/.snapcopy_$1 ]; do
    aws ec2 describe-snapshots \
      --region $to \
      --snapshot-ids $1 \
      --query 'Snapshots[].State' \
      --output text > /tmp/.snapcopy_$1
    sleep 60
  done
}

function get_status() {
  aws ec2 describe-snapshots --snapshot-ids $1 --query 'Snapshots[].Progress' --region $to --output text
}

function set_backup_tag() {
  aws ec2 create-tags --resources $1 --tags Key=backup_id,Value=$backup_id --region $to
}

tasks=0
backup_id=$(get_last_backup)
echo "DEBUG: $backup_id"

for snapshot in $(get_snapshots $backup_id); do
  echo "DEBUG: source $snapshot"
  new_snap=$(copy_snapshot $snapshot)
  set_backup_tag $new_snap
  echo "DEBUG: dest $new_snap"
  mkfifo /tmp/.snapcopy_${new_snap}
  ( poll $new_snap ) &
  tasks=$[$tasks + 1]
  echo "DEBUG: Polling for $new_snap"

  while [ $tasks -eq 4 ]; do
    for fifo in /tmp/.snapcopy_* ; do 
      count=$(grep -c 'completed' $fifo)
      if [ $count -gt 0 ]; then
        echo "${fifo#/tmp/.snapcopy_} is completed.  Moving on."
        rm $fifo
        tasks=$[$tasks - 1]
      else
        echo "${fifo#/tmp/.snapcopy_} progress: $(get_status ${fifo#/tmp/.snapcopy_})"
      fi
    done
  sleep 20
  done
done
