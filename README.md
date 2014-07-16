Requirements:

- Create buckets in each region (us-east-1 and us-west-2 in our case) to hold the cloud formation templates.
- Create buckets in each region to hold Chef validation keys and encrypted data bag secrets.
- Make sure you have an identical SSH key pair in each region to log into the created instances as the "ubuntu" user, if necessary.
- Make sure you have an identical, instance-backed AMI in each region.

The mongodb-replicaset-stack template will create an IAM user with s3:get privileges as well as cloud formation privileges.  It will create a
keypair for for S3, which is supplied to the "ubuntu" user to use with s3cmd to download the Chef validation key and encrypted data bag 
secrets from S3 with IAM credentials.  It will also soet up bucket policies on the bucket holding Chef credentials, preventing unauthorized 
access to these files.  

It's important that your buckets containing Chef validation credentials and secrets aren't made public, or that bucket policies aren't made
so loose that an unintended user can gain access to these files.
