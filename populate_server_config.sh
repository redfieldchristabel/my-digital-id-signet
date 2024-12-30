#!/bin/bash

echo "==========================================="
echo "     Step 1: Load Values from config.yaml"
echo "==========================================="
echo ""

# Check if yq is installed natively
if command -v yq >/dev/null 2>&1; then
    echo "✅ Native 'yq' found."
    YQ_CMD="yq"
else
    echo "⚠️ 'yq' not found. Using Docker 'mikefarah/yq'."
    YQ_CMD="docker run --rm -v $(pwd)/:/workdir mikefarah/yq"
fi

# Extract values using yq
PORT=$($YQ_CMD eval '.server.port' config.yaml)
MAX_CONNECTION=$($YQ_CMD eval '.server.max_connection' config.yaml)
SERVER_P12=$($YQ_CMD eval '.server.server_p12' config.yaml)
SERVER_P12_PIN=$($YQ_CMD eval '.server.server_p12_pin' config.yaml)
SERVER_ALIAS=$($YQ_CMD eval '.server.server_alias' config.yaml)
TRUSTED_CERT_STORE=$($YQ_CMD eval '.server.trusted_cert_store' config.yaml)
TRUSTED_CERT_STORE_PIN=$($YQ_CMD eval '.server.trusted_cert_store_pin' config.yaml)

DB_TYPE=$($YQ_CMD eval '.server.db.type' config.yaml)
DB_USERNAME=$($YQ_CMD eval '.server.db.username' config.yaml)
DB_PASSWORD=$($YQ_CMD eval '.server.db.password' config.yaml)
DB_HOST=$($YQ_CMD eval '.server.db.host' config.yaml)
DB_DRIVER=$($YQ_CMD eval '.server.db.driver' config.yaml)
DB_NAME=$($YQ_CMD eval '.server.db.name' config.yaml)
DB_MAX_TOTAL_CONNECTION=$($YQ_CMD eval '.server.db.max_total_connection' config.yaml)
DB_MAX_IDLE_CONNECTION=$($YQ_CMD eval '.server.db.max_idle_connection' config.yaml)
DB_IDLE_CONNECTION_TIMEOUT=$($YQ_CMD eval '.server.db.idle_connection_timeout' config.yaml)
DB_CONNECTION_MAX_WAIT_TIMEOUT=$($YQ_CMD eval '.server.db.connection_max_wait_timeout' config.yaml)

echo "==========================================="
echo "     Step 2: Check if server_config.xml Exists"
echo "==========================================="
echo ""

# Check if the XML file exists
if [ -f "server_config.xml" ]; then
    echo "ℹ️  'server_config.xml' already exists."

    # Check if the file is writable
    if [ ! -w "server_config.xml" ]; then
        echo "❌ 'server_config.xml' is not writable. Please check the file permissions."
        exit 1
    else
        echo "✅ 'server_config.xml' is writable."
        
        # Ask if user wants to update the existing file
        read -p "Do you want to update the existing 'server_config.xml'? (y/n): " update_choice

        # If user opts to update, continue, else skip
        if [[ "$update_choice" =~ ^[Yy]$ ]]; then
            echo "ℹ️ Proceeding to update the 'server_config.xml' file."
        else
            echo "ℹ️ Skipping the update process for 'server_config.xml'."
            exit 0
        fi
    fi
else
    echo "ℹ️ 'server_config.xml' not found. Creating the file."
fi

echo "==========================================="
echo "     Step 3: Populate the XML File"
echo "==========================================="
echo ""

# Ensure the XML declaration is added at the beginning
echo '<?xml version="1.0"?>' > server_config.xml

# Use yq to replace the XML values by extracting each value from the config.yaml and modifying the XML file.
$YQ_CMD eval --inplace ".Server_Properties.Port = \"$PORT\"" server_config.xml
$YQ_CMD eval --inplace ".Server_Properties.Max_Connection = \"$MAX_CONNECTION\"" server_config.xml
$YQ_CMD eval --inplace ".Server_Properties.Server_P12 = \"$SERVER_P12\"" server_config.xml
$YQ_CMD eval --inplace ".Server_Properties.Server_P12_PIN = \"$SERVER_P12_PIN\"" server_config.xml
$YQ_CMD eval --inplace ".Server_Properties.Server_Alias = \"$SERVER_ALIAS\"" server_config.xml
$YQ_CMD eval --inplace ".Server_Properties.TrustedCertStore = \"$TRUSTED_CERT_STORE\"" server_config.xml
$YQ_CMD eval --inplace ".Server_Properties.TrustedCertStore_PIN = \"$TRUSTED_CERT_STORE_PIN\"" server_config.xml

# Modify the DB values
$YQ_CMD eval --inplace ".Server_Properties.DB_Properties.DB_Type = \"$DB_TYPE\"" server_config.xml
$YQ_CMD eval --inplace ".Server_Properties.DB_Properties.DB_Username = \"$DB_USERNAME\"" server_config.xml
$YQ_CMD eval --inplace ".Server_Properties.DB_Properties.DB_Password = \"$DB_PASSWORD\"" server_config.xml
$YQ_CMD eval --inplace ".Server_Properties.DB_Properties.DB_Host = \"$DB_HOST\"" server_config.xml
$YQ_CMD eval --inplace ".Server_Properties.DB_Properties.DB_Driver = \"$DB_DRIVER\"" server_config.xml
$YQ_CMD eval --inplace ".Server_Properties.DB_Properties.DB_Name = \"$DB_NAME\"" server_config.xml
$YQ_CMD eval --inplace ".Server_Properties.DB_Properties.DB_MaxTotalConnection = \"$DB_MAX_TOTAL_CONNECTION\"" server_config.xml
$YQ_CMD eval --inplace ".Server_Properties.DB_Properties.DB_MaxIdleConnection = \"$DB_MAX_IDLE_CONNECTION\"" server_config.xml
$YQ_CMD eval --inplace ".Server_Properties.DB_Properties.DB_IdleConnectionTimeout = \"$DB_IDLE_CONNECTION_TIMEOUT\"" server_config.xml
$YQ_CMD eval --inplace ".Server_Properties.DB_Properties.DB_ConnectionMaxWaitTimeout = \"$DB_CONNECTION_MAX_WAIT_TIMEOUT\"" server_config.xml

echo "✅ XML populated successfully."

echo "==========================================="
echo "     Step 4: Update Docker Compose for MySQL"
echo "==========================================="
echo ""


# Update MySQL configuration in docker-compose.yml using yq
$YQ_CMD eval -i ".services.mysql.environment.MYSQL_DATABASE = \"$DB_NAME\"" docker-compose.yml
$YQ_CMD eval -i ".services.mysql.environment.MYSQL_USER = \"$DB_USERNAME\"" docker-compose.yml
$YQ_CMD eval -i ".services.mysql.environment.MYSQL_PASSWORD = \"$DB_PASSWORD\"" docker-compose.yml

echo "✅ docker-compose.yml updated successfully with database configuration from config.yaml."
