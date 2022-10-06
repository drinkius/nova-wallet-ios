import Foundation
import SubstrateSdk
import RobinHood
import BigInt

final class Gov2OperationFactory {
    struct AdditionalInfo {
        let tracks: [Referenda.TrackId: Referenda.TrackInfo]
        let totalIssuance: BigUInt
        let undecidingTimeout: Moment
    }

    struct SchedulerTaskName: Encodable {
        let index: Referenda.ReferendumIndex

        func encode(to encoder: Encoder) throws {
            let scaleEncoder = ScaleEncoder()
            "assembly".data(using: .utf8).map { scaleEncoder.appendRaw(data: $0) }
            try "enactment".encode(scaleEncoder: scaleEncoder)
            try index.encode(scaleEncoder: scaleEncoder)

            let data = scaleEncoder.encode()

            var container = encoder.singleValueContainer()
            try container.encode(BytesCodable(wrappedValue: data))
        }
    }

    let requestFactory: StorageRequestFactoryProtocol

    init(requestFactory: StorageRequestFactoryProtocol) {
        self.requestFactory = requestFactory
    }

    private func createEnacmentTimeFetchWrapper(
        dependingOn referendumOperation: BaseOperation<[ReferendumIndexKey: ReferendumInfo]>,
        connection: JSONRPCEngine,
        runtimeProvider: RuntimeProviderProtocol
    ) -> CompoundOperationWrapper<[Referenda.ReferendumIndex: BlockNumber]> {
        let keysClosure: () throws -> [SchedulerTaskName] = {
            let referendums = try referendumOperation.extractNoCancellableResultData()

            return referendums.compactMap { keyValue in
                switch keyValue.value {
                case .approved:
                    return SchedulerTaskName(index: keyValue.key.referendumIndex)
                default:
                    return nil
                }
            }
        }

        let codingFactoryOperation = runtimeProvider.fetchCoderFactoryOperation()

        let enactmentWrapper: CompoundOperationWrapper<[StorageResponse<OnChainScheduler.TaskAddress>]> =
            requestFactory.queryItems(
                engine: connection,
                keyParams: keysClosure,
                factory: { try codingFactoryOperation.extractNoCancellableResultData() },
                storagePath: OnChainScheduler.lookupTaskPath
            )

        enactmentWrapper.addDependency(operations: [codingFactoryOperation])

        let mapOperation = ClosureOperation<[Referenda.ReferendumIndex: BlockNumber]> {
            let keys = try keysClosure()
            let results = try enactmentWrapper.targetOperation.extractNoCancellableResultData()

            return zip(keys, results).reduce(into: [Referenda.ReferendumIndex: BlockNumber]()) { accum, keyResult in
                guard let when = keyResult.1.value?.when else {
                    return
                }

                accum[keyResult.0.index] = when
            }
        }

        mapOperation.addDependency(enactmentWrapper.targetOperation)

        let dependencies = [codingFactoryOperation] + enactmentWrapper.allOperations

        return CompoundOperationWrapper(targetOperation: mapOperation, dependencies: dependencies)
    }

    private func createReferendumMapOperation(
        dependingOn referendumOperation: BaseOperation<[ReferendumIndexKey: ReferendumInfo]>,
        additionalInfoOperation: BaseOperation<AdditionalInfo>,
        enactmentsOperation: BaseOperation<[Referenda.ReferendumIndex: BlockNumber]>
    ) -> BaseOperation<[ReferendumLocal]> {
        ClosureOperation<[ReferendumLocal]> {
            let remoteReferendums = try referendumOperation.extractNoCancellableResultData()
            let additionalInfo = try additionalInfoOperation.extractNoCancellableResultData()
            let enactments = try enactmentsOperation.extractNoCancellableResultData()

            let mappingFactory = Gov2LocalMappingFactory()

            return remoteReferendums.compactMap { keyedReferendum in
                let referendumIndex = keyedReferendum.key.referendumIndex
                let remoteReferendum = keyedReferendum.value

                return mappingFactory.mapRemote(
                    referendum: remoteReferendum,
                    index: referendumIndex,
                    additionalInfo: additionalInfo,
                    enactmentBlock: enactments[referendumIndex]
                )
            }
        }
    }

    private func createAdditionalInfoWrapper(
        from connection: JSONRPCEngine,
        runtimeProvider: RuntimeProviderProtocol
    ) -> CompoundOperationWrapper<AdditionalInfo> {
        let codingFactoryOperation = runtimeProvider.fetchCoderFactoryOperation()

        let tracksOperation = StorageConstantOperation<[Referenda.Track]>(path: Referenda.tracks)

        tracksOperation.configurationBlock = {
            do {
                tracksOperation.codingFactory = try codingFactoryOperation.extractNoCancellableResultData()
            } catch {
                tracksOperation.result = .failure(error)
            }
        }

        let undecidingTimeoutOperation = PrimitiveConstantOperation<UInt32>(path: Referenda.undecidingTimeout)

        undecidingTimeoutOperation.configurationBlock = {
            do {
                undecidingTimeoutOperation.codingFactory = try codingFactoryOperation.extractNoCancellableResultData()
            } catch {
                undecidingTimeoutOperation.result = .failure(error)
            }
        }

        let totalIssuanceWrapper: CompoundOperationWrapper<StorageResponse<StringScaleMapper<BigUInt>>> =
            requestFactory.queryItem(
                engine: connection,
                factory: { try codingFactoryOperation.extractNoCancellableResultData() },
                storagePath: .totalIssuance
            )

        let fetchOperations = [tracksOperation, undecidingTimeoutOperation] + totalIssuanceWrapper.allOperations
        fetchOperations.forEach { $0.addDependency(codingFactoryOperation) }

        let mappingOperation = ClosureOperation<AdditionalInfo> {
            let tracks = try tracksOperation.extractNoCancellableResultData().reduce(
                into: [Referenda.TrackId: Referenda.TrackInfo]()
            ) { $0[$1.trackId] = $1.info }

            let undecidingTimeout = try undecidingTimeoutOperation.extractNoCancellableResultData()

            let totalIssuance = try totalIssuanceWrapper.targetOperation.extractNoCancellableResultData().value

            return AdditionalInfo(
                tracks: tracks,
                totalIssuance: totalIssuance?.value ?? 0,
                undecidingTimeout: undecidingTimeout
            )
        }

        let dependencies = [codingFactoryOperation] + fetchOperations

        fetchOperations.forEach { mappingOperation.addDependency($0) }

        return CompoundOperationWrapper(targetOperation: mappingOperation, dependencies: dependencies)
    }
}

extension Gov2OperationFactory: ReferendumsOperationFactoryProtocol {
    func fetchAllReferendumsWrapper(
        from connection: JSONRPCEngine,
        runtimeProvider: RuntimeProviderProtocol
    ) -> CompoundOperationWrapper<[ReferendumLocal]> {
        let request = UnkeyedRemoteStorageRequest(storagePath: Referenda.referendumInfo)

        let codingFactoryOperation = runtimeProvider.fetchCoderFactoryOperation()

        let referendumWrapper: CompoundOperationWrapper<[ReferendumIndexKey: ReferendumInfo]> =
            requestFactory.queryByPrefix(
                engine: connection,
                request: request,
                storagePath: request.storagePath,
                factory: { try codingFactoryOperation.extractNoCancellableResultData() }
            )

        referendumWrapper.addDependency(operations: [codingFactoryOperation])

        let additionalInfoWrapper = createAdditionalInfoWrapper(from: connection, runtimeProvider: runtimeProvider)

        let enactmentsWrapper = createEnacmentTimeFetchWrapper(
            dependingOn: referendumWrapper.targetOperation,
            connection: connection,
            runtimeProvider: runtimeProvider
        )

        enactmentsWrapper.addDependency(wrapper: referendumWrapper)

        let mapOperation = createReferendumMapOperation(
            dependingOn: referendumWrapper.targetOperation,
            additionalInfoOperation: additionalInfoWrapper.targetOperation,
            enactmentsOperation: enactmentsWrapper.targetOperation
        )

        mapOperation.addDependency(referendumWrapper.targetOperation)
        mapOperation.addDependency(additionalInfoWrapper.targetOperation)
        mapOperation.addDependency(enactmentsWrapper.targetOperation)

        let dependencies = [codingFactoryOperation] + referendumWrapper.allOperations +
            additionalInfoWrapper.allOperations + enactmentsWrapper.allOperations

        return CompoundOperationWrapper(targetOperation: mapOperation, dependencies: dependencies)
    }
}
