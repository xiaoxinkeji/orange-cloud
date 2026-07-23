
import os

# SettingsView.swift merge
with open(r'E:\o\orange-cloud\temp_settings_theirs.swift', 'r', encoding='utf-8') as f:
    theirs = f.read()
with open(r'E:\o\orange-cloud\temp_settings_ours.swift', 'r', encoding='utf-8') as f:
    ours = f.read()

theirs_lines = theirs.split('\n')

result = []
i = 0

while i < len(theirs_lines):
    line = theirs_lines[i]
    
    if '@State private var showAddAccount = false' in line:
        result.append(line)
        result.append('    @State private var showTokenEntry = false')
        i += 1
        continue
    
    if '@State private var logShareItems: [Any]?' in line:
        result.append(line)
        result.append('    @State private var iCloudSync = UserDefaults.standard.bool(forKey: AuthManager.iCloudSyncKey)')
        i += 1
        continue
    
    if '@Environment(EntitlementStore.self) private var entitlements' in line:
        result.append(line)
        result.append('    @Environment(\.openURL) private var openURL')
        i += 1
        continue
    
    if line.strip().startswith('var body') and 'some View' in line:
        result.append('')
        result.append('    private var appVersion: String {')
        result.append('        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"')
        result.append('        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"')
        result.append('        return "\(version) (\(build))"')
        result.append('    }')
        result.append('')
        result.append(line)
        i += 1
        continue
    
    if 'Orange Cloud Pro' in line and line.strip().startswith('//'):
        result.append('')
        result.append('                // ---- iCloud Sync ----')
        result.append('                Section {')
        result.append('                    Toggle(isOn: ) {')
        result.append('                        HStack(spacing: 12) {')
        result.append('                            TintIcon(systemImage: "icloud", color: .blue)')
        result.append('                            Text("iCloud Sync")')
        result.append('                        }')
        result.append('                    }')
        result.append('                } header: {')
        result.append('                    Text("Sync")')
        result.append('                } footer: {')
        result.append('                    Text("iCloud sync settings description.")')
        result.append('                }')
        result.append('                .onChange(of: iCloudSync) {')
        result.append('                    auth.setICloudSync(iCloudSync)')
        result.append('                    AccountPrefsStore.shared.applySyncChange(iCloudSync)')
        result.append('                }')
        result.append('                .glassRow()')
        result.append('')
        result.append(line)
        i += 1
        continue
    
    result.append(line)
    i += 1

merged = '\n'.join(result)
out_path = r'E:\o\orange-cloud\apps\ios\Orange Cloud\Orange Cloud\Views\Settings\SettingsView.swift'
with open(out_path, 'w', encoding='utf-8') as f:
    f.write(merged)
print('Written ' + str(len(merged)) + ' bytes')
