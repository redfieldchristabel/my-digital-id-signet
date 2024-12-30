#!/bin/bash

echo "==========================================="
echo "       Step 0.1: Check Docker Availability"
echo "==========================================="
echo ""

# Check if Docker is installed
if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Docker is not installed. Please install Docker to continue."
    exit 1
else
    echo "✅ Docker is installed."
fi
echo "==========================================="
echo "       Step 0.2: Initialize Key Setup"
echo "==========================================="
echo ""

# Check for 'keys' directory
if [ ! -d "keys" ]; then
    mkdir keys
    echo "✅ Directory 'keys' created."
else
    echo "ℹ️  Directory 'keys' already exists."
fi

# Check if the 'keys' directory is writable
if [ ! -w "keys" ]; then
    echo "❌ 'keys' directory is not writable. Please check permissions."
    exit 1
fi

# Navigate to 'keys' directory
cd keys || {
    echo "❌ Failed to navigate to 'keys' directory. Exiting."
    exit 1
}

echo ""
echo "==========================================="
echo "       Step 0.3: Check for Existing Key and CSR"
echo "==========================================="
echo ""

# Check if the key or CSR already exists
if [ -f "signetserver.key" ] || [ -f "signetserver.csr" ]; then
    read -p "Key or CSR already exists. Do you want to regenerate them? (y/n): " REGENERATE
    if [[ "$REGENERATE" =~ ^[Yy]$ ]]; then
        rm -f signetserver.key signetserver.csr
        echo "✅ Files removed. Continuing with key and CSR generation."
    else
        echo "ℹ️ Skipping generation of key and CSR."
    fi
fi

echo ""
echo "==========================================="
echo "       Step 0.4: Check for OpenSSL"
echo "==========================================="
echo ""

# Check for 'openssl' command
if command -v openssl >/dev/null 2>&1; then
    echo "✅ Native 'openssl' found. Proceeding with it."
    OPENSSL_CMD="openssl"
else
    echo "⚠️  'openssl' not found. Using Docker 'alpine/openssl'."
    OPENSSL_CMD="docker run --rm -v $(pwd):/data alpine/openssl"
fi

echo ""
echo "==========================================="
echo "        Step 0.5: Load Config from YAML"
echo "==========================================="
echo ""

# Check if yq is installed natively
if command -v yq >/dev/null 2>&1; then
    echo "✅ Native 'yq' found."
    YQ_CMD="yq"
else
    echo "⚠️ 'yq' not found. Using Docker 'mikefarah/yq'."
    YQ_CMD="docker run --rm -v $(pwd)/../:/workdir mikefarah/yq"
fi

# Check for 'identifier' key in config.yaml
IDENTIFIER=$($YQ_CMD eval '.identifier' config.yaml)

if [ "$IDENTIFIER" == "REMOVE_ME" ]; then
    echo "❌ You must remove or modify the 'identifier' key in the config.yaml file to continue."
    echo "Please make sure you've edited the file properly and removed the placeholder."
    exit 1
else
    echo "✅ 'identifier' key has been removed or modified. Proceeding..."
fi

# Read values from the YAML config file
COUNTRY=$($YQ_CMD eval '.ssl_params.country' config.yaml)
STATE=$($YQ_CMD eval '.ssl_params.state' config.yaml)
LOCALITY=$($YQ_CMD eval '.ssl_params.locality' config.yaml)
ORGANIZATION=$($YQ_CMD eval '.ssl_params.organization' config.yaml)
ORG_UNIT=$($YQ_CMD eval '.ssl_params.organizational_unit' config.yaml)
COMMON_NAME=$($YQ_CMD eval '.ssl_params.common_name' config.yaml)
EMAIL=$($YQ_CMD eval '.ssl_params.email_address' config.yaml)

# Ensure all required fields are populated
if [ -z "$COUNTRY" ] || [ -z "$STATE" ] || [ -z "$LOCALITY" ] || [ -z "$ORGANIZATION" ] || [ -z "$ORG_UNIT" ] || [ -z "$COMMON_NAME" ] || [ -z "$EMAIL" ]; then
    echo "❌ Missing values in the configuration. Please ensure the YAML file is properly populated."
    exit 1
fi

# Construct the subject string
SUBJ="/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORG_UNIT/CN=$COMMON_NAME/emailAddress=$EMAIL"


echo ""
echo "==========================================="
echo "     Step 0.6: Populate server_config.xml"
echo "==========================================="
echo ""

# Run the populate_server_config.sh script to populate XML file
if [ -f "populate_server_config.sh" ]; then
    echo "ℹ️  Running 'populate_server_config.sh' to populate server_config.xml..."
    ./populate_server_config.sh
    if [ $? -eq 0 ]; then
        echo "✅ 'server_config.xml' has been populated successfully."
    else
        echo "❌ There was an error in populating 'server_config.xml'. Exiting."
        exit 1
    fi
else
    echo "❌ 'populate_server_config.sh' script not found. Please ensure it's present in the current directory."
    exit 1
fi

echo ""
echo "==========================================="
echo "    Step 1: Generate EC Private Key"
echo "==========================================="
echo ""

# Generate EC private key
$OPENSSL_CMD ecparam -genkey -name prime256v1 -out signetserver.key
if [ $? -eq 0 ]; then
    echo "✅ EC private key 'signetserver.key' generated successfully."
else
    echo "❌ Failed to generate EC private key. Exiting."
    exit 1
fi

echo ""
echo "==========================================="
echo "   Step 2: Generate Certificate Signing Request (CSR)"
echo "==========================================="
echo ""

# Generate CSR using the subject string
$OPENSSL_CMD req -new -key signetserver.key -out signetserver.csr -subj "$SUBJ"
if [ $? -eq 0 ]; then
    echo "✅ CSR 'signetserver.csr' generated successfully."
else
    echo "❌ Failed to generate CSR. Exiting."
    exit 1
fi

echo ""
echo "==========================================="
echo "        Step 3: Request a Server Certificate"
echo "==========================================="
echo ""
echo "1️⃣ Send the CSR file (signetserver.csr) to MyDigital ID Technical Support."
echo ""
echo "2️⃣ Once you receive the server certificate (signetserver.pem),"
echo "   place it in the 'keys' directory."
echo ""
echo "✅ Next Step:"
echo "   Run the second script ('finalize_keys.sh') to combine the key and certificate."
echo ""
echo "==========================================="
