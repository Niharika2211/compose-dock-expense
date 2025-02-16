#!/bin/bash

# Function to upload task definitions
upload_task_definitions() {
    echo "Uploading task definitions to the ECS cluster..."
    
    scripts=("frontend-td.sh" "backend-td.sh")

    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            echo "Executing $script..."
            bash "$script"
            if [[ $? -ne 0 ]]; then
                echo "❌ Error: $script execution failed!"
                exit 1
            fi
        else
            echo "❌ Error: $script not found!"
        fi
    done

    echo "✅ Task definitions uploaded successfully!"
}

# Function to deregister task definitions
deregister_task_definitions() {
    echo "Deregistering task definitions from the ECS cluster..."

    task_definitions=("expense-frontend" "expense-backend")

    for task in "${task_definitions[@]}"; do
        # Get the latest revision of the task definition
        latest_revision=$(aws ecs list-task-definitions --family-prefix "$task" --sort DESC --query "taskDefinitionArns[0]" --output text)

        if [[ -n "$latest_revision" && "$latest_revision" != "None" ]]; then
            echo "Deregistering $latest_revision..."
            aws ecs deregister-task-definition --task-definition "$latest_revision"
        else
            echo "⚠️ Warning: No active task definition found for $task"
        fi
    done

    echo "✅ Task definitions deregistered successfully!"
}

# Ask user for action
echo "Do you want to UPLOAD or DEREGISTER task definitions? (Enter 'upload' or 'deregister')"
read ACTION

if [[ "$ACTION" == "upload" ]]; then
    upload_task_definitions
elif [[ "$ACTION" == "deregister" ]]; then
    deregister_task_definitions
else
    echo "❌ Invalid input. Please enter 'upload' or 'deregister'."
fi
