#!/bin/bash

echo "==========================================="
echo "       Step 0.1: Initialize Key Setup"
echo "==========================================="
echo ""

# Check for 'keys' directory
if [ ! -d "keys" ]; then
    mkdir keys
    echo "✅ Directory 'keys' created."
else
    echo "ℹ️  Directory 'keys' already exists."
fi

# Navigate to 'keys' directory
cd keys || {
    echo "❌ Failed to navigate to 'keys' directory. Exiting."
    exit 1
}

echo ""
echo "==========================================="
echo "       Step 0.2: Check for OpenSSL"
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

# Generate CSR
$OPENSSL_CMD req -new -key signetserver.key -out signetserver.csr
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
