import os
import boto3

def handler(event, context):
    asg_name = os.environ['FAILOVER_ASG_NAME']
    autoscaling = boto3.client('autoscaling', region_name='us-west-2')
    route53 = boto3.client('route53')
    
    # Route 53 Hosted Zone ID from Terraform
    zone_id = "Z3EXAMPLEZONEID"  # Replace with actual Hosted Zone ID
    failover_record_name = "fail.harvey1.com"  # The failover DNS record matching Terraform
    failover_dns_name = "failover-alb-123456789.us-west-2.elb.amazonaws.com"  # Failover ALB DNS name
    failover_zone_id = "Z35SXDOTRQ7X7K"  # Failover ALB Hosted Zone ID

    try:
        # Scale up the Auto Scaling Group (ASG) in the failover region
        autoscaling.set_desired_capacity(
            AutoScalingGroupName=asg_name,
            DesiredCapacity=2  # Scale to 2 instance
        )
        print(f"Scaled up ASG: {asg_name}")


    except Exception as e:
        print(f"Error scaling ASG: {e}")