package com.template.workflows

import co.paralleluniverse.fibers.Suspendable
import com.template.contracts.ExampleContract
import com.template.states.ExampleState
import net.corda.core.contracts.StateRef
import net.corda.core.flows.*
import net.corda.core.identity.Party
import net.corda.core.node.services.queryBy
import net.corda.core.node.services.vault.QueryCriteria
import net.corda.core.transactions.SignedTransaction
import net.corda.core.transactions.TransactionBuilder
import net.corda.core.utilities.ProgressTracker

// *********
// * Flows *
// *********


// CreateDraftFlows

@InitiatingFlow
@StartableByRPC
class CreateDraftFlow(val otherParty: Party,
                      val agreementDetails: String) : FlowLogic<SignedTransaction>() {
    override val progressTracker = ProgressTracker()

    @Suspendable
    override fun call() : SignedTransaction{

        // create output state
        val me = serviceHub.myInfo.legalIdentities.first()
        val outputState = ExampleState(me, otherParty, agreementDetails)

        // create command
        val command = ExampleContract.Commands.CreateDraft()

        // Build transaction

        val txBuilder = TransactionBuilder()
        val notary = serviceHub.networkMapCache.notaryIdentities.first()
        txBuilder.notary = notary
        txBuilder.addOutputState(outputState)
        txBuilder.addCommand(command, me.owningKey)

        // verify
        txBuilder.verify(serviceHub)

        // sign
        val stx = serviceHub.signInitialTransaction(txBuilder)


        // Finalise
        val session =  initiateFlow(otherParty)
        val ftx = subFlow((FinalityFlow(stx,session)))

        return ftx
    }
}

@InitiatedBy(CreateDraftFlow::class)
class CreateDraftResponderFlow(val otherPartySession: FlowSession) : FlowLogic<SignedTransaction>() {
    @Suspendable
    override fun call(): SignedTransaction {
        // Responder flow logic goes here.

        return subFlow(ReceiveFinalityFlow(otherPartySession))

    }
}

// AmendDraftFlows


@InitiatingFlow
@StartableByRPC
class AmendDraftFlow(val existingStateRef: StateRef,
                      val newAgreementDetails: String) : FlowLogic<SignedTransaction>() {
    override val progressTracker = ProgressTracker()

    @Suspendable
    override fun call() : SignedTransaction{

        // get existing state details
        val inputStateAndRef = serviceHub.toStateAndRef<ExampleState>(existingStateRef)
        val inputState = inputStateAndRef.state as ExampleState


        // create output state
        val outputState = inputState.copy(agreementDetails = newAgreementDetails)

        // create command
        val command = ExampleContract.Commands.AmendDraft()

        // Build transaction

        val txBuilder = TransactionBuilder()
        val notary = serviceHub.networkMapCache.notaryIdentities.first()
        val me = serviceHub.myInfo.legalIdentities.first()

        txBuilder.notary = notary
        txBuilder.addInputState(inputStateAndRef)
        txBuilder.addOutputState(outputState)
        txBuilder.addCommand(command, me.owningKey)

        // verify
        txBuilder.verify(serviceHub)

        // sign
        val stx = serviceHub.signInitialTransaction(txBuilder)


        // identify otherParty

        val otherParty = inputState.participants.filter {it != me}

        // todo: fix this Party vs AbstractParty problem

        // Finalise
        val session =  initiateFlow(otherParty)
        val ftx = subFlow((FinalityFlow(stx,session)))

        return ftx
    }
}

@InitiatedBy(CreateDraftFlow::class)
class AmendDraftResponderFlow(val otherPartySession: FlowSession) : FlowLogic<SignedTransaction>() {
    @Suspendable
    override fun call(): SignedTransaction {
        // Responder flow logic goes here.

        return subFlow(ReceiveFinalityFlow(otherPartySession))

    }
}
