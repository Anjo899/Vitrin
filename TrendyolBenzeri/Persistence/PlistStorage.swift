//
//  PlistStorage.swift
//  TrendyolBenzeri
//

import Foundation

/// `Codable` değerleri uygulamanın Documents klasöründe plist dosyası olarak saklar.
/// Uygulama kapanıp açıldığında favoriler ve sepet buradan geri yüklenir.
nonisolated struct PlistStorage: Sendable {
    let directory: URL

    /// Testlerde geçici bir klasör verilir, uygulamada Documents kullanılır.
    init(directory: URL = .documentsDirectory) {
        self.directory = directory
    }

    func save<T: Encodable>(_ value: T, to fileName: String) throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        let data = try encoder.encode(value)
        try data.write(to: fileURL(for: fileName), options: .atomic)
    }

    /// Dosya henüz yoksa (ilk açılış) `nil` döner.
    func load<T: Decodable>(_ type: T.Type, from fileName: String) throws -> T? {
        let url = fileURL(for: fileName)
        guard FileManager.default.fileExists(atPath: url.path()) else {
            return nil
        }
        let data = try Data(contentsOf: url)
        return try PropertyListDecoder().decode(type, from: data)
    }

    /// Okunamayan dosyayı silmeden, zaman damgalı bir adla kenara alır
    /// (ör. `cart.plist` → `cart.plist.corrupt-20261023T120000Z`).
    /// Böylece bir sonraki kayıt eski veriyi ezmez ve önceki yedekler silinmez; dosya incelenip kurtarılabilir.
    func moveAsideCorruptFile(_ fileName: String, date: Date = .now) {
        let source = fileURL(for: fileName)
        let stamp = date.ISO8601Format(.iso8601.dateSeparator(.omitted).timeSeparator(.omitted))
        var destination = fileURL(for: "\(fileName).corrupt-\(stamp)")
        // Aynı saniyede ikinci bir yedek gelirse ilkini ezmesin.
        if FileManager.default.fileExists(atPath: destination.path()) {
            destination = fileURL(for: "\(fileName).corrupt-\(stamp)-\(UUID().uuidString)")
        }
        do {
            try FileManager.default.moveItem(at: source, to: destination)
        } catch {
            print("\(fileName) kenara alınamadı: \(error)")
        }
    }

    private func fileURL(for fileName: String) -> URL {
        directory.appending(path: fileName)
    }
}
