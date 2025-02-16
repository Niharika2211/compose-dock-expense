#!/bin/bash

VPC_ID="vpc-057811f3f42dec09f"
SUBNETS=("subnet-000f164cabd01ad15" "subnet-01899a28d9cd091c2")
SECURITY_GROUP="sg-0c2026150f42233ac"
CLUSTER_NAME="expense"
SERVICE_NAME="frontend-node-service"
HOSTED_ZONE_ID="Z011675617HENPLWZ1EJC"
DOMAIN_NAME="ecs-expense.konkas.tech"
CONTAINER_NAME="frontend-node"


TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
    --name expense \
    --protocol HTTP \
    --port 80 \
    --vpc-id $VPC_ID \
    --target-type ip \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)

echo "Target Group ARN: $TARGET_GROUP_ARN"


LOAD_BALANCER_ARN=$(aws elbv2 create-load-balancer \
    --name expense \
    --subnets ${SUBNETS[@]} \
    --security-groups $SECURITY_GROUP \
    --scheme internet-facing \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text)

echo "Load Balancer ARN: $LOAD_BALANCER_ARN"


# Create HTTP Listener with Redirect to HTTPS
aws elbv2 create-listener \
    --load-balancer-arn $LOAD_BALANCER_ARN \
    --protocol HTTP \
    --port 80 \
    --default-actions '[{"Type": "redirect", "RedirectConfig": {"Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}]'

echo "✅ HTTP Listener created with redirect to HTTPS for Load Balancer ARN: $LOAD_BALANCER_ARN"

# Create HTTPS Listener with SSL Termination
LISTENER_ARN_HTTPS=$(aws elbv2 create-listener \
    --load-balancer-arn $LOAD_BALANCER_ARN \
    --protocol HTTPS \
    --port 443 \
    --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN \
    --certificates CertificateArn=arn:aws:acm:us-east-1:522814728660:certificate/903d653b-c49e-4b28-9cb3-795b477042ea \
    --ssl-policy ELBSecurityPolicy-2016-08)

echo "✅ HTTPS Listener created for Load Balancer ARN: $LOAD_BALANCER_ARN"

# Create an additional rule for a fixed response (e.g., maintenance mode)
aws elbv2 create-rule \
    --listener-arn $LISTENER_ARN_HTTPS \
    --priority 10 \
    --conditions '[{"Field": "path-pattern", "Values": ["/maintenance"]}]' \
    --actions '[{"Type": "fixed-response", "FixedResponseConfig": {"StatusCode": "503", "ContentType": "text/plain", "MessageBody": "Service Temporarily Unavailable"}}]'

echo "✅ Fixed response rule added for path '/maintenance' with 503 Service Unavailable."


aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --load-balancers targetGroupArn=$TARGET_GROUP_ARN,containerName=$CONTAINER_NAME,containerPort=80

echo "ECS Service updated with Target Group ARN: $TARGET_GROUP_ARN"


ALB_DNS=$(aws elbv2 describe-load-balancers \
    --names expense \
    --query 'LoadBalancers[0].DNSName' \
    --output text)

echo "ALB DNS Name: $ALB_DNS"


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