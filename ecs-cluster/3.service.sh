#!/bin/bash

aws ecs create-service \
    --cluster expense \
    --service-name backend-node-service \
    --task-definition expense-backend \
    --desired-count 1 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-01899a28d9cd091c2],securityGroups=[sg-0c2026150f42233ac],assignPublicIp=ENABLED}" \
    --service-registries "registryArn=arn:aws:servicediscovery:us-east-1:522814728660:service/srv-soi3bloshikrmdmx"

# aws ecs create-service \
#     --cluster expense \
#     --service-name frontend-node-service \
#     --task-definition expense-frontend \
#     --desired-count 1 \
#     --launch-type FARGATE \
#     --network-configuration "awsvpcConfiguration={subnets=[subnet-01899a28d9cd091c2],securityGroups=[sg-0c2026150f42233ac],assignPublicIp=ENABLED}" \
#     --service-registries "registryArn=arn:aws:servicediscovery:us-east-1:522814728660:service/srv-fb7ouzaf2kla3sx7"