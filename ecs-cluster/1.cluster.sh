#!/bin/bash

# Function to create ECS resources
create_resources() {
    echo "Creating ECS cluster..."
    aws ecs create-cluster --cluster-name expense

    echo "Creating log groups for backend and frontend..."
    aws logs create-log-group --log-group-name /ecs/siva-node-backend
    aws logs create-log-group --log-group-name /ecs/siva-node-frontend

    echo "Creating service discovery for backend and frontend..."
    aws servicediscovery create-service \
        --name backend-node \
        --namespace-id ns-asl6syvjpdvlthvc \
        --dns-config "NamespaceId=ns-asl6syvjpdvlthvc,RoutingPolicy=WEIGHTED,DnsRecords=[{Type=A,TTL=60}]"

    aws servicediscovery create-service \
        --name frontend-node \
        --namespace-id ns-asl6syvjpdvlthvc \
        --dns-config "NamespaceId=ns-asl6syvjpdvlthvc,RoutingPolicy=WEIGHTED,DnsRecords=[{Type=A,TTL=60}]"

    echo "✅ Resources created successfully."
}

# Function to delete ECS resources
delete_resources() {
    echo "Deleting ECS cluster and related resources..."

    echo "Deleting log groups..."
    aws logs delete-log-group --log-group-name /ecs/siva-node-backend
    aws logs delete-log-group --log-group-name /ecs/siva-node-frontend

    echo "Deleting service discovery services..."
    aws servicediscovery delete-service --id $(aws servicediscovery list-services --query "Services[?Name=='backend-node'].Id" --output text)
    aws servicediscovery delete-service --id $(aws servicediscovery list-services --query "Services[?Name=='frontend-node'].Id" --output text)

    echo "Deleting ECS cluster..."
    aws ecs delete-cluster --cluster expense

    echo "✅ Resources deleted successfully."
}

# Ask user for action
echo "Do you want to CREATE or DELETE the resources? (Enter 'create' or 'delete')"
read ACTION

if [[ "$ACTION" == "create" ]]; then
    create_resources
elif [[ "$ACTION" == "delete" ]]; then
    delete_resources
else
    echo "❌ Invalid input. Please enter 'create' or 'delete'."
fi
