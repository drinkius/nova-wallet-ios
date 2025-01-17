import Foundation
import Operation_iOS

typealias GovernanceOffchainVotes = [ReferendumIdLocal: ReferendumAccountVoteLocal]

protocol GovernanceOffchainVotingFactoryProtocol {
    func createAllVotesFetchOperation(
        for address: AccountAddress
    ) -> CompoundOperationWrapper<GovernanceOffchainVoting>

    func createDirectVotesFetchOperation(
        for address: AccountAddress,
        from block: BlockNumber?
    ) -> CompoundOperationWrapper<GovernanceOffchainVotes>

    func createReferendumVotesFetchOperation(
        referendumId: ReferendumIdLocal,
        votersType: ReferendumVotersType
    ) -> CompoundOperationWrapper<[ReferendumVoterLocal]>
}
