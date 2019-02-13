#!/usr/bin/env bash
NODE_LIST=("dockerNode1" "dockerNode2" "dockerNode3")
NETWORK_NAME=mininet
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

for NODE in ${NODE_LIST[*]}
do
    wget -O ${NODE}/certificates/network-root-truststore.jks http://localhost:18080/truststore
    docker rm -f ${NODE}
    docker run \
            -e MY_LEGAL_NAME="O=${NODE},L=Berlin,C=DE"     \
            -e MY_PUBLIC_ADDRESS="${NODE}"                \
            -e NETWORKMAP_URL="http://netmap:8080"      \
            -e DOORMAN_URL="http://netmap:8080"         \
            -e NETWORK_TRUST_PASSWORD="trustpass"       \
            -e MY_EMAIL_ADDRESS="${NODE}@r3.com"      \
            -e MY_RPC_PORT="1100"$(echo ${NODE} | sed 's/[^0-9]*//g')  \
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
            -p "1100"$(echo ${NODE} | sed 's/[^0-9]*//g'):"1100"$(echo ${NODE} | sed 's/[^0-9]*//g') \
            -p "222$(echo ${NODE} | sed 's/[^0-9]*//g')":"222$(echo ${NODE} | sed 's/[^0-9]*//g')" \
            -e CORDA_ARGS="--sshd --sshd-port=222$(echo ${NODE} | sed 's/[^0-9]*//g')" \
            --name ${NODE} \
            --network="${NETWORK_NAME}" \
            corda/corda-zulu-4.0-rc02:latest
done

#ssh -o StrictHostKeyChecking=no rpcUser@localhost -p 2221
#<password>
#run vaultQuery contractStateType: net.corda.finance.contracts.asset.Cash$State
#start net.corda.finance.flows.CashIssueFlow amount: $111111, issuerBankPartyRef: 0x01, notary: Notary
#start net.corda.finance.flows.CashPaymentFlow amount: $500, recipient: "dockerNode2"
#start net.corda.finance.flows.CashPaymentFlow amount: $500, recipient: "dockerNode3"
#
#ssh -o StrictHostKeyChecking=no rpcUser@localhost -p 2222
#<password>
#start net.corda.finance.flows.CashPaymentFlow amount: $200, recipient: "dockerNode1"
#start net.corda.finance.flows.CashPaymentFlow amount: $100, recipient: "dockerNode3"
#
#ssh -o StrictHostKeyChecking=no rpcUser@localhost -p 2223
#<password>
#start net.corda.finance.flows.CashPaymentFlow amount: $200, recipient: "dockerNode1"