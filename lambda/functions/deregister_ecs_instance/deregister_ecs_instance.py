import json
import boto3

"""
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:DeregisterContainerInstance",
        "ecs:DescribeClusters",
        "ecs:DescribeContainerInstances",
        "ecs:ListContainerInstances"
      ],
      "Resource": [
        "arn:aws:ecs:us-west-2:*:cluster/*",
        "arn:aws:ecs:us-west-2:*:container-instance/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:ListClusters",
        "ecs:ListContainerInstances"
      ],
      "Resource": "*"
    }
  ]
}
"""

print('Loading function')

def lambda_handler(event, context):
  print("Event received: " + json.dumps(event))
  for record in event['Records']:
    if 'Sns' in record:
      message = json.loads(record['Sns']['Message'])
      if message['Event'] == 'autoscaling:EC2_INSTANCE_TERMINATE':
        terminatedInstanceId = message['EC2InstanceId']
        print("terminatedInstanceId = " + terminatedInstanceId)

        try:
          client = boto3.client('ecs')
        except:
          raise Exception('Could not connect to ECS')

        clusterArns = client.list_clusters()['clusterArns']

        for clusterArn in clusterArns:
          containerInstanceArns = client.list_container_instances(cluster=clusterArn)['containerInstanceArns']
          if len(containerInstanceArns) > 0:
            containerInstances = client.describe_container_instances(cluster=clusterArn, containerInstances=containerInstanceArns)['containerInstances']
            for instance in containerInstances:
              if instance['ec2InstanceId'] == terminatedInstanceId:
                client.deregister_container_instance(cluster=clusterArn,containerInstance=instance['containerInstanceArn'], force=True)
      else:
        raise Exception('Could not process SNS message')
