import SwiftUI
import AppKit

final class SessionController: ObservableObject {
    @Published var blockedSites: [BlockedSite] = []
    @Published var blockedApps: [BlockedApp] = []
    @Published private(set) var sessionState: SessionState = .idle
    @Published private(set) var isAccessibilityTrusted: Bool = false

    private var timer: Timer?
    private var pendingEndDate: Date?
    private var hesitationEndDate: Date?

    var runningApps: [RunningAppInfo] {
        AppBlocker.runningApps()
    }

    var isInHesitation: Bool {
        if case .hesitation = sessionState { return true }
        return false
    }

    var isActive: Bool {
        if case .active = sessionState { return true }
        return false
    }

    var canStartSession: Bool {
        !isInHesitation && !isActive
    }

    var hesitationRemaining: Int {
        guard let end = hesitationEndDate else { return 0 }
        return max(Int(end.timeIntervalSinceNow.rounded(.up)), 0)
    }

    var sessionEndTimeString: String {
        guard case let .active(endDate) = sessionState else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: endDate)
    }

    init() {
        loadDefaults()
        isAccessibilityTrusted = AccessibilityHelper.isTrusted()
        startTimer()
    }

    func startSession(durationMinutes: Int) {
        let now = Date()
        pendingEndDate = now.addingTimeInterval(TimeInterval(durationMinutes * 60))
        hesitationEndDate = now.addingTimeInterval(10)
        sessionState = .hesitation(until: hesitationEndDate!)
    }

    func cancelHesitation() {
        guard isInHesitation else { return }
        pendingEndDate = nil
        hesitationEndDate = nil
        sessionState = .idle
    }

    func addSite(domain: String) {
        let cleaned = domain
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "/", with: "")
        guard !cleaned.isEmpty else { return }
        if !blockedSites.contains(where: { $0.domain == cleaned }) {
            blockedSites.append(BlockedSite(domain: cleaned))
            saveDefaults()
        }
    }

    func removeSite(_ site: BlockedSite) {
        blockedSites.removeAll { $0.id == site.id }
        saveDefaults()
    }

    func addApp(bundleId: String) {
        let trimmed = bundleId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let name = AppBlocker.displayName(for: trimmed) ?? trimmed
        if !blockedApps.contains(where: { $0.bundleId == trimmed }) {
            blockedApps.append(BlockedApp(name: name, bundleId: trimmed))
            saveDefaults()
        }
    }

    func removeApp(_ app: BlockedApp) {
        blockedApps.removeAll { $0.id == app.id }
        saveDefaults()
    }

    func requestAccessibility() {
        AccessibilityHelper.requestTrust()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isAccessibilityTrusted = AccessibilityHelper.isTrusted()
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        let now = Date()

        switch sessionState {
        case .idle:
            break
        case .hesitation(let endDate):
            if now >= endDate {
                if let pending = pendingEndDate {
                    sessionState = .active(until: pending)
                } else {
                    sessionState = .idle
                }
                hesitationEndDate = nil
            }
        case .active(let endDate):
            if now >= endDate {
                sessionState = .idle
                pendingEndDate = nil
            } else {
                AppBlocker.enforce(blockedApps: blockedApps)
                SiteBlocker.enforce(blockedSites: blockedSites)
            }
        }
    }

    private func saveDefaults() {
        let encoder = JSONEncoder()
        if let siteData = try? encoder.encode(blockedSites) {
            UserDefaults.standard.set(siteData, forKey: "blockedSites")
        }
        if let appData = try? encoder.encode(blockedApps) {
            UserDefaults.standard.set(appData, forKey: "blockedApps")
        }
    }

    private func loadDefaults() {
        let decoder = JSONDecoder()
        if let siteData = UserDefaults.standard.data(forKey: "blockedSites"),
           let sites = try? decoder.decode([BlockedSite].self, from: siteData) {
            blockedSites = sites
        }
        if let appData = UserDefaults.standard.data(forKey: "blockedApps"),
           let apps = try? decoder.decode([BlockedApp].self, from: appData) {
            blockedApps = apps
        }
    }
}

enum SessionState: Equatable {
    case idle
    case hesitation(until: Date)
    case active(until: Date)
}

struct BlockedSite: Identifiable, Codable, Hashable {
    let id: UUID
    let domain: String

    init(id: UUID = UUID(), domain: String) {
        self.id = id
        self.domain = domain
    }
}

struct BlockedApp: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let bundleId: String

    init(id: UUID = UUID(), name: String, bundleId: String) {
        self.id = id
        self.name = name
        self.bundleId = bundleId
    }
}
