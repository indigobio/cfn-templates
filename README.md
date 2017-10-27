# Contents

The contents of this repo are a) always in flux, and b) currently consist of:

* "chef_bucket", "dereg_queue," "rds," "stacks," and "vpc" folders, which describe Indigo Bioautomation's infrastructure.
* A "utils" folder, which contains:
  * A "jenkins" folder, containing groovy scripts to use with the workflow DSL plugin
  * A few scripts, most notably a "snapshots.sh" script that copies snapshots between regions, based on "backup_id" tags. 

The majority of the contents of this repository are "SparklePacks," or at least before they were called SparklePacks, and 
they are specific to my employer, but feel free to browse around.  See http://sparkleformation.github.io/sparkle_formation/UserDocs/sparkle-packs.html.

I tried to emulate AWS's documentation of each component as closely as possible.

# Setting up a Jenkins Server

Start off by obtaining:

* AWS credentials, and/or
* Infrajenkins AWS credentials
* The indigo-bootstrap.pem SSH key

Then follow these steps.

1. Set up the AWS CLI (https://aws.amazon.com/cli/)

    * Mac: `brew install awscli`
    * Linux: `sudo apt-get -y install python-pip python-virtualenv && sudo pip install --upgrade awscli`

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
        aws ec2 authorize-security-group-ingress --group-id $mysg --protocol tcp --port 443 --cidr 207.250.246.0/24
        aws ec2 authorize-security-group-ingress --group-id $mysg --protocol all --port -1 --source-group $mysg

1. Search for the newest Xenial AMI

        myami=$(aws ec2 describe-images \
          --owners 099720109477 \
          --query 'Images[?VirtualizationType == `hvm` && RootDeviceType == `ebs` && Architecture == `x86_64` && contains(Name, `xenial-16.04-amd64-server`) == `true`].{ImageId: ImageId, Name: Name}' \
          --output text \
          | sort -k2 \
          | tail -1 \
          | awk '{print $1}')
        myami=$(eval echo $myami)

1. Launch the Xenial EC2 instance

        myinst=$(aws ec2 run-instances --image-id $myami --key-name indigo-bootstrap --security-group-ids $mysg --instance-type t2.small --count 1 --associate-public-ip-address --query 'Instances[0].InstanceId')
        myinst=$(eval echo $myinst)
        aws ec2 create-tags --resources $myinst --tags Key=Name,Value=infrajenkins-restore

    Wait about a minute and you can get your public IP address.

        myip=$(aws ec2 describe-instances --instance-id $myinst --query 'Reservations[0].Instances[0].PublicIpAddress')
        myip=$(eval echo $myip)

1. Log into the instance

        ssh -i ~/.ssh/indigo-bootstrap.pem ubuntu@$myip

1. Install Oracle JDK 8

        sudo apt-get update
        sudo apt-get -y install git-core build-essential bison openssl libreadline6 libreadline6-dev curl git-core \
          zlib1g zlib1g-dev libssl-dev libyaml-dev libxml2-dev autoconf libc6-dev ncurses-dev automake libtool \
          libgmp-dev software-properties-common
        sudo add-apt-repository ppa:webupd8team/java
        sudo apt-get update
        echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
        sudo apt-get -y install oracle-java8-installer
        sudo apt-get -y install oracle-java8-set-default

1. Install jenkins and a few extras

        wget -q -O - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
        echo deb http://pkg.jenkins-ci.org/debian binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list
        sudo apt-get update
        sudo apt-get -y install jenkins
        sudo passwd -l jenkins

1. Install ruby and gems

        wget https://cache.ruby-lang.org/pub/ruby/2.3/ruby-2.3.3.tar.bz2
        tar xjvf ruby-2.3.3.tar.bz2
        cd ruby-2.3.3
        ./configure --prefix=/usr/local && make && sudo make install
        sudo gem install bundler
        cd ..
        rm -rf ruby-2.3.3*

1.  Install s3cmd

    Supply the infrajenkins access key ID and secret access key; leave everything else default.

        sudo apt-get -y install python-pip && \
        sudo pip install --upgrade pip && \
        sudo pip install s3cmd && \
        sudo pip install awscli
        s3cmd --configure

1. Start jenkins and get the cli

        sudo service jenkins start
        wget http://localhost:8080/jnlpJars/jenkins-cli.jar

1. Get the initial admin password:

        adminpw=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

1. Install plugins

        for p in \
        git-parameter ace-editor bouncycastle-api jquery-detached github-organization-folder \
        pipeline-model-api structs handlebars role-strategy mailer docker-commons ansicolor \
        pipeline-stage-view hipchat authentication-tokens pipeline-rest-api pam-auth \
        build-timeout mapdb-api gradle ssh-credentials credentials pipeline-milestone-step \
        credentials-binding momentjs pipeline-model-definition workflow-cps docker-workflow \
        pipeline-model-declarative-agent pipeline-model-extensions workflow-support junit \
        ws-cleanup run-condition ruby-runtime github-api scm-api audit-trail resource-disposer \
        multiple-scms matrix-auth email-ext git-client workflow-api durable-task matrix-project \
        flexible-publish javadoc s3 display-url-api cloudbees-folder workflow-job rvm \
        jackson2-api github-oauth token-macro jquery branch-api github windows-slaves \
        external-monitor-job ssh-slaves pipeline-graph-analysis workflow-step-api git-server \
        plain-credentials workflow-multibranch antisamy-markup-formatter pipeline-github-lib \
        aws-java-sdk workflow-basic-steps rebuild pipeline-build-step script-security \
        workflow-cps-global-lib workflow-aggregator git github-branch-source performance \
        workflow-durable-task-step ant maven-plugin subversion timestamper workflow-scm-step \
        pipeline-stage-tags-metadata pipeline-stage-step icon-shim copyartifact \
        pipeline-input-step ldap ; do \
          java -jar jenkins-cli.jar -auth Admin:$adminpw -s http://localhost:8080/ install-plugin $p ; done
        sudo service jenkins restart

    See notes, below, on getting a list of plugins to install using Jenkins's script console.

1. Install the emp CLI tool:
        sudo curl -sL https://github.com/remind101/empire/releases/download/v0.13.0/emp-`uname -s`-`uname -m` -o /usr/local/bin/emp-0.13.0
        sudo chmod 755 /usr/local/bin/emp-0.13.0
        if [ -L /usr/local/bin/emp ]; then
          sudo rm /usr/local/bin/emp
        fi
        sudo ln -s /usr/local/bin/emp-0.13.0 /usr/local/bin/emp

1. Grab the latest infrajenkins backup from s3

        s3cmd get s3://infrajenkins-backups/latest.tar.gz

1. Restore the backup

        tar xvzf latest.tar.gz
        cd <number>
        sudo cp -Rp config.xml credentials.xml identity.key.enc jobs secret.key* \
          secrets users hudson.plugins.s3.S3BucketPublisher.xml /var/lib/jenkins/
        sudo chown -R jenkins:jenkins /var/lib/jenkins

1. Restart jenkins

        sudo service jenkins restart

1. Update the system for security reasons and reboot.

        cd ~
        rm .s3cfg
        sudo apt-get dist-upgrade
        sudo reboot

1. Draw the rest of the f---ing owl.

    Create an ELB in the new infrajenkins security group with two listeners:

    * an HTTPS listener that talks to the new Jenkins instance via plaintext HTTP on port 8080
    * a TCP listener that forwards port 22 to the Jenkins instance
    * use the indigocraftsmen.net ACM cert for SSL
    * use a simple TCP health check

    Change the infrajenkins.indigocraftsmen.net CNAME to point to the new ELB.

## Getting a list of installed plugins

The following groovy script will spit out a list of currently-installed plugins for Jenkins.
Just run it in the script console in Jenkins's management web UI.

        println "Running plugin enumerator"
        println ""
        def plugins = jenkins.model.Jenkins.instance.getPluginManager().getPlugins()
        plugins.each {println "${it.getShortName()}"}
        println ""
        println "Total number of plugins: ${plugins.size()}"
