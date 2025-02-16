#!/bin/bash

echo "creating ECS cluster"
aws ecs create-cluster --cluster-name expense


echo "creating log groups for backend and frontend"
aws logs create-log-group --log-group-name /ecs/siva-node-backend
aws logs create-log-group --log-group-name /ecs/siva-node-frontend

echo "creating serivce discovery for backend and frontend"
aws servicediscovery create-service \
    --name backend-node \
    --namespace-id ns-asl6syvjpdvlthvc \
    --dns-config "NamespaceId=ns-asl6syvjpdvlthvc,RoutingPolicy=WEIGHTED,DnsRecords=[{Type=A,TTL=60}]"

aws servicediscovery create-service \
    --name frontend-node \
    --namespace-id ns-asl6syvjpdvlthvc \
    --dns-config "NamespaceId=ns-asl6syvjpdvlthvc,RoutingPolicy=WEIGHTED,DnsRecords=[{Type=A,TTL=60}]"
echo "Uploading task definitions"






# - creating ALB
# - creating TG on port 80
# - Create Listners 443 and 80
# - update the service with frontend-service



# - create cluster
# - create log groups for containers
# - create iam role for containers
# - create cloud map for each container
# - create and upload task definition for each micro service
# - create service for each td
# - create tg group for frontend containers
# - create ALB
# - create Listner 80,443 in ALB
# - create redirect rule in listner 80 to 443
# - create rule in 443 ecs-expense.konkas.tech forward to above TG




   