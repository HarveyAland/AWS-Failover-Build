import os
import boto3

def handler(event, context):
    # Get the Auto Scaling group name from the environment variable
    asg_name = os.environ['FAILOVER_ASG_NAME']
    
    # Initialize the Auto Scaling client for the primary region
    autoscaling = boto3.client('autoscaling', region_name='us-east-1') 
    
    try:
        # Set the desired capacity of the Auto Scaling group to 0 to trigger failover
        response = autoscaling.set_desired_capacity(
            AutoScalingGroupName=asg_name,
            DesiredCapacity=0
        )
        print(f"Scaled down ASG: {asg_name} to 0 capacity. Failover triggered.")
    except Exception as e:
        print(f"Error scaling down ASG: {e}")
        raise e