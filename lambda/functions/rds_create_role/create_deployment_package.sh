#!/usr/bin/env bash

# aws ec2 describe-images --owners 137112412989 \
#  --filters 'Name=block-device-mapping.volume-type,Values=gp2' \
#  'Name=virtualization-type,Values=hvm' \
#  --query 'Images[*].{Name:Name,ID:ImageId}' \
#  --output text \
#  | sort -k 2 \
#  | grep -v vpc-nat

stamp="temp-$(date +'%Y%m%d%H%M%S')$$"

echo "Creating temporary key pair for ssh."
aws ec2 create-key-pair --key-name $stamp --query 'KeyMaterial' --output text > ${stamp}-rsa 
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

aws ec2 authorize-security-group-ingress --group-id $mysg --protocol tcp --port 22 --cidr 0.0.0.0/0

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

#aws ec2 terminate-instances --instance-id $myinst &> /dev/null
#
#echo -n "Waiting on $myinst to be terminated."
#while test $(aws ec2 describe-instances --instance-id $myinst --query 'Reservations[0].Instances[0].State.Name' --output text) != 'terminated'; do
#  echo -n "."
#  sleep 10
#done
#echo
#
#aws ec2 delete-security-group --group-id $mysg
#aws ec2 delete-key-pair --key-name $stamp
#rm ${stamp}-rsa
