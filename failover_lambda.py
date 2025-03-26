import os
import boto3

def handler(event, context):
    asg_name = os.environ['FAILOVER_ASG_NAME']
    autoscaling = boto3.client('autoscaling', region_name='us-west-2')


    try:
        # Scale up the Auto Scaling Group (ASG) in the failover region
        autoscaling.set_desired_capacity(
            AutoScalingGroupName=asg_name,
            DesiredCapacity=2  # Scale to 2 instance
        )
        print(f"Scaled up ASG: {asg_name}")


    except Exception as e:
        print(f"Error scaling ASG: {e}")
