package com.template

import com.template.contracts.ExampleContract
import com.template.states.ExampleState
import net.corda.core.contracts.CommandData
import net.corda.core.contracts.ContractState
import net.corda.core.identity.AbstractParty
import net.corda.core.identity.CordaX500Name
import net.corda.core.identity.Party
import net.corda.testing.common.internal.testNetworkParameters
import net.corda.testing.core.TestIdentity
import net.corda.testing.node.MockServices
import net.corda.testing.node.ledger
import net.corda.testing.node.makeTestIdentityService
import org.junit.Test

class ExampleContractTests{

    // set up the mockServices which will validate the test transactions
    private val ledgerServices = MockServices(
            cordappPackages = listOf("com.template.contracts"),
            initialIdentity = TestIdentity(CordaX500Name("TestIdentity", "", "GB")),
            identityService = makeTestIdentityService(),
            networkParameters = testNetworkParameters(minimumPlatformVersion = 4))

    private val party1 = TestIdentity(CordaX500Name.parse("O=party1,L=London,C=GB"))
    private val party2 = TestIdentity(CordaX500Name.parse("O=party2,L=NewYork,C=US"))
    private val otherIdentity = TestIdentity(CordaX500Name.parse("O=otherIdentity,L=Paris,C=FR"))




    // set up some dummy transaction components for use in the testing
    data class DummyState(val party: Party) : ContractState {
        override val participants: List<AbstractParty> = listOf(party)
    }

    interface TestCommands : CommandData {
        class dummyCommand: TestCommands
    }

    // set up some states to use in the testing

    private val draftState1 = ExampleState(party1.party, party2.party, "This is draft agreement 1")
    private val draftState2 = ExampleState(party1.party, party2.party, "This is draft agreement 2")



    @Test
    fun `example for DSL structure`() {

        // the ledgerServices DSL allows you to build transactions and test them against your contract logic
        ledgerServices.ledger {

            // transaction {} allows you to build up a transaction for testing and assert whether it shoudl pass or fail verification
            transaction {

                // input() adds an input state to the transaction, you need to supply the contract references by it's ID and the pre formed state
                input(ExampleContract.ID, draftState1)

                // output() adds an output state to the transaction, you need to supply the contract references by it's ID and the pre formed state
                output(ExampleContract.ID, draftState2)

                // command() adds a command to the transaction, you need to supply the required signers and the command
                command(party1.publicKey, ExampleContract.Commands.AmendDraft())

                // assert whether the transaction should pass verification or not
                this.verifies()
            }


            // An example where wrong command is used
            transaction {

                input(ExampleContract.ID, draftState1)
                output(ExampleContract.ID, draftState2)
                command(party1.publicKey, TestCommands.dummyCommand())

                // this transaction should fail, we specify the message it should fails with to pass the test
                this.failsWith("There should be exactly one ExampleContract command")

                // if you comment the above failsWith() line and uncomment the below line, the test will fail as the error thrown does not match the error expected
//                this.failsWith("Some other error message")

            }
        }
    }
}