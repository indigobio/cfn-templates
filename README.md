#Contents

The contents of this repo are a) always in flux, and b) currently consist of:

* "chef_bucket", "dereg_queue," "rds," "stacks," and "vpc" folders, which describe Indigo Bioautomation's infrastructure.
* A "utils" folder, which contains:
  * A "jenkins" folder, containing groovy scripts to use with the workflow DSL plugin
  * A few scripts, most notably a "snapshots.sh" script that copies snapshots between regions, based on "backup_id" tags. 

The majority of the contents of this repository are "SparklePacks," or at least before they were called SparklePacks, and 
they are specific to my employer, but feel free to browse around.  See http://sparkleformation.github.io/sparkle_formation/UserDocs/sparkle-packs.html.

I tried to emulate AWS's documentation of each component as closely as possible.

#Setting up a Jenkins Server

Start off by obtaining:

* AWS credentials, and/or
* Infrajenkins AWS credentials
* The indigo-bootstrap.pem SSH key

Then follow these steps.

1. Set up the AWS CLI (https://aws.amazon.com/cli/)

	* Mac: `brew install awscli`
	* Linux: `sudo apt-get -y install python-pip && sudo pip install --upgrade awscli`

1. Configure your AWS credentials

		aws configure
		AWS Access Key ID: AKIAxxxx
		AWS Secret Access Key: xxxx
		Default region name: us-east-1
		Default output format:

1. Place a copy of the indigo-bootstrap.pem file from into your ~/.ssh directory.  Make sure its permissions are 0600.

1. You may need to import the indigo-bootstrap key to AWS EC2.  If so, then base64 encode it and upload it.

		aws ec2 describe-key-pairs --key-names indigo-bootstrap
		# If no key is returned...
		mykey=$(ssh-keygen -y -f .ssh/indigo-bootstrap.pem | ruby -r 'base64' -e 'puts Base64.encode64(STDIN.read)')
		aws ec2 import-key-pair --key-name indigo-bootstrap --public-key-material $mykey

1. Create a security group

   This example opens up your jenkins server to the world.  Replace 207.250.246.0/24 with your desired IP block.

		myvpc=$(aws ec2 describe-vpcs --filters 'Name=isDefault,Values=true' --query 'Vpcs[0].VpcId')
		myvpc=$(eval echo $myvpc)
		mysg=$(aws ec2 create-security-group --group-name infrajenkins-`date '+%Y%m%d%H%M%S'` --vpc-id $myvpc --description 'HTTP/SSH access for infrajenkins' --query 'GroupId')
		mysg=$(eval echo $mysg)
		aws ec2 authorize-security-group-ingress --group-id $mysg --protocol tcp --port 22 --cidr 207.250.246.0/24
		aws ec2 authorize-security-group-ingress --group-id $mysg --protocol tcp --port 8080  --cidr 207.250.246.0/24


1. Launch a trusty AMI

   Visit https://cloud-images.ubuntu.com/locator/ec2/ and type 'us-east-1 trusty 64 hvm:ebs-ssd'
   into the search box.  Use the AMI id displayed.

		myinst=$(aws ec2 run-instances --image-id ami-415f6d2b --key-name indigo-bootstrap --security-group-ids $mysg --instance-type t2.small --count 1 --associate-public-ip-address --query 'Instances[0].InstanceId')
		myinst=$(eval echo $myinst)
		aws ec2 create-tags --resources $myinst --tags Key=Name,Value=infrajenkins-restore

   Wait about a minute and you can get your public IP address.

		myip=$(aws ec2 describe-instances --instance-id $myinst --query 'Reservations[0].Instances[0].PublicIpAddress')
    myip=$(eval echo $myip)

1. Log into the instance

		ssh -i ~/.ssh/indigo-bootstrap.pem ubuntu@$myip

1. Install jenkins and a few extras

		wget -q -O - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
		echo deb http://pkg.jenkins-ci.org/debian binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list
		sudo apt-get update
		sudo apt-get -y install git-core build-essential bison openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libxml2-dev autoconf libc6-dev ncurses-dev automake libtool libgmp-dev
		wget http://pkg.jenkins-ci.org/debian/binary/jenkins_1.632_all.deb
		sudo dpkg -i jenkins_1.632_all.deb
		sudo passwd jenkins

  Note: the Jenkins people broke jenkins, which is why you should install 1.632.  You have just added the 
  jenkins repository.  You will be prompted to input a password.

1. Add the jenkins user to the sudo group.

		sudo usermod -G sudo jenkins

1. Install rvm and gems

		sudo su - jenkins
		gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
		curl -sSL https://get.rvm.io | bash -s stable --ruby=2.2.2
		source /var/lib/jenkins/.rvm/scripts/rvm

  You will be prompted for jenkins's password.

1. Create a gemset and install the bundler gem.

		rvm gemset use --create jenkins
		gem install bundler
		exit

1.  Install s3cmd

   Supply the infrajenkins access key ID and secret access key; leave everything else default.

		sudo apt-get -y install python-pip && sudo pip install s3cmd
		s3cmd --configure

1. Start jenkins and get the cli

		sudo service jenkins start
		wget http://localhost:8080/jnlpJars/jenkins-cli.jar

1. Install plugins

		for i in credentials-binding copyartifact flexible-publish github git-parameter rvm s3 workflow-aggregator; do
		  java -jar jenkins-cli.jar -s http://localhost:8080/ install-plugin $i ; done
		sudo service jenkins restart

1. Grab the latest infrajenkins backup from s3

		s3cmd get s3://ascent-infrajenkins-backups/latest.tar.gz

1. Restore the backup

		tar xvzf latest.tar.gz
		cd <number>
		sudo cp -Rp config.xml credentials.xml identity.key.enc jobs secret.key* secrets users /var/lib/jenkins/
		sudo chown -R jenkins:jenkins /var/lib/jenkins

1. Restart jenkins

		sudo passwd -d jenkins
		sudo service jenkins stop
		sudo service jenkins start

# TODO (Misc area for old, undocumented stuff)

Well, there's lots to do but most important is describe how to create our Chef validator key bucket and the instance deregistration notification queue, since I don't expect to create Jenkins jobs to perform these actions.
