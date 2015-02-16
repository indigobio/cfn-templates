require 'rubygems'
require 'aws-sdk'
require 'json'
require 'time'
require 'chef'

asg_queue_url = ENV['ASG_DEREG_QUEUE_URL']
asg_error_queue_url = ENV['ASG_DEREG_ERROR_QUEUE_URL']
topic_arn= ENV['WARNING_TOPIC']
sqs = AWS::SQS.new(:access_key_id => ENV['ADMINPROC_USER'],
                   :secret_access_key => ENV['ADMINPROC_PASS'],
                   :sqs_endpoint => asg_queue_url)
sns = AWS::SNS.new(:access_key_id => ENV['RELEASE_USER'],
                   :secret_access_key => ENV['RELEASE_PASS'])
Chef::Config.from_file(ENV['HOME'] + '/.chef/knife.rb')
rest = Chef::REST.new(Chef::Config[:chef_server_url])

sqs.queues[asg_queue_url].poll do |m|
  sns_msg = m.as_sns_message
  body = JSON.parse(sns_msg.to_h[:body])
  event = body["Event"]
  begin
    if event.include? "autoscaling:EC2_INSTANCE_TERMINATE"
      time = Time.now.utc.iso8601
      # here we assume that the ec2 instance id = node name
      iid = body["EC2InstanceId"]

      puts "deleting node " + iid + "\n"
      del_node = rest.delete_rest("/nodes/" + iid)

      puts "deleting client " + iid + "\n"
      del_client = rest.delete_rest("/clients/" + iid)

    elsif event.include? "autoscaling:TEST_NOTIFICATION"
      m.delete
    end

      # on failure:
  rescue
    msg = "There was a problem deregistering instance #{iid}.\n" + $!.to_s + "\n" + body.to_a.sort.join("\n")
    puts msg    # should go to STDERR

    # send alert to staff
    topic = sns.topics[topic_arn]
    topic.publish(msg)

    # put the message in DeregErrorQueue
    error_q = sqs.queues[asg_error_queue_url]
    error_q.send_message(m.to_s)

    # keep moving
    next
  end
  puts ""
end