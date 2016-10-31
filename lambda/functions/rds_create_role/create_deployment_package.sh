#!/usr/bin/env bash

stamp="temp-$(date +'%Y%m%d%H%M%S')$$"
declare -a things

function cleanup {
  # things will have 0 - 3 elements, in this order:
  # instance ID, security group ID, key pair, or nothing
  if [ ${#things[@]} -eq 3 ]; then
    myinst=${things[2]}
    aws ec2 terminate-instances --instance-id $myinst &> /dev/null
    echo -n "Waiting on $myinst to be terminated."
    while test $(aws ec2 describe-instances --instance-id $myinst --query 'Reservations[0].Instances[0].State.Name' --output text) != 'terminated'; do
      echo -n "."
    sleep 10
    done
    echo
    unset things[2]
    things=( "${things[@]}" )
  fi

  if [ ${#things[@]} -eq 2 ]; then
    mysg=${things[1]}
    echo "Deleting $mysg security group"
    aws ec2 delete-security-group --group-id $mysg
    unset things[1]
    things=( "${things[@]}" )
  fi

  if [ ${#things[@]} -eq 1 ]; then
    keypair=${things[0]}
    echo "Deleting $keypair keypair"
    aws ec2 delete-key-pair --key-name $keypair
  fi

  if [ -f ${stamp}-rsa ]; then
    echo "Removing ${stamp}-rsa file."
    rm ${stamp}-rsa
  fi

  exit 0
}

trap cleanup $things SIGINT SIGTERM SIGHUP

echo "Creating temporary key pair for ssh."
aws ec2 create-key-pair --key-name $stamp --query 'KeyMaterial' --output text > ${stamp}-rsa && things[${#things[@]}]=$stamp
chmod go-rwx ${stamp}-rsa

myvpc=$(aws ec2 describe-vpcs --filters 'Name=isDefault,Values=true' --query 'Vpcs[0].VpcId')
myvpc=$(eval echo $myvpc)

mysg=$(aws ec2 create-security-group --group-name $stamp --vpc-id $myvpc --description 'SSH access for deployment package build' --query 'GroupId')
mysg=$(eval echo $mysg)
echo -n "Waiting for security group $mysg to be created in $myvpc."
while ! aws ec2 describe-security-groups --group-ids $mysg &> /dev/null; do
  echo -n "."
  sleep 5
done
echo

aws ec2 authorize-security-group-ingress --group-id $mysg --protocol tcp --port 22 --cidr 0.0.0.0/0 && \
  things[${#things[@]}]=$mysg || \
  cleanup $things

amzn_ami=$(aws ec2 describe-images --owners 137112412989 \
 --filters 'Name=block-device-mapping.volume-type,Values=gp2' \
 'Name=virtualization-type,Values=hvm' \
 --query 'Images[*].{Name:Name,ID:ImageId}' \
 --output text \
 | sort -k 2 \
 | grep -v vpc-nat \
 | grep -v 'rc-' \
 | tail -1 \
 | awk '{print $1}')

amzn_ami=$(eval echo $amzn_ami)

echo "Launching an instance from $amzn_ami"
myinst=$(aws ec2 run-instances \
         --image-id $amzn_ami \
         --key-name $stamp \
         --security-group-ids $mysg \
         --instance-type c4.large \
         --count 1 \
         --associate-public-ip-address \
         --query 'Instances[0].InstanceId')

myinst=$(eval echo $myinst)

echo -n "Waiting on a public IP address."
myip=$(aws ec2 describe-instances --instance-id $myinst --query 'Reservations[0].Instances[0].PublicIpAddress')
while test $myip == 'null'; do
  echo -n "."
  myip=$(aws ec2 describe-instances --instance-id $myinst --query 'Reservations[0].Instances[0].PublicIpAddress')
  sleep 1
done
echo

myip=$(eval echo $myip)
things[${#things[@]}]=$myinst

echo -n "Waiting on ssh to $myip."
while ! nc -z -w 1 $myip 22; do
  echo -n "."
  sleep 1
done
echo

echo "Logging in."
echo 'yes' | scp -o StrictHostKeyChecking=no -q -i ${stamp}-rsa remote.sh ec2-user@${myip}: && \
ssh -t -i ${stamp}-rsa ec2-user@${myip} chmod 755 remote.sh && \
ssh -t -i ${stamp}-rsa ec2-user@${myip} ./remote.sh && \
scp -i ${stamp}-rsa ec2-user@${myip}:rds_create_role.zip . && \
zip -u rds_create_role.zip rds_create_role.py

cleanup $things
