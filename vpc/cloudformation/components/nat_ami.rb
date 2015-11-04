# READ ME: changed from HVM to PV because m1.smalls may be faster than m3.mediums
# You may very well want to switch to an HVM AMI if you intend to use newer generation instance types.
SparkleFormation.build do
  mappings.region_to_nat_ami do
    set!('us-east-1'.disable_camel!,    :ami => 'ami-5fb8c835') # amzn-ami-hvm-2014.09.2.x86_64-ebs (NOT the nat ami)
    set!('us-west-1'.disable_camel!,    :ami => 'ami-56ea8636')
    set!('us-west-2'.disable_camel!,    :ami => 'ami-d93622b8')
  end
end
