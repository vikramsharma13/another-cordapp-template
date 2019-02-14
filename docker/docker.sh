#!/usr/bin/env bash

docker kill $(docker ps -q)
docker rm $(docker ps -a -q)

#### Parse participant names from text file ####
NODE_LIST=($(cat participants.txt |tr "\n" " "))
nodeListlength=${#NODE_LIST}

#### START CORDAPP SETUP ####
mkdir cordapps
rm -f cordapps/*

wget -O cordapps/finance-contracts.jar          https://ci-artifactory.corda.r3cev.com/artifactory/list/corda-dev/net/corda/corda-finance-contracts/4.0-SNAPSHOT/corda-finance-contracts-4.0-SNAPSHOT.jar
wget -O cordapps/finance-workflows.jar          https://ci-artifactory.corda.r3cev.com/artifactory/list/corda-dev/net/corda/corda-finance-workflows/4.0-SNAPSHOT/corda-finance-workflows-4.0-SNAPSHOT.jar
wget -O cordapps/confidential-identities.jar    https://ci-artifactory.corda.r3cev.com/artifactory/list/corda-dev/net/corda/corda-confidential-identities/4.0-SNAPSHOT/corda-confidential-identities-4.0-SNAPSHOT.jar
#### END CORDAPP SETUP####

#### BEGIN SIGNING SETUP ####

rm keystore

keytool -genkey -noprompt \
  -alias alias1 \
  -dname "CN=totally_not_r3, OU=ID, O=definitely_not_r3, L=LONDON, S=LONDON, C=GB" \
  -keystore keystore \
  -storepass password \
  -keypass password \
  -keyalg EC \
  -keysize 256 \
  -sigalg SHA256withECDSA

jarsigner -keystore keystore -storepass password -keypass password cordapps/finance-workflows.jar alias1
jarsigner -keystore keystore -storepass password -keypass password cordapps/finance-contracts.jar alias1
jarsigner -keystore keystore -storepass password -keypass password cordapps/confidential-identities.jar alias1

#### END SIGNING SETUP ####

#### START NODE DIR SETUP ####

for NODE in ${NODE_LIST[*]}
do
    echo Building ${NODE} directory
    rm -rf ${NODE}
    mkdir ${NODE}
    mkdir ${NODE}/config
    mkdir ${NODE}/certificates
    mkdir ${NODE}/logs
    mkdir ${NODE}/persistence
done


NETWORK_NAME=mininet
docker rm -f  netmap
docker network rm ${NETWORK_NAME}

docker network create --attachable ${NETWORK_NAME}
docker run -d \
            -p 18080:8080 \
            -p 10200:10200 \
            --name netmap \
            -e PUBLIC_ADDRESS=netmap \
            --network="${NETWORK_NAME}" \
            roastario/notary-and-network-map:latest

let EXIT_CODE=255
while [ ${EXIT_CODE} -gt 0 ]
do
    sleep 2
    echo "Waiting for network map to start"
    curl -s http://localhost:18080/network-map > /dev/null
    let EXIT_CODE=$?
done

for (( i=0; i<=nodeListlength; i++ ));
do
    NODE=${NODE_LIST[i]}
    wget -O ${NODE}/certificates/network-root-truststore.jks http://localhost:18080/truststore
    docker rm -f ${NODE}
    docker run \
            -e MY_LEGAL_NAME="O=${NODE},L=Berlin,C=DE"     \
            -e MY_PUBLIC_ADDRESS="${NODE}"                \
            -e NETWORKMAP_URL="http://netmap:8080"      \
            -e DOORMAN_URL="http://netmap:8080"         \
            -e NETWORK_TRUST_PASSWORD="trustpass"       \
            -e MY_EMAIL_ADDRESS="${NODE}@r3.com"      \
            -e MY_RPC_PORT="1100"${i}  \
            -e RPC_PASSWORD="testingPassword" \
            -v $(pwd)/${NODE}/config:/etc/corda          \
            -v $(pwd)/${NODE}/certificates:/opt/corda/certificates \
            -v $(pwd)/${NODE}/logs:/opt/corda/logs \
            --name ${NODE} \
            --network="${NETWORK_NAME}" \
            corda/corda-zulu-4.0-rc02:latest config-generator --generic

    docker rm -f ${NODE}
    docker run -d \
            --memory=2048m \
            --cpus=2 \
            -v $(pwd)/${NODE}/config:/etc/corda          \
            -v $(pwd)/${NODE}/certificates:/opt/corda/certificates \
            -v $(pwd)/${NODE}/logs:/opt/corda/logs \
            -v $(pwd)/${NODE}/persistence:/opt/corda/persistence \
            -v $(pwd)/cordapps:/opt/corda/cordapps \
            -p "1100"${i}:"1100"${i} \
            -p "222"${i}:"222"${i} \
            -e CORDA_ARGS="--sshd --sshd-port=222"${i} \
            --name ${NODE} \
            --network="${NETWORK_NAME}" \
            corda/corda-zulu-4.0-rc02:latest
done

