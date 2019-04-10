package com.template.states

import com.template.contracts.ExampleContract
import net.corda.core.contracts.BelongsToContract
import net.corda.core.contracts.LinearState
import net.corda.core.identity.AbstractParty
import net.corda.core.identity.Party

// *********
// * State *
// *********
@BelongsToContract(ExampleContract::class)
data class ExampleState(val party1: Party,
                        val party2: Party,
                        val agreementDetails): LinearState {

    override val participants: List<AbstractParty> = listOf(party1, party2)) : ContractState

}