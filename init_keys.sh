if [ ! -d "keys" ]; then
    mkdir keys
    echo "Directory 'keys' created."
else
    echo "Directory 'keys' already exists."
fi

cd keys || { echo "Failed to navigate to 'keys' directory."; exit 1; }

if command -v openssl >/dev/null 2>&1; then
    echo "Using native 'openssl'."
    OPENSSL_CMD="openssl"
else
    echo "Using Docker 'alpine/openssl'."
    OPENSSL_CMD="docker run --rm -v $(pwd):/data alpine/openssl"
fi

$OPENSSL_CMD ecparam -genkey -name prime256v1 -out signetserver.key
if [ $? -eq 0 ]; then
    echo "EC private key 'signetserver.key' generated successfully."
else
    echo "Failed to generate EC private key."
    exit 1
fi

$OPENSSL_CMD req -new -key signetserver.key -out signetserver.csr
if [ $? -eq 0 ]; then
    echo "CSR 'signetserver.csr' generated successfully."
else
    echo "Failed to generate CSR."
    exit 1
fi

echo "Step 3: Request a Server Certificate"
echo ""
echo "Send the CSR (signetserver.csr) file to MyDigital ID Technical Support for the issuance of the server certificate."
echo "Once you receive the server certificate (named 'signetserver.pem'), place it in the 'keys' directory."
echo ""
echo "Next, run the second script ('finalize_keys.sh') to combine the key and certificate."

