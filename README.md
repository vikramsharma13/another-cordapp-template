<p align="center">
  <img src="https://www.corda.net/wp-content/uploads/2016/11/fg005_corda_b.png" alt="Corda" width="500">
</p>

# CorDapp Client Template - Kotlin

Welcome to the Kotlin CorDapp template. The CorDapp template is a stubbed-out CorDapp that you can use to bootstrap 
your own CorDapps.

# Pre-Requisites

See https://docs.corda.net/getting-set-up.html.

# Usage

## Running the nodes

See https://docs.corda.net/tutorial-cordapp.html#running-the-example-cordapp.

This can be done simply by running the two scripts in the `script` folder. You might need to changed the file permissions first to do so.

    cd scripts
    chmod +x deployNodes.sh runNodes.sh 
    ./deployNodes.sh 
    ./runNodes.sh

## Interacting with the nodes

### Shell

When started via the command line, each node will display an interactive shell:

    Welcome to the Corda interactive shell.
    Useful commands include 'help' to see what is available, and 'bye' to shut down the node.
    
    Tue Nov 06 11:58:13 GMT 2018>>>

You can use this shell to interact with your node. For example, enter `run networkMapSnapshot` to see a list of 
the other nodes on the network:

    Tue Nov 06 11:58:13 GMT 2018>>> run networkMapSnapshot
    [
      {
      "addresses" : [ "localhost:10002" ],
      "legalIdentitiesAndCerts" : [ "O=Notary, L=London, C=GB" ],
      "platformVersion" : 3,
      "serial" : 1541505484825
    },
      {
      "addresses" : [ "localhost:10005" ],
      "legalIdentitiesAndCerts" : [ "O=PartyA, L=London, C=GB" ],
      "platformVersion" : 3,
      "serial" : 1541505382560
    },
      {
      "addresses" : [ "localhost:10008" ],
      "legalIdentitiesAndCerts" : [ "O=PartyB, L=New York, C=US" ],
      "platformVersion" : 3,
      "serial" : 1541505384742
    }
    ]
    
    Tue Nov 06 12:30:11 GMT 2018>>> 

You can find out more about the node shell [here](https://docs.corda.net/shell.html).

### Client Webserver

`clients/src/main/kotlin/com/template/webserver/` defines a simple Spring webserver that connects to a node via RPC and 
allows you to interact with the node over HTTP. This connection is established via a proxy `NodeRPCConnection.kt` class.

Some helpful starter API endpoints are defined here:

     clients/src/main/kotlin/com/template/webserver/StandardController.kt
     
You can add and extend your own here:

     clients/src/main/kotlin/com/template/webserver/CustomController.kt

And a static webpage is defined here:

     clients/src/main/resources/static/

#### Running the webserver

##### Via the command line

Each node has it's own corresponding Spring server that interacts with it via Node RPC Connection proxy which is essentially a wrapper around the CordaRPCClient class. You can start these web servers via gradle tasks for ease-of-development. 

    ./gradlew runPartyAServer 
    ./gradlew runPartyBServer
    ./gradlew runPartyCServer  
    
These web servers are hosted on ports 50005, 50006 and 50007 respectively. You can test they have launched successfully by connecting to one of there endpoints.

    curl localhost:50005/api/status -> 200
    
You can add your own custom endpoints to the Spring Custom Controller 
    
##### Via IntelliJ

Run the `Run Template Server` run configuration. By default, it connects to the node with RPC address `localhost:10006` 
with the username `user1` and the password `test`, and serves the webserver on port `localhost:10050`.

### Docker

You can interact with the Corda nodes on your own mini network of docker containers. You can bootstrap this network via the `docker.sh` script within docker module. This script will generate the relevant directories for a list of participant names specified within the participant.txt file. For now each party name should be allocated a number linearly at the end i.e Party1, Party2, Party3,... PartyN, to ensure a correct allocation of ports. The script will spin up a docker network along docker containers for each node that request to join through the doorman and NMS container.

Once the script has been successfully ran you can inspect the docker processes. via the command below which should display a list of 4 running containers; one for each of the 3 partys and one for the notary and network map service.

    docker ps

Alternatively you can display all docker containers whether they are running or not via the command 

    docker ps -a
    
Once you can see the running containers. You can `ssh` in to one to interact with the corda node via the command

    ssh rpcUser@localhost -p <ssh-port> #2221 is the first port used. The password is testingPassword
    
The template uses the Corda finance Cordapps but you can use any of you own. Just place them in the Cordapps folders by editing the script or do it after and relaunch the container. We can test this node is successfully running by running

    run vaultQuery contractStateType: net.corda.finance.contracts.asset.Cash$State
    start net.corda.finance.flows.CashIssueFlow amount: $111111, issuerBankPartyRef: 0x01, notary: Notary
    start net.corda.finance.flows.CashPaymentFlow amount: $500, recipient: "Party2"
    start net.corda.finance.flows.CashPaymentFlow amount: $500, recipient: "Party3"
    
Try other nodes too

    ssh rpcUser@localhost -p 2222
    start net.corda.finance.flows.CashPaymentFlow amount: $200, recipient: "Party1"
    start net.corda.finance.flows.CashPaymentFlow amount: $100, recipient: "Party3"
    
    
# Extending the template

You should extend this template as follows:

* Add your own state and contract definitions under `contracts/src/main/kotlin/`
* Add your own flow definitions under `workflows/src/main/kotlin/`
* Extend or replace the client and webserver under `clients/src/main/kotlin/`

For a guided example of how to extend this template, see the Hello, World! tutorial 
[here](https://docs.corda.net/hello-world-introduction.html).
