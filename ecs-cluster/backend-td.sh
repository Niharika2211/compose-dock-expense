#!/bin/bash
aws ecs register-task-definition \
    --family expense-backend \
    --network-mode awsvpc \
    --requires-compatibilities FARGATE \
    --cpu "256" \
    --memory "512" \
    --execution-role-arn arn:aws:iam::522814728660:role/ecsTaskExecutionRole1 \
    --container-definitions '[
        {
            "name": "backend-node",
            "image": "siva9666/expense-backend:node",
            "essential": true,
            "environment": [
                {
                    "name": "DB_HOST",
                    "value": "test-db.konkas.tech"
                },
                {
                    "name": "DB_USER",
                    "value": "expense" 
                },
                {
                    "name": "DB_PASSWD",
                    "value": "ExpenseApp@1"
                },
                {
                    "name": "DB_DATABASE",
                    "value": "transactions"
                }
            ],
            "portMappings": [
                {
                    "containerPort": 8080,
                    "protocol": "tcp"
                }
            ],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "/ecs/siva-node-backend",
                    "awslogs-region": "us-east-1",
                    "awslogs-stream-prefix": "ecs"
                }
            }
        }
    ]'