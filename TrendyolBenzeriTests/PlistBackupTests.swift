//
//  PlistBackupTests.swift
//  TrendyolBenzeriTests
//

import Foundation
import Testing
@testable import TrendyolBenzeri

/// Okunamayan dosyaların zaman damgalı yedekleri (ARCHITECTURE.md 7. Kalıcılık, REVIEW.md O3).
struct PlistBackupTests {

    /// İkinci bozulma ilk yedeği silmez (REVIEW.md O3).
    @Test func secondCorruptionKeepsFirstBackup() throws {
        let storage = try PlistStorage.temporary()
        let fileURL = storage.directory.appending(path: "cart.plist")

        try Data("ilk".utf8).write(to: fileURL)
        storage.moveAsideCorruptFile("cart.plist", date: Date(timeIntervalSince1970: 0))
        try Data("ikinci".utf8).write(to: fileURL)
        storage.moveAsideCorruptFile("cart.plist", date: Date(timeIntervalSince1970: 60))

        let names = storage.backupNames(of: "cart.plist")
        #expect(names == ["cart.plist.corrupt-19700101T000000Z", "cart.plist.corrupt-19700101T000100Z"])
        let contents = try names.map { try Data(contentsOf: storage.directory.appending(path: $0)) }
        #expect(contents == [Data("ilk".utf8), Data("ikinci".utf8)])
    }

    @Test func sameSecondCorruptionKeepsBothBackups() throws {
        let storage = try PlistStorage.temporary()
        let fileURL = storage.directory.appending(path: "cart.plist")
        let date = Date(timeIntervalSince1970: 0)

        try Data("ilk".utf8).write(to: fileURL)
        storage.moveAsideCorruptFile("cart.plist", date: date)
        try Data("ikinci".utf8).write(to: fileURL)
        storage.moveAsideCorruptFile("cart.plist", date: date)

        #expect(storage.backupNames(of: "cart.plist").count == 2)
    }
}
