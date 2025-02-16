#!/bin/bash

VPC_ID="vpc-057811f3f42dec09f"
SUBNETS=("subnet-000f164cabd01ad15" "subnet-01899a28d9cd091c2")
SECURITY_GROUP="sg-0c2026150f42233ac"
CLUSTER_NAME="expense"
SERVICE_NAME="frontend-node-service"
HOSTED_ZONE_ID="Z011675617HENPLWZ1EJC"
DOMAIN_NAME="ecs-expense.konkas.tech"
CONTAINER_NAME="frontend-node"
CERTIFICATE_ARN="arn:aws:acm:us-east-1:522814728660:certificate/903d653b-c49e-4b28-9cb3-795b477042ea"

# Check if Target Group exists
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --names expense --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null)
if [ "$TARGET_GROUP_ARN" == "None" ]; then
    TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
        --name expense \
        --protocol HTTP \
        --port 80 \
        --vpc-id $VPC_ID \
        --target-type ip \
        --query 'TargetGroups[0].TargetGroupArn' \
        --output text)
    echo "Created Target Group: $TARGET_GROUP_ARN"
else
    echo "Target Group already exists: $TARGET_GROUP_ARN"
fi

# Check if Load Balancer exists
LOAD_BALANCER_ARN=$(aws elbv2 describe-load-balancers --names expense --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null)
if [ "$LOAD_BALANCER_ARN" == "None" ]; then
    LOAD_BALANCER_ARN=$(aws elbv2 create-load-balancer \
        --name expense \
        --subnets ${SUBNETS[@]} \
        --security-groups $SECURITY_GROUP \
        --scheme internet-facing \
        --query 'LoadBalancers[0].LoadBalancerArn' \
        --output text)
    echo "Created Load Balancer: $LOAD_BALANCER_ARN"
else
    echo "Load Balancer already exists: $LOAD_BALANCER_ARN"
fi

# Check if HTTPS Listener exists
LISTENER_ARN_HTTPS=$(aws elbv2 describe-listeners --load-balancer-arn $LOAD_BALANCER_ARN --query 'Listeners[?Protocol==`HTTPS`].ListenerArn' --output text 2>/dev/null)
if [ -z "$LISTENER_ARN_HTTPS" ]; then
    LISTENER_ARN_HTTPS=$(aws elbv2 create-listener \
        --load-balancer-arn $LOAD_BALANCER_ARN \
        --protocol HTTPS \
        --port 443 \
        --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN \
        --certificates CertificateArn=$CERTIFICATE_ARN \
        --ssl-policy ELBSecurityPolicy-2016-08 \
        --query 'Listeners[0].ListenerArn' \
        --output text)
    echo "Created HTTPS Listener: $LISTENER_ARN_HTTPS"
else
    echo "HTTPS Listener already exists: $LISTENER_ARN_HTTPS"
fi

# Update ECS Service with Target Group
aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --load-balancers targetGroupArn=$TARGET_GROUP_ARN,containerName=$CONTAINER_NAME,containerPort=80

echo "ECS Service updated with Target Group: $TARGET_GROUP_ARN"

# Get ALB DNS Name
ALB_DNS=$(aws elbv2 describe-load-balancers \
    --names expense \
    --query 'LoadBalancers[0].DNSName' \
    --output text)

echo "ALB DNS Name: $ALB_DNS"

# Update Route 53 Record
aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "'$DOMAIN_NAME'",
        "Type": "CNAME",
        "TTL": 1,
        "ResourceRecords": [{
          "Value": "'$ALB_DNS'"
        }]
      }
    }]
  }'

echo "Route 53 CNAME record updated for $DOMAIN_NAME"