package com.template


import com.template.states.ExampleState
import com.template.workflows.CreateDraftFlow
import com.template.workflows.CreateDraftResponderFlow
import net.corda.core.node.services.queryBy
import net.corda.core.utilities.getOrThrow
import net.corda.testing.common.internal.testNetworkParameters
import net.corda.testing.node.MockNetwork
import net.corda.testing.node.MockNetworkParameters
import net.corda.testing.node.TestCordapp
import org.junit.After
import org.junit.Before
import org.junit.Test

class ExampleFlowTests{


    val mnp = MockNetworkParameters(listOf(TestCordapp.findCordapp("com.template.contracts"), TestCordapp.findCordapp("com.template.workflows")
    ))

    val mockNetworkParameters = mnp.withNetworkParameters(testNetworkParameters(minimumPlatformVersion = 4))

    private val network = MockNetwork(mockNetworkParameters)

    private val a = network.createNode()
    private val b = network.createNode()

    private val partya = a.info.legalIdentities.first()
    private val partyb = b.info.legalIdentities.first()

    init {
        listOf(a, b).forEach {
            it.registerInitiatedFlow(CreateDraftResponderFlow::class.java)
        }
    }

    @Before
    fun setup() = network.runNetwork()

    @After
    fun tearDown() = network.stopNodes()


    @Test
    fun `CreateDraftFlow Test`(){

        val flow = CreateDraftFlow(partyb, "This is an agreement between partya and partyb")
        val future = a.startFlow(flow)

        network.runNetwork()

        val returnedTx = future.getOrThrow()

        val returnedLedgerTx =returnedTx.toLedgerTransaction(a.services).outputs.single().data as ExampleState

        assert(returnedLedgerTx.agreementDetails == "This is an agreement between partya and partyb" )

        // check b has the transaction in its vault
        val result = b.services.vaultService.queryBy<ExampleState>()
        assert(result.states[0].ref.txhash == returnedTx.id)

    }

//    @Test
//    fun `AmendeDraftFlow Test`(){
//
//        val flow = CreateDraftFlow(partyb, "This is an agreement between partya and partyb")
//        val future = a.startFlow(flow)
//
//        network.runNetwork()
//
//        val returnedTx = future.getOrThrow()
//
//        val returnedLedgerTx =returnedTx.toLedgerTransaction(a.services).outputs.single().data as ExampleState
//
//        assert(returnedLedgerTx.agreementDetails == "This is an agreement between partya and partyb" )
//
//        // check b has the transaction in its vault
//        val result = b.services.vaultService.queryBy<ExampleState>()
//        assert(result.states[0].ref.txhash == returnedTx.id)
//
//    }





}