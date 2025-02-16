#!/bin/bash

# User Inputs
VPC_ID="vpc-057811f3f42dec09f"
SUBNETS=("subnet-000f164cabd01ad15" "subnet-01899a28d9cd091c2")
SECURITY_GROUP="sg-0c2026150f42233ac"
CLUSTER_NAME="expense"
SERVICE_NAME="frontend-node-service"
HOSTED_ZONE_ID="Z011675617HENPLWZ1EJC"
DOMAIN_NAME="ecs-expense.konkas.tech"
CONTAINER_NAME="frontend-node"
CERTIFICATE_ARN="arn:aws:acm:us-east-1:522814728660:certificate/903d653b-c49e-4b28-9cb3-795b477042ea"

# Prompt User for Action
read -p "Do you want to 'create' or 'delete' the Load Balancer setup? (create/delete): " ACTION

if [[ "$ACTION" == "create" ]]; then
    echo "✅ Starting Load Balancer setup..."

    # Check if Target Group already exists
    TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --names expense --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null)
    if [[ -z "$TARGET_GROUP_ARN" ]]; then
        echo "🔹 Creating Target Group..."
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

    # Check if Load Balancer already exists
    LOAD_BALANCER_ARN=$(aws elbv2 describe-load-balancers --names expense --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null)
    if [[ -z "$LOAD_BALANCER_ARN" ]]; then
        echo "🔹 Creating Load Balancer..."
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

    # Wait for ALB to be active
    echo "⏳ Waiting for Load Balancer to be active..."
    aws elbv2 wait load-balancer-available --load-balancer-arns $LOAD_BALANCER_ARN
    echo "✅ Load Balancer is active."

    # Check if HTTP Listener already exists
    HTTP_LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $LOAD_BALANCER_ARN --query 'Listeners[?Protocol==`HTTP`].ListenerArn' --output text 2>/dev/null)
    if [[ -z "$HTTP_LISTENER_ARN" ]]; then
        echo "🔹 Creating HTTP Listener with redirect to HTTPS..."
        aws elbv2 create-listener \
            --load-balancer-arn $LOAD_BALANCER_ARN \
            --protocol HTTP \
            --port 80 \
            --default-actions '[{"Type": "redirect", "RedirectConfig": {"Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}]'
        echo "✅ HTTP Listener created."
    else
        echo "✅ HTTP Listener already exists: $HTTP_LISTENER_ARN"
    fi

    # Check if HTTPS Listener already exists
    HTTPS_LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $LOAD_BALANCER_ARN --query 'Listeners[?Protocol==`HTTPS`].ListenerArn' --output text 2>/dev/null)
    if [[ -z "$HTTPS_LISTENER_ARN" ]]; then
        echo "🔹 Creating HTTPS Listener..."
        HTTPS_LISTENER_ARN=$(aws elbv2 create-listener \
            --load-balancer-arn $LOAD_BALANCER_ARN \
            --protocol HTTPS \
            --port 443 \
            --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN \
            --certificates CertificateArn=$CERTIFICATE_ARN \
            --ssl-policy ELBSecurityPolicy-2016-08 \
            --query 'Listeners[0].ListenerArn' \
            --output text)
        echo "✅ HTTPS Listener created: $HTTPS_LISTENER_ARN"
    else
        echo "✅ HTTPS Listener already exists: $HTTPS_LISTENER_ARN"
    fi

    # Update ECS Service
    echo "🔹 Updating ECS Service..."
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service $SERVICE_NAME \
        --load-balancers targetGroupArn=$TARGET_GROUP_ARN,containerName=$CONTAINER_NAME,containerPort=80
    echo "✅ ECS Service updated with Target Group: $TARGET_GROUP_ARN"

    # Get ALB DNS Name
    ALB_DNS=$(aws elbv2 describe-load-balancers --names expense --query 'LoadBalancers[0].DNSName' --output text)
    echo "✅ ALB DNS Name: $ALB_DNS"

    # Check if Route 53 record already exists
    EXISTING_RECORD=$(aws route53 list-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --query "ResourceRecordSets[?Name == '${DOMAIN_NAME}.' && Type == 'CNAME'].ResourceRecords[0].Value" --output text 2>/dev/null)
    if [[ "$EXISTING_RECORD" != "$ALB_DNS" ]]; then
        echo "🔹 Updating Route 53 CNAME record..."
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
    else
        echo "✅ Route 53 CNAME record already points to $ALB_DNS"
    fi

elif [[ "$ACTION" == "delete" ]]; then
    echo "❌ Starting Load Balancer teardown..."

    # Get Load Balancer ARN
    LOAD_BALANCER_ARN=$(aws elbv2 describe-load-balancers --names expense --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null)
    if [[ -n "$LOAD_BALANCER_ARN" ]]; then
        # Get Listeners
        HTTPS_LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $LOAD_BALANCER_ARN --query 'Listeners[?Protocol==`HTTPS`].ListenerArn' --output text 2>/dev/null)
        HTTP_LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $LOAD_BALANCER_ARN --query 'Listeners[?Protocol==`HTTP`].ListenerArn' --output text 2>/dev/null)

        # Delete Listeners
        if [[ -n "$HTTPS_LISTENER_ARN" ]]; then
            echo "🔹 Deleting HTTPS Listener..."
            aws elbv2 delete-listener --listener-arn $HTTPS_LISTENER_ARN
            echo "✅ HTTPS Listener deleted."
        fi

        if [[ -n "$HTTP_LISTENER_ARN" ]]; then
            echo "🔹 Deleting HTTP Listener..."
            aws elbv2 delete-listener --listener-arn $HTTP_LISTENER_ARN
            echo "✅ HTTP Listener deleted."
        fi

        # Delete Load Balancer
        echo "🔹 Deleting Load Balancer..."
        aws elbv2 delete-load-balancer --load-balancer-arn $LOAD_BALANCER_ARN
        echo "✅ Load Balancer deleted."
    else
        echo "⚠️ Load Balancer not found. Skipping deletion."
    fi

    # Delete Target Group
    TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --names expense --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null)
    if [[ -n "$TARGET_GROUP_ARN" ]]; then
        echo "🔹 Deleting Target Group..."
        aws elbv2 delete-target-group --target-group-arn $TARGET_GROUP_ARN
        echo "✅ Target Group deleted."
    else
        echo "⚠️ Target Group not found. Skipping deletion."
    fi

    # Delete Route 53 CNAME record
    EXISTING_RECORD=$(aws route53 list-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --query "ResourceRecordSets[?Name == '${DOMAIN_NAME}.' && Type == 'CNAME'].ResourceRecords[0].Value" --output text 2>/dev/null)
    if [[ -n "$EXISTING_RECORD" ]]; then
        echo "🔹 Removing Route 53 CNAME record..."
        aws route53 change-resource-record-sets \
            --hosted-zone-id $HOSTED_ZONE_ID \
            --change-batch '{
                "Changes": [{
                    "Action": "DELETE",
                    "ResourceRecordSet": {
                        "Name": "'$DOMAIN_NAME'",
                        "Type": "CNAME",
                        "TTL": 300,
                        "ResourceRecords": [{"Value": "'$EXISTING_RECORD'"}]
                    }
                }]
            }'
        echo "✅ Route 53 CNAME record deleted for $DOMAIN_NAME"
    else
        echo "⚠️ Route 53 record not found. Skipping deletion."
    fi

    echo "✅ Cleanup completed."
else
    echo "❌ Invalid option. Please enter 'create' or 'delete'."
    exit 1
fi