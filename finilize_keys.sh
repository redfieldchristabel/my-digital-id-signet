#!/bin/bash

echo "Chnage to the 'keys' directory"
cd keys

echo "==========================================="
echo "         Step 4: Combine Files"
echo "==========================================="

# Check for the required files
if [ ! -f "signetserver.key" ] || [ ! -f "signetserver.pem" ]; then
    echo "❌ Error: Required files 'signetserver.key' and 'signetserver.pem' are missing in the 'keys' directory."
    echo "   Please ensure these files exist and run the script again."
    exit 1
fi

# Combine the key and PEM
cat signetserver.key signetserver.pem > signetserver.p12
if [ $? -eq 0 ]; then
    echo "✅ Combined 'signetserver.key' and 'signetserver.pem' into 'signetserver.p12'."
else
    echo "❌ Failed to combine the files."
    exit 1
fi

echo ""
echo "==========================================="
echo "      Step 5: Convert to PKCS12 Format"
echo "==========================================="

# Convert to PKCS12 (.jks)
openssl pkcs12 -export -in signetserver.p12 -out signetserver.jks -name signetserver -noiter -nomaciter
if [ $? -eq 0 ]; then
    echo "✅ Converted to PKCS12 format: 'signetserver.jks'."
else
    echo "❌ Failed to convert to PKCS12 format."
    exit 1
fi

echo ""
echo "🎉 Finalization Complete!"
echo "==========================================="
echo "You can now use 'signetserver.jks' as needed."
echo "==========================================="
