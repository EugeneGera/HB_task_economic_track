import Foundation

final class AppStore: ObservableObject {
    @Published var data: AppData {
        didSet {
            scheduleSave()
        }
    }

    private let fileURL: URL
    private let cloudBackupService = CloudBackupService()
    private var saveWorkItem: DispatchWorkItem?
    private var lastLocalModifiedAt: Date

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documents.appendingPathComponent("task-manager-data.json")

        if let savedData = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder.appDecoder.decode(AppData.self, from: savedData) {
            data = decoded
            lastLocalModifiedAt = fileURL.modificationDate ?? Date.distantPast
        } else {
            data = AppData.defaultData
            lastLocalModifiedAt = Date.distantPast
        }

        restoreFromCloudIfNeeded()
    }

    deinit {
        saveImmediately()
    }

    func resetToDefaultData() {
        data = AppData.defaultData
    }

    func saveImmediately() {
        saveWorkItem?.cancel()
        save()
    }

    private func scheduleSave() {
        saveWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.save()
        }
        saveWorkItem = workItem

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: workItem)
    }

    private func save() {
        guard let encoded = try? JSONEncoder.appEncoder.encode(data) else {
            return
        }

        let modifiedAt = Date()
        try? encoded.write(to: fileURL, options: [.atomic])
        lastLocalModifiedAt = modifiedAt
        cloudBackupService.upload(data: data, modifiedAt: modifiedAt)
    }

    private func restoreFromCloudIfNeeded() {
        cloudBackupService.fetchLatest { [weak self] snapshot in
            DispatchQueue.main.async {
                guard let self, let snapshot, snapshot.modifiedAt > self.lastLocalModifiedAt else {
                    return
                }

                self.data = snapshot.data
            }
        }
    }
}

private extension URL {
    var modificationDate: Date? {
        (try? resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
    }
}

extension JSONDecoder {
    static var appDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

extension JSONEncoder {
    static var appEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
