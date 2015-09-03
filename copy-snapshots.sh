#!/bin/bash

region=${1-'us-east-1'}
to=${2-'us-west-2'}
me=$$

backup_id=$(aws ec2 describe-snapshots --region $region --filters Name=tag-key,Values=backup_id | \
       jq '.["Snapshots"][]."Tags"[] | select(.Key == "backup_id").Value' | sort | uniq | tr -d '"' | \
       tail -1 )

tasks=0
for snapshot in $(aws ec2 describe-snapshots --filters Name=tag-key,Values=backup_id Name=tag-value,Values=$backup_id --region us-east-1 | \
                  jq '.["Snapshots"][].SnapshotId' | tr -d '"') ; do
  new_snap=$(aws ec2 copy-snapshot --source-region $region --source-snapshot-id $snapshot --description \
             "Copy of $snapshot ($backup_id) from $region" --destination-region $to | jq '.SnapshotId' | tr -d '"')
  mkfifo /tmp/.snapcopy_$new_snap
  ( while [ -p /tmp/.snapcopy_$new_snap ]; do aws ec2 describe-snapshots --region $to --snapshot-ids $new_snap | jq '.Snapshots[].State' | tr -d '"' > /tmp/.snapcopy_$new_snap ; sleep 60 ; done ) &
  tasks=$[$tasks + 1]

  while [ $tasks -eq 4 ]; do
    for fifo in /tmp/.snapcopy_* ; do
      count=$(grep -c 'completed' $fifo)
      if [ $count -gt 0 ]; then
        echo "${fifo#/tmp/.snapcopy_} is completed.  Moving on."
        rm $fifo
        tasks=$[$tasks - 1]
      else
        echo "${fifo#/tmp/.snapcopy_} progress: $(aws ec2 describe-snapshots --snapshot-ids ${fifo#/tmp/.snapcopy_} | jq '.Snapshots[].Progress' | tr -d '\"')"
      fi
    done
    sleep 20
  done
done
