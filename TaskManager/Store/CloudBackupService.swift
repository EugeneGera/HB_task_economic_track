import Foundation

#if canImport(CloudKit) && CLOUDKIT_BACKUP_ENABLED
import CloudKit
#endif

struct CloudBackupSnapshot {
    let data: AppData
    let modifiedAt: Date
}

final class CloudBackupService {
    #if canImport(CloudKit) && CLOUDKIT_BACKUP_ENABLED
    private let database = CKContainer.default().privateCloudDatabase
    private let recordID = CKRecord.ID(recordName: "task-manager-data-v1")
    private let recordType = "TaskManagerBackup"
    #endif

    func fetchLatest(completion: @escaping (CloudBackupSnapshot?) -> Void) {
        #if canImport(CloudKit) && CLOUDKIT_BACKUP_ENABLED
        database.fetch(withRecordID: recordID) { record, error in
            if let ckError = error as? CKError, ckError.code == .unknownItem {
                completion(nil)
                return
            }

            guard
                let record,
                let payload = record["payload"] as? String,
                let payloadData = payload.data(using: .utf8),
                let decoded = try? JSONDecoder.appDecoder.decode(AppData.self, from: payloadData)
            else {
                completion(nil)
                return
            }

            let modifiedAt = record["modifiedAt"] as? Date ?? Date.distantPast
            completion(CloudBackupSnapshot(data: decoded, modifiedAt: modifiedAt))
        }
        #else
        completion(nil)
        #endif
    }

    func upload(data: AppData, modifiedAt: Date) {
        #if canImport(CloudKit) && CLOUDKIT_BACKUP_ENABLED
        guard
            let encoded = try? JSONEncoder.appEncoder.encode(data),
            let payload = String(data: encoded, encoding: .utf8)
        else {
            return
        }

        database.fetch(withRecordID: recordID) { [recordType, recordID, database] record, _ in
            let record = record ?? CKRecord(recordType: recordType, recordID: recordID)
            record["payload"] = payload as CKRecordValue
            record["modifiedAt"] = modifiedAt as CKRecordValue
            record["schemaVersion"] = 1 as CKRecordValue

            database.save(record) { _, _ in }
        }
        #endif
    }
}
