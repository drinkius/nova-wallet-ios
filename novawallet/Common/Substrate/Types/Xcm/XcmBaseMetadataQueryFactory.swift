import Foundation
import RobinHood
import SubstrateSdk

class XcmBaseMetadataQueryFactory {
    func createXcmTypeVersionWrapper(
        for runtimeProvider: RuntimeProviderProtocol,
        typeName: String
    ) -> CompoundOperationWrapper<Xcm.Version?> {
        let codingFactoryOperation = runtimeProvider.fetchCoderFactoryOperation()
        let searchOperation = ClosureOperation<Xcm.Version?> {
            guard
                let node = try codingFactoryOperation.extractNoCancellableResultData().getTypeNode(
                    for: typeName
                ) else {
                return nil
            }

            guard let versionNode = node as? SiVariantNode else {
                return nil
            }

            return versionNode.typeMapping
                .compactMap { Xcm.Version(rawName: $0.name) }
                .min()
        }

        searchOperation.addDependency(codingFactoryOperation)

        return CompoundOperationWrapper(targetOperation: searchOperation, dependencies: [codingFactoryOperation])
    }
}