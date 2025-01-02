# MyDigital ID Server Setup

This document outlines the steps to setup the required files for the MyDigital ID server using the Docerrize version.

## Prerequisites

Before starting, ensure the following prerequisites are met:

- **Latest Docker Version**  
  Ensure Docker is installed and updated to the latest version. Docker is required for running tools like OpenSSL and `yq` via containerized images if they are not available locally.

- **OpenSSL (*Optional*)**  
  *Native OpenSSL is optional.* If not available locally, the scripts will automatically use Docker's Alpine-based OpenSSL image to execute OpenSSL commands.

- **`yq` (YAML Processor)**  
  *Native `yq` is optional but highly recommended.* The script uses `yq` to process YAML files.  
  - If `yq` is not installed, the script will default to using Docker's `mikefarah/yq` image to execute YAML operations.

- **Permissions**  
  To grant the scripts executable permissions, run the following commands:
  ```shell
  chmod +x init_keys.sh
  chmod +x finalize_keys.sh
  chmod +x populate_server_config.sh
  ```




## Required Keystore Files

The MyDigital ID server requires the following keystore files:

- **signetserver.jks**: Contains the PKCS12 of the MyDigital ID server.
- **signetserver_trustedca.jks**: Contains trusted root and intermediate CA certificates that sign the user certificate.

## Steps to Generate Keystores

### Installation

ssh
```shell
git clone git@github.com:redfieldchristabel/my-digital-id-signet.git 
```

https
```shell
git clone https://github.com/redfieldchristabel/my-digital-id-signet.git 
```

### Project Structure


Here’s how your project structure now look like:

```shell
project_root
├── README.md <-- its me
├── config.yaml
├── docker-compose.yml
├── init_keys.sh
├── finilize_keys.sh
└── populate_server_config.sh
```

Here’s how your project structure should look:

```shell
project_root
├── README.md <-- its me
├── config.yaml
├── docker-compose.yml
├── init_keys.sh
├── finilize_keys.sh
├── populate_server_config.sh
├── server-config.xml
├── keys
│ ├── signetserver.key 
│ ├── signetserver.csr 
│ ├── signetserver.pem <-- from My Digital ID
│ ├── signetserver.p12 
│ ├── signetserver.jks
| └── signetserver_trustedca.jks
```
Your stucture will look like this after completing all the step below


## Follow these steps to create and prepare the required keystore files:
### Step 1: Run init_keys.sh

Navigate to your project directory.
Run the init_keys.sh script:

```shell
./init_keys.sh
```

The script will:
- Check for or create the keys directory.
- Use OpenSSL (native or via Docker) to generate an elliptic curve (EC) private key and a CSR.

### Step 2: Request a Server Certificate

Send the generated signetserver.csr file to MyDigital ID Technical Support.
After receiving the certificate (signetserver.pem), place it in the keys directory.

### Step 3: Run finalize_keys.sh

Execute the finalize_keys.sh script:

```shell
./finalize_keys.sh
```

This script will:

- Combine signetserver.key and signetserver.pem into signetserver.p12.
- Convert signetserver.p12 to the PKCS12 format (signetserver.jks).


## What the script do in detail

### Prerequisites

- Ensure that OpenSSL is installed on your system.
- You have access to the terminal and permissions to execute commands.
- create the "server-config.xml" file wiht default value

### Step 1: Generate key
- Change directory to the `keys` directory.

- run the following command:
```shell
openssl ecparam -genkey -name prime256v1 -out signetserver.key
```

### Step 2: Generate CSR
- run the following command:
```shell
openssl req -new -key signetserver.key -out signetserver.csr
```

### Step 3: Request a Server Certificate
- send the CSR (signetserver.csr) file to MyDigital ID Technical Support for the issuance of the MyDigital ID server certificate.
- Once you receive the server certificate (named signetserver.pem), place it in the keys directory.
- Combine the PEM and Key into PKCS12 (step 4):

### Step 4: Combine PEM and Key into PKCS12
- run the following command:
```shell
 cat signetserver.key signetserver.pem>signetserver.p12
 ```

### Step 5: Convert PEM to PKCS12
- run the following command:
```shell
openssl pkcs12 -export -in signetserver.p12 -out signetserver.jks -name signetserver -noiter -nomaciter
```

### Step 6: Clean Up
- remove the PEM and Key files
- remove the PKCS12 file
- use the `keys/cleanup.sh` script to remove the key files

### Step 7: Generate Trusted CA Keystore
- To create the signetserver_trustedca.jks keystore, ensure you have the necessary CA certificates.
 Place the trusted root and intermediate CA certificates in the `keys/ca_certs` directory and
 run the following command from `keys` directory to generate the keystore:
- keytool -importcert -file ca_certs/<path_to_ca_certificate> -alias <alias_name> -keystore signetserver_trustedca.jks
- Replace <path_to_ca_certificate> and <alias_name> with the actual file path of your CA certificate and the desired alias name.

### Step 8: create server config file
- run the following command:
- cp server_config_template.xml server_config.xml

### Step 9: Configure server_config.xml
- Replace the placeholders in the server_config.xml file with the appropriate values.
