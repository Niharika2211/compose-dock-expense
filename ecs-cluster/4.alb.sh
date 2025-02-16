#!/bin/bash

# Configuration
VPC_ID="vpc-057811f3f42dec09f"
SUBNETS=("subnet-000f164cabd01ad15" "subnet-01899a28d9cd091c2")
SECURITY_GROUP="sg-0c2026150f42233ac"
CLUSTER_NAME="expense"
SERVICE_NAME="frontend-node-service"
HOSTED_ZONE_ID="Z011675617HENPLWZ1EJC"
DOMAIN_NAME="ecs-expense.konkas.tech"
CONTAINER_NAME="frontend-node"
CERTIFICATE_ARN="arn:aws:acm:us-east-1:522814728660:certificate/903d653b-c49e-4b28-9cb3-795b477042ea"

# Ask for action
read -p "Do you want to 'create' or 'delete' the Load Balancer setup? (create/delete): " ACTION

if [[ "$ACTION" == "create" ]]; then
    echo "✅ Starting Load Balancer setup..."

    # Get or create Target Group
    TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --names expense --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null)

    if [[ -z "$TARGET_GROUP_ARN" || "$TARGET_GROUP_ARN" == "None" ]]; then
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

    # Get or create Load Balancer
    LOAD_BALANCER_ARN=$(aws elbv2 describe-load-balancers --names expense --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null)

    if [[ -z "$LOAD_BALANCER_ARN" || "$LOAD_BALANCER_ARN" == "None" ]]; then
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

    # Create Listeners
    HTTP_LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $LOAD_BALANCER_ARN --query "Listeners[?Port==\`80\`].ListenerArn" --output text 2>/dev/null)

    if [[ -z "$HTTP_LISTENER_ARN" || "$HTTP_LISTENER_ARN" == "None" ]]; then
        aws elbv2 create-listener \
            --load-balancer-arn $LOAD_BALANCER_ARN \
            --protocol HTTP \
            --port 80 \
            --default-actions '[{"Type": "redirect", "RedirectConfig": {"Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}]'
        echo "✅ Created HTTP Listener (Redirect to HTTPS)"
    fi

    HTTPS_LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $LOAD_BALANCER_ARN --query "Listeners[?Port==\`443\`].ListenerArn" --output text 2>/dev/null)

    if [[ -z "$HTTPS_LISTENER_ARN" || "$HTTPS_LISTENER_ARN" == "None" ]]; then
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
    fi

    # Update ECS Service
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service $SERVICE_NAME \
        --load-balancers targetGroupArn=$TARGET_GROUP_ARN,containerName=$CONTAINER_NAME,containerPort=80
    echo "✅ ECS Service updated with Target Group: $TARGET_GROUP_ARN"

    # Update Route 53
    ALB_DNS=$(aws elbv2 describe-load-balancers --names expense --query 'LoadBalancers[0].DNSName' --output text)
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

elif [[ "$ACTION" == "delete" ]]; then
    echo "⚠️ Deleting Load Balancer setup..."

    # Delete Listeners
    LISTENERS=$(aws elbv2 describe-listeners --load-balancer-arn $LOAD_BALANCER_ARN --query "Listeners[*].ListenerArn" --output text 2>/dev/null)
    for LISTENER in $LISTENERS; do
        aws elbv2 delete-listener --listener-arn $LISTENER
        echo "✅ Deleted Listener: $LISTENER"
    done

    # Delete Load Balancer
    aws elbv2 delete-load-balancer --load-balancer-arn $LOAD_BALANCER_ARN
    echo "✅ Load Balancer deletion initiated: $LOAD_BALANCER_ARN"

    # Wait for LB deletion
    sleep 20

    # Delete Target Group
    aws elbv2 delete-target-group --target-group-arn $TARGET_GROUP_ARN
    echo "✅ Deleted Target Group: $TARGET_GROUP_ARN"

    # Delete Route 53 CNAME record
    aws route53 change-resource-record-sets \
        --hosted-zone-id $HOSTED_ZONE_ID \
        --change-batch '{
            "Changes": [{
                "Action": "DELETE",
                "ResourceRecordSet": {
                    "Name": "'$DOMAIN_NAME'",
                    "Type": "CNAME",
                    "TTL": 300,
                    "ResourceRecords": [{"Value": "'$ALB_DNS'"}]
                }
            }]
        }'
    echo "✅ Deleted Route 53 CNAME record for $DOMAIN_NAME"

    echo "🚀 Deletion complete!"

else
    echo "❌ Invalid option. Please enter 'create' or 'delete'."
fi
