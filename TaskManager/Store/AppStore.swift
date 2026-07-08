import Foundation

final class AppStore: ObservableObject {
    @Published var data: AppData {
        didSet {
            scheduleSave()
        }
    }

    private let fileURL: URL
    private var saveWorkItem: DispatchWorkItem?

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documents.appendingPathComponent("task-manager-data.json")

        if let savedData = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder.appDecoder.decode(AppData.self, from: savedData) {
            data = decoded
        } else {
            data = AppData.defaultData
        }
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

        try? encoded.write(to: fileURL, options: [.atomic])
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
