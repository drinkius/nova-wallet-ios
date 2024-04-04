import Foundation

final class ICloudBackupServiceFactory {
    let containerId: String
    let fileManager: FileManager
    let fileCoordinator: NSFileCoordinator
    let logger: LoggerProtocol
    let operationQueue: OperationQueue

    init(
        containerId: String = CloudBackup.containerId,
        fileManager: FileManager = FileManager.default,
        fileCoordinator: NSFileCoordinator = NSFileCoordinator(),
        operationQueue: OperationQueue,
        logger: LoggerProtocol = Logger.shared
    ) {
        self.containerId = containerId
        self.fileManager = fileManager
        self.fileCoordinator = fileCoordinator
        self.operationQueue = operationQueue
        self.logger = logger
    }
}

extension ICloudBackupServiceFactory: CloudBackupServiceFactoryProtocol {
    var baseUrl: URL? {
        fileManager.url(
            forUbiquityContainerIdentifier: containerId
        )?.appendingPathComponent("Documents", conformingTo: .directory)
    }

    func createAvailabilityService() -> CloudBackupAvailabilityServiceProtocol {
        CloudBackupAvailabilityService(fileManager: fileManager, logger: logger)
    }

    func createStorageManager(for baseUrl: URL) -> CloudBackupStorageManaging {
        let operationFactory = CloudBackupOperationFactory(
            fileCoordinator: fileCoordinator,
            fileManager: fileManager
        )

        return ICloudBackupStorageManager(
            baseUrl: baseUrl,
            operationFactory: operationFactory,
            operationQueue: operationQueue
        )
    }

    func createOperationFactory() -> CloudBackupOperationFactoryProtocol {
        CloudBackupOperationFactory(
            fileCoordinator: fileCoordinator,
            fileManager: fileManager
        )
    }
}
