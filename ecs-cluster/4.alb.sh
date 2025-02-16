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

# Get Target Group ARN if exists, otherwise create one
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --names expense --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null)

if [ "$TARGET_GROUP_ARN" == "None" ] || [ -z "$TARGET_GROUP_ARN" ]; then
    TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
        --name expense \
        --protocol HTTP \
        --port 80 \
        --vpc-id $VPC_ID \
        --target-type ip \
        --query 'TargetGroups[0].TargetGroupArn' \
        --output text)
    echo "✅ Created Target Group: $TARGET_GROUP_ARN"
else
    echo "✅ Target Group already exists: $TARGET_GROUP_ARN"
fi

# Get Load Balancer ARN if exists, otherwise create one
LOAD_BALANCER_ARN=$(aws elbv2 describe-load-balancers --names expense --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null)

if [ "$LOAD_BALANCER_ARN" == "None" ] || [ -z "$LOAD_BALANCER_ARN" ]; then
    LOAD_BALANCER_ARN=$(aws elbv2 create-load-balancer \
        --name expense \
        --subnets ${SUBNETS[@]} \
        --security-groups $SECURITY_GROUP \
        --scheme internet-facing \
        --query 'LoadBalancers[0].LoadBalancerArn' \
        --output text)
    echo "✅ Created Load Balancer: $LOAD_BALANCER_ARN"
else
    echo "✅ Load Balancer already exists: $LOAD_BALANCER_ARN"
fi

# Ensure HTTP Listener exists with redirect to HTTPS
HTTP_LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $LOAD_BALANCER_ARN --query "Listeners[?Port==\`80\`].ListenerArn" --output text 2>/dev/null)

if [ "$HTTP_LISTENER_ARN" == "None" ] || [ -z "$HTTP_LISTENER_ARN" ]; then
    aws elbv2 create-listener \
        --load-balancer-arn $LOAD_BALANCER_ARN \
        --protocol HTTP \
        --port 80 \
        --default-actions '[{"Type": "redirect", "RedirectConfig": {"Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}]'
    echo "✅ Created HTTP Listener with redirect to HTTPS"
else
    echo "✅ HTTP Listener already exists"
fi

# Ensure HTTPS Listener exists
HTTPS_LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $LOAD_BALANCER_ARN --query "Listeners[?Port==\`443\`].ListenerArn" --output text 2>/dev/null)

if [ "$HTTPS_LISTENER_ARN" == "None" ] || [ -z "$HTTPS_LISTENER_ARN" ]; then
    HTTPS_LISTENER_ARN=$(aws elbv2 create-listener \
        --load-balancer-arn $LOAD_BALANCER_ARN \
        --protocol HTTPS \
        --port 443 \
        --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN \
        --certificates CertificateArn=$CERTIFICATE_ARN \
        --ssl-policy ELBSecurityPolicy-2016-08 \
        --query 'Listeners[0].ListenerArn' \
        --output text)
    echo "✅ Created HTTPS Listener: $HTTPS_LISTENER_ARN"
else
    echo "✅ HTTPS Listener already exists"
fi

# Ensure Fixed Response Rule exists
RULE_EXIST=$(aws elbv2 describe-rules --listener-arn $HTTPS_LISTENER_ARN --query "Rules[?Priority==\`10\`].RuleArn" --output text 2>/dev/null)

if [ "$RULE_EXIST" == "None" ] || [ -z "$RULE_EXIST" ]; then
    aws elbv2 create-rule \
        --listener-arn $HTTPS_LISTENER_ARN \
        --priority 10 \
        --conditions '[{"Field": "path-pattern", "Values": ["/maintenance"]}]' \
        --actions '[{"Type": "fixed-response", "FixedResponseConfig": {"StatusCode": "503", "ContentType": "text/plain", "MessageBody": "Service Temporarily Unavailable"}}]'
    echo "✅ Fixed response rule added for '/maintenance'"
else
    echo "✅ Fixed response rule already exists"
fi

# Update ECS Service to attach Target Group
aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --load-balancers targetGroupArn=$TARGET_GROUP_ARN,containerName=$CONTAINER_NAME,containerPort=80
echo "✅ ECS Service updated with Target Group: $TARGET_GROUP_ARN"

# Get ALB DNS Name
ALB_DNS=$(aws elbv2 describe-load-balancers --names expense --query 'LoadBalancers[0].DNSName' --output text 2>/dev/null)

if [ "$ALB_DNS" == "None" ] || [ -z "$ALB_DNS" ]; then
    echo "❌ Load Balancer DNS not found!"
    exit 1
else
    echo "✅ ALB DNS Name: $ALB_DNS"
fi

# Update Route 53 CNAME Record
aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "'$DOMAIN_NAME'",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [{"Value": "'$ALB_DNS'"}]
      }
    }]
  }'
echo "✅ Route 53 CNAME record updated for $DOMAIN_NAME"
