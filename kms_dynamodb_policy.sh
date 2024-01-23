#!/bin/bash

# Variables
DYNAMODB_TABLE="VaultStorage"          # Replace with your preferred DynamoDB table name
AWS_REGION="us-east-1"                 # Replace with your preferred AWS region
KMS_KEY_ALIAS="alias/vault-auto-unseal"    # KMS Key alias


# Function to check if DynamoDB table exists
check_dynamodb_table() {
    aws dynamodb describe-table --table-name $DYNAMODB_TABLE --region $AWS_REGION 2>/dev/null
}

# Function to check if KMS key exists
check_kms_key() {
    aws kms describe-key --key-id $KMS_KEY_ALIAS --region $AWS_REGION 2>/dev/null
}

# Function to create DynamoDB table
create_dynamodb_table() {
    aws dynamodb create-table \
        --table-name $DYNAMODB_TABLE \
        --attribute-definitions AttributeName=Key,AttributeType=S \
        --key-schema AttributeName=Key,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region $AWS_REGION
}

# Function to create KMS key
create_kms_key() {
    aws kms create-key \
        --description "KMS key for Vault" \
        --region $AWS_REGION
    aws kms create-alias \
        --alias-name $KMS_KEY_ALIAS \
        --target-key-id $(aws kms list-keys --query 'Keys[0].KeyId' --output text) \
        --region $AWS_REGION
}

# Check and handle existing DynamoDB table
if check_dynamodb_table; then
    read -p "DynamoDB table $DYNAMODB_TABLE already exists. Delete and recreate? (yes/no): " response
    if [ "$response" == "yes" ]; then
        aws dynamodb delete-table --table-name $DYNAMODB_TABLE --region $AWS_REGION
        create_dynamodb_table
    else
        echo "Exiting without creating DynamoDB table."
        exit 1
    fi
else
    create_dynamodb_table
fi

# Check and handle existing KMS key
if check_kms_key; then
    read -p "KMS key $KMS_KEY_ALIAS already exists. Delete and recreate? (yes/no): " response
    if [ "$response" == "yes" ]; then
        aws kms disable-key --key-id $KMS_KEY_ALIAS --region $AWS_REGION
        aws kms schedule-key-deletion --key-id $KMS_KEY_ALIAS --pending-window-in-days 7 --region $AWS_REGION
        create_kms_key
    else
        echo "Exiting without creating KMS key."
        exit 1
    fi
else
    create_kms_key
fi

echo "Resources created successfully."
