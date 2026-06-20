#!/usr/bin/env bash

# 1. Validate argument count

if [ $# -ne 1 ]; then
	echo "Error: Missing environment argument."
	echo "Usage: $0 {dev|staging|prod}"
	exit 1
fi

#2. assign and validate teh envoriment typoe using case statment 
ENV_TYPE=$(echo "$1" | tr '[:upper:]' '[:lower:]')

case "$ENV_TYPE" in
	dev) 
		DB_HOST="localhost"
		DEBUG_MODE="true"
		LOG_LEVEL="debug"
		;;
	staging)
		DB_HOST="stg-db.techflow.internal"
		DEBUG_MODE="false"
		LOG_LEVEL="info"
		;;
	prod)
		DB_HOST="prod-db-cluster.techflow.internal"
		DEBUG_MODE="false"
		LOG_LEVEL="warn"
		;;
	*)
		echo "Error: Invalid enviroment '$1'."
		echo "Allowed options are: dev, staging, prod"
		exit 1
		;;
esac

#target DIR path "

TARGET_DIR="/tmp/techflow-$ENV_TYPE"

# 3 prompt user for cinfirmation before deploying 

echo "Prepering to configureation a [$ENV_TYPE] workspace at: $TARGET_DIR"
read -p "Do you want to proceed (Y/N): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
	echo "Setup canelled by user.."
	exit 0
fi

#4 , create directory stucture 

echo "Creating directory structure..."
mkdir -p "$TARGET_DIR"

# 5 . write the .env configuration uisng a heredoc

echo "Writing the .env configutaion...."
cat << EOF > "$TARGET_DIR/.env"
ENVIRONMENT=$ENV_TYPE
DB_HOST=$DB_HOST
DEBUG_MODE=$DEBUG_MODE
LOG_LEVEL=$LOG_LEVEL
CONFIG_GENERATED_AT=$(date "+%Y-%m-%d %H:%M:%S")
EOF

echo " Successfully set up $ENV_TYPE enviroment inside $TARGET_DIR/"

