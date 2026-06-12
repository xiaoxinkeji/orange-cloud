//
//  DNSListViewModel.swift
//  Orange Cloud
//
//  DNS 记录的拉取与增删改，全部同步进 SwiftData 缓存。
//

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class DNSListViewModel {

    var isLoading = false
    var isSaving  = false
    var error: String?
    var didSave = false      // sensoryFeedback 触发器

    private let dnsService: DNSService
    private let zoneId: String
    private let zoneName: String

    init(dnsService: DNSService, zoneId: String, zoneName: String = "") {
        self.dnsService = dnsService
        self.zoneId = zoneId
        self.zoneName = zoneName
    }

    func refresh(context: ModelContext) async {
        isLoading = true
        error = nil
        do {
            let records = try await dnsService.listRecords(zoneId: zoneId)
            try sync(records: records, context: context)
            SpotlightIndexer.indexDNSRecords(records, zoneId: zoneId, zoneName: zoneName)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    /// 新建或更新记录；recordId == nil 表示新建。成功返回 true。
    func save(recordId: String?, record: CreateDNSRecord, context: ModelContext) async -> Bool {
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            let saved: DNSRecord
            if let recordId {
                saved = try await dnsService.updateRecord(zoneId: zoneId, recordId: recordId, record: record)
            } else {
                saved = try await dnsService.createRecord(zoneId: zoneId, record: record)
            }
            try upsert(saved, context: context)
            didSave.toggle()
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func delete(recordId: String, context: ModelContext) async {
        error = nil
        do {
            try await dnsService.deleteRecord(zoneId: zoneId, recordId: recordId)
            let descriptor = FetchDescriptor<CachedDNSRecord>(
                predicate: #Predicate { $0.id == recordId }
            )
            for cached in try context.fetch(descriptor) {
                context.delete(cached)
            }
            try context.save()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - 缓存同步

    private func sync(records: [DNSRecord], context: ModelContext) throws {
        let zoneId = self.zoneId
        let descriptor = FetchDescriptor<CachedDNSRecord>(
            predicate: #Predicate { $0.zoneId == zoneId }
        )
        let existing = try context.fetch(descriptor)
        let fetchedIDs = Set(records.map(\.id))

        for cached in existing where !fetchedIDs.contains(cached.id) {
            context.delete(cached)
        }
        let existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        for record in records {
            if let cached = existingByID[record.id] {
                cached.update(from: record)
            } else {
                context.insert(CachedDNSRecord(from: record, zoneId: zoneId))
            }
        }
        try context.save()
    }

    private func upsert(_ record: DNSRecord, context: ModelContext) throws {
        let recordId = record.id
        let descriptor = FetchDescriptor<CachedDNSRecord>(
            predicate: #Predicate { $0.id == recordId }
        )
        if let cached = try context.fetch(descriptor).first {
            cached.update(from: record)
        } else {
            context.insert(CachedDNSRecord(from: record, zoneId: zoneId))
        }
        try context.save()
    }
}
