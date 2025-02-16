#!/bin/bash

echo "Uploading task definitions to the ECS cluster"


scripts=("frontend-td.sh" "backend-td.sh")


for script in "${scripts[@]}"; do
    if [[ -f "$script" ]]; then
        echo "Executing $script..."
        bash "$script"
    else
        echo "Error: $script not found!"
    fi
done

echo "Task definitions uploaded successfully!"
