SfnRegistry.register(:deregister_ecs_instances_py) do

  zip_file join!(
"import json\n",
"import boto3\n\n",

"print('Loading function')\n\n",

"def lambda_handler(event, context):\n",
"  print(\"Event received: \" + json.dumps(event))\n\n",

"  for record in event['Records']:\n",
"    if 'Sns' in record:\n",
"      message = json.loads(record['Sns']['Message'])\n",
"      if message['Event'] == 'autoscaling:EC2_INSTANCE_TERMINATE':\n",
"        terminatedInstanceId = message['EC2InstanceId']\n",
"        print('terminatedInstanceId = ' + terminatedInstanceId)\n",
"        try:\n",
"          client = boto3.client('ecs')\n",
"        except:\n",
"         raise Exception('Could not connect to ECS')\n\n",

"        clusterArns = client.list_clusters()['clusterArns']\n\n",

"        for clusterArn in clusterArns:\n",
"          containerInstanceArns = client.list_container_instances(cluster=clusterArn)['containerInstanceArns']\n",
"          if len(containerInstanceArns) > 0:\n",
"            containerInstances = client.describe_container_instances(cluster=clusterArn, containerInstances=containerInstanceArns)['containerInstances']\n",
"            for instance in containerInstances:\n",
"              if instance['ec2InstanceId'] == terminatedInstanceId:\n",
"                client.deregister_container_instance(cluster=clusterArn,containerInstance=instance['containerInstanceArn'], force=True)\n",
"      else:\n",
"        raise Exception('Could not process SNS message')\n")
end