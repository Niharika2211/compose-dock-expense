#!/bin/bash

echo "creating ECS cluster"
aws ecs create-cluster --cluster-name expense


echo "creating log groups for backend and frontend"
aws logs create-log-group --log-group-name /ecs/siva-node-backend
aws logs create-log-group --log-group-name /ecs/siva-node-frontend

echo "creating serivce discovery for backend and frontend"
aws servicediscovery create-service \
    --name siva-node-backend \
    --namespace-id ns-asl6syvjpdvlthvc \
    --dns-config "NamespaceId=ns-asl6syvjpdvlthvc,RoutingPolicy=WEIGHTED,DnsRecords=[{Type=A,TTL=60}]"

aws servicediscovery create-service \
    --name siva-node-frontend \
    --namespace-id ns-asl6syvjpdvlthvc \
    --dns-config "NamespaceId=ns-asl6syvjpdvlthvc,RoutingPolicy=WEIGHTED,DnsRecords=[{Type=A,TTL=60}]"



   