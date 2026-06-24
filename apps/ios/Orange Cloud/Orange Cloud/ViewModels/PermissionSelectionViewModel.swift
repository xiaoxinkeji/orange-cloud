//
//  PermissionSelectionViewModel.swift
//  Orange Cloud
//

import Foundation
import Observation

@Observable
@MainActor
final class PermissionSelectionViewModel {

    var permissions: [FeaturePermission]

    init(preselectScopes: Set<String>? = nil) {
        var features = FeaturePermission.allFeatures
        if let existing = preselectScopes {
            for i in features.indices {
                let readGranted = features[i].readScopes.contains(where: { existing.contains($0) })
                let editGranted = features[i].editScopes.contains(where: { existing.contains($0) })
                features[i].isEnabled = features[i].isRequired || readGranted || editGranted
                features[i].canEdit = editGranted
            }
        }
        self.permissions = features
    }

    // 当前选中的 scope ID 列表（用于预览）
    var selectedScopes: [String] {
        FeaturePermission.buildScopeSet(from: permissions).sorted()
    }

    // 当前 scope 字符串（传给 AuthManager）
    var scopeString: String {
        FeaturePermission.buildScopeString(from: permissions)
    }

    func toggleFeature(id: String) {
        guard let index = permissions.firstIndex(where: { $0.id == id }) else { return }
        guard !permissions[index].isRequired else { return }  // 必选项不可关闭
        permissions[index].isEnabled.toggle()
        // 关闭功能时重置为只读
        if !permissions[index].isEnabled {
            permissions[index].canEdit = false
        }
    }

    func toggleEditPermission(id: String) {
        guard let index = permissions.firstIndex(where: { $0.id == id }) else { return }
        guard permissions[index].isEnabled else { return }
        guard permissions[index].hasEditOption else { return }
        permissions[index].canEdit.toggle()
    }
}
