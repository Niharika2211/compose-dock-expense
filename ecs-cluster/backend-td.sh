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
            "name": "shipping",
            "image": "siva9666/shipping-instana:v1",
            "essential": true,
            "environment": [
                {
                    "name": "DB_HOST",
                    "value": "mysql.instana"
                },
                {
                    "name": "DB_PORT",
                    "value": "3306"
                },
                {
                    "name": "DB_USER",
                    "value": "shipping" 
                },
                {
                    "name": "DB_PASSWD",
                    "value": "RoboShop@1"
                },
                {
                    "name": "CART_ENDPOINT",
                    "value": "cart.instana:8080"
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
                    "awslogs-group": "/ecs/shipping",
                    "awslogs-region": "us-east-1",
                    "awslogs-stream-prefix": "ecs"
                }
            }
        }
    ]'