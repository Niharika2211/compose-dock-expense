#!/bin/bash

# Function to fetch Cloud Map service ARNs dynamically
fetch_service_arn() {
    local service_name=$1
    aws servicediscovery list-services --query "Services[?Name=='$service_name'].Arn" --output text
}

# Function to create ECS services
create_services() {
    echo "Creating ECS services..."

    # Fetch Cloud Map service ARNs dynamically for backend-node and frontend-node
    backend_service_arn=$(fetch_service_arn "backend-node")
    frontend_service_arn=$(fetch_service_arn "frontend-node")

    if [[ -z "$backend_service_arn" || -z "$frontend_service_arn" ]]; then
        echo "❌ Error: Failed to fetch Cloud Map service ARNs"
        exit 1
    fi

    services=(
        "backend-node-service expense-backend $backend_service_arn"
        "frontend-node-service expense-frontend $frontend_service_arn"
    )

    for service in "${services[@]}"; do
        read -r service_name task_definition service_registry <<< "$service"
        echo "Creating service: $service_name"

        aws ecs create-service \
            --cluster expense \
            --service-name "$service_name" \
            --task-definition "$task_definition" \
            --desired-count 1 \
            --launch-type FARGATE \
            --network-configuration "awsvpcConfiguration={subnets=[subnet-01899a28d9cd091c2],securityGroups=[sg-0c2026150f42233ac],assignPublicIp=ENABLED}" \
            --service-registries "registryArn=$service_registry"

        if [[ $? -ne 0 ]]; then
            echo "❌ Error: Failed to create service $service_name"
            exit 1
        fi

        # Wait for 15 seconds after deploying the backend service
        if [[ "$service_name" == "backend-node-service" ]]; then
            echo "⏳ Waiting for 15 seconds to let the backend service stabilize..."
            sleep 15
        fi
    done

    echo "✅ ECS services created successfully!"
}

# Function to delete ECS services
delete_services() {
    echo "Deleting ECS services..."

    services=("backend-node-service" "frontend-node-service")

    for service in "${services[@]}"; do
        echo "Deleting service: $service"

        aws ecs update-service --cluster expense --service "$service" --desired-count 0

        aws ecs delete-service --cluster expense --service "$service" --force

        if [[ $? -ne 0 ]]; then
            echo "❌ Error: Failed to delete service $service"
            exit 1
        fi
    done

    echo "✅ ECS services deleted successfully!"
}

# Ask user for action
echo "Do you want to CREATE or DELETE ECS services? (Enter 'create' or 'delete')"
read ACTION

if [[ "$ACTION" == "create" ]]; then
    create_services
elif [[ "$ACTION" == "delete" ]]; then
    delete_services
else
    echo "❌ Invalid input. Please enter 'create' or 'delete'."
fi
