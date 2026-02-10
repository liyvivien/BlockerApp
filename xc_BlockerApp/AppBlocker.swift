import AppKit

struct RunningAppInfo {
    let name: String
    let bundleId: String
}

enum AppBlocker {
    static func runningApps() -> [RunningAppInfo] {
        NSWorkspace.shared.runningApplications
            .compactMap { app in
                guard let bundleId = app.bundleIdentifier else { return nil }
                let name = app.localizedName ?? bundleId
                return RunningAppInfo(name: name, bundleId: bundleId)
            }
            .sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    static func displayName(for bundleId: String) -> String? {
        NSWorkspace.shared.runningApplications
            .first(where: { $0.bundleIdentifier == bundleId })
            .flatMap { $0.localizedName }
    }

    static func enforce(blockedApps: [BlockedApp]) {
        guard !blockedApps.isEmpty else { return }
        let blockedIds = Set(blockedApps.map { $0.bundleId })
        let selfBundleId = Bundle.main.bundleIdentifier

        for app in NSWorkspace.shared.runningApplications {
            guard let bundleId = app.bundleIdentifier else { continue }
            guard bundleId != selfBundleId else { continue }
            if blockedIds.contains(bundleId) {
                _ = app.terminate()
            }
        }
    }
}
