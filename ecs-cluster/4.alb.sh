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

    # Ensure TARGET_GROUP_ARN is not empty before proceeding
    if [[ -z "$TARGET_GROUP_ARN" || "$TARGET_GROUP_ARN" == "None" ]]; then
        echo "❌ ERROR: Failed to get or create Target Group."
        exit 1
    fi

    # Get or create Load Balancer
    LOAD_BALANCER_ARN=$(aws elbv2 describe-load-balancers --names expense --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null)

    if [[ -z "$LOAD_BALANCER_ARN" || "$LOAD_BALANCER_ARN" == "None" ]]; then
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

    # Ensure LOAD_BALANCER_ARN is valid before proceeding
    if [[ -z "$LOAD_BALANCER_ARN" || "$LOAD_BALANCER_ARN" == "None" ]]; then
        echo "❌ ERROR: Failed to get or create Load Balancer."
        exit 1
    fi

    # Update ECS Service
    echo "🔹 Updating ECS Service..."
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service $SERVICE_NAME \
        --load-balancers targetGroupArn=$TARGET_GROUP_ARN,containerName=$CONTAINER_NAME,containerPort=80

    echo "✅ ECS Service updated with Target Group: $TARGET_GROUP_ARN"

elif [[ "$ACTION" == "delete" ]]; then
    echo "⚠️ Deleting Load Balancer setup..."

    # Get existing resources
    TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --names expense --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null)
    LOAD_BALANCER_ARN=$(aws elbv2 describe-load-balancers --names expense --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null)

    # Ensure resources exist before attempting to delete
    if [[ -z "$LOAD_BALANCER_ARN" || "$LOAD_BALANCER_ARN" == "None" ]]; then
        echo "❌ ERROR: Load Balancer not found. Exiting..."
        exit 1
    fi

    # Delete Listeners
    echo "🔹 Deleting Listeners..."
    LISTENERS=$(aws elbv2 describe-listeners --load-balancer-arn $LOAD_BALANCER_ARN --query "Listeners[*].ListenerArn" --output text 2>/dev/null)
    if [[ -n "$LISTENERS" ]]; then
        for LISTENER in $LISTENERS; do
            aws elbv2 delete-listener --listener-arn $LISTENER
            echo "✅ Deleted Listener: $LISTENER"
        done
    fi

    # Delete Load Balancer
    echo "🔹 Deleting Load Balancer..."
    aws elbv2 delete-load-balancer --load-balancer-arn $LOAD_BALANCER_ARN
    echo "✅ Load Balancer deletion initiated: $LOAD_BALANCER_ARN"

    # Wait for Load Balancer deletion
    sleep 20

    # Delete Target Group only if it exists
    if [[ -n "$TARGET_GROUP_ARN" && "$TARGET_GROUP_ARN" != "None" ]]; then
        echo "🔹 Deleting Target Group..."
        aws elbv2 delete-target-group --target-group-arn $TARGET_GROUP_ARN
        echo "✅ Deleted Target Group: $TARGET_GROUP_ARN"
    else
        echo "⚠️ No Target Group found to delete."
    fi

    echo "🚀 Deletion complete!"

else
    echo "❌ Invalid option. Please enter 'create' or 'delete'."
    exit 1
fi
