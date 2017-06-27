#!/bin/bash

function get_backup_ids() {
  backups=$(aws ec2 describe-snapshots \
              --region $from \
              --filters Name=tag-key,Values=backup_id \
              --query 'Snapshots[].Tags[?Key==`backup_id`].Value' \
              --output text | sort | uniq)
  echo $backups
}

function get_snapshots() {
  snapshots=$(aws ec2 describe-snapshots \
                --region $from \
                --filters Name=tag-key,Values=backup_id Name=tag-value,Values=$1 \
                --query 'Snapshots[].SnapshotId' \
                --output text)
  echo $snapshots
}

function get_last_backup() {
  echo $(get_backup_ids) | awk '{print $NF}'
}

function copy_snapshot() {
  new_snap=$(aws ec2 copy-snapshot \
    --source-region $from \
    --source-snapshot-id $1 \
    --description "Copy of $snapshot ($backup_id) from $from" \
    --destination-region $to \
    --query 'SnapshotId' \
    --region $to \
    --output text )
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

function usage() {
  echo
  echo "Usage: snapshots.sh -f from [-t to] [(-l|-c)]"
  echo "       -f from = region to copy (or list) snapshots from"
  echo "       -t to   = region to copy snaphots to"
  echo "       -l      = list snapshots only"
  echo "       -L      = show last backup ID only"
  echo "       -c      = copy snapshots"
  echo
}

copy=0
last=0

while getopts ":f:t:lLc" opt; do
  case $opt in
    f)
      from=$OPTARG
    ;;
    t)
      to=$OPTARG
    ;;
    c)
      copy=1
    ;;
    l)
      copy=0
    ;;
    L)
      last=1
    ;;
    \?)
      echo "Unknown argument -$OPTARG"
      usage
      exit 0;
    ;;
    :)
      echo "Option -$OPTARG needs a parameter"
      usage
      exit 0;
    ;;
  esac
done

from=${from:=$AWS_DEFAULT_REGION}
to=${to:=$AWS_DEFAULT_REGION}

# Copy mode
if (( $copy > 0 )); then
  tasks=0
  backup_id=$(get_last_backup)

  for snapshot in $(get_snapshots $backup_id); do
    new_snap=$(copy_snapshot $snapshot)
    set_backup_tag $new_snap
    mkfifo /tmp/.snapcopy_${new_snap}
    ( poll $new_snap ) &
    tasks=$[$tasks + 1]

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

# List mode
else
  # Machine readable mode
  if (( $last > 0)); then
    echo $(get_last_backup)

  # Human readable mode
  else
    echo "Backup IDs:"
    for id in $(get_backup_ids); do
      printf '%38s %15s\n' "" $id
    done
    echo
    last=$(get_last_backup)
    echo "Snapshots in last backup ($last):"
    for snap in $(get_snapshots $last); do
      printf '%38s %15s\n' "" $snap
    done
  fi
fi
