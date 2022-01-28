#!/bin/sh

# Root Certificate Authority
if [ -f "${OUTPUT_PATH}/${ROOT_FILENAME}.key" ]; then
    echo "'${OUTPUT_PATH}/${ROOT_FILENAME}.key' already exists"
else
    echo "'${OUTPUT_PATH}/${ROOT_FILENAME}.key'..."
    openssl genrsa -out "${OUTPUT_PATH}/${ROOT_FILENAME}.key" 4096
    openssl req -x509 -new -nodes \
        -key "${OUTPUT_PATH}/${ROOT_FILENAME}.key" \
        -subj "/C=${COUNTRY_NAME}/ST=${STATE_NAME}/L=${LOCALITY_NAME}/O=${ORGANIZATION_NAME}/CN=${ORGANIZATION_NAME} CA" \
        -sha256 \
        -days ${ROOT_VALIDITY_DAYS} \
        -out "${OUTPUT_PATH}/${ROOT_FILENAME}.crt"
fi

if [ -f "${OUTPUT_PATH}/${CERT_FILENAME}.key" ]; then
    echo "'${OUTPUT_PATH}/${CERT_FILENAME}.key' already exists"
else
    echo "'${OUTPUT_PATH}/${CERT_FILENAME}.key'... '${OUTPUT_PATH}/${CERT_FILENAME}.crt'..."

    # Create new certificate configuration file
    export requestConfig="
    [ req ]
    default_bits            = 4096
    distinguished_name	    = req_distinguished_name
    req_extensions          = req_ext

    [ req_distinguished_name ]
    countryName			        = Country Name (2 letter code)

    stateOrProvinceName		  = State or Province Name (full name)

    localityName			      = Locality Name (eg, city)

    organizationalUnitName  = Organizational Unit Name (eg, section)

    commonName			        = Common Name (e.g. server FQDN or YOUR name)

    emailAddress			      = Email Address

    [ req_ext ]
    subjectAltName          = @alt_names

    [ alt_names ]
    DNS.1                   = *.*.${COMMON_NAME}
    "

    # Create server config
    echo "${requestConfig}" | tee "${OUTPUT_PATH}/${CERT_FILENAME}.cfg"

    # Create server key
    openssl genrsa -out "${OUTPUT_PATH}/${CERT_FILENAME}.key" 4096

    # Create the certificate request
    openssl req -new -sha256 \
            -subj "/C=$COUNTRY_NAME/ST=$STATE_NAME/L=$LOCALITY_NAME/O=$ORGANIZATION_NAME/CN=$COMMON_NAME/emailAddress=$EMAIL" \
            -out "${OUTPUT_PATH}/${CERT_FILENAME}.csr" \
            -key "${OUTPUT_PATH}/${CERT_FILENAME}.key" \
            -config "${OUTPUT_PATH}/${CERT_FILENAME}.cfg"

    # Validate the certificate request
    openssl req -text -noout -in "${OUTPUT_PATH}/${CERT_FILENAME}.csr"

    # Create the certificate
    openssl x509 -req \
        -sha256 \
        -days ${CERT_VALIDITY_DAYS} \
        -in "${OUTPUT_PATH}/${CERT_FILENAME}.csr" \
        -CA "${OUTPUT_PATH}/${ROOT_FILENAME}.crt" \
        -CAkey "${OUTPUT_PATH}/${ROOT_FILENAME}.key" \
        -CAcreateserial \
        -out "${OUTPUT_PATH}/${CERT_FILENAME}.crt" \
        -extensions req_ext \
        -extfile "${OUTPUT_PATH}/${CERT_FILENAME}.cfg"

    # Validate the certificate
    openssl x509 -in "${OUTPUT_PATH}/${CERT_FILENAME}.crt" -noout -text

    # Change permission to read / write all
    chmod 777 -R "${OUTPUT_PATH}/"
fi
