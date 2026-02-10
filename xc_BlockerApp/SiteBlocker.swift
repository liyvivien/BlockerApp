import Foundation

enum SiteBlocker {
    static func enforce(blockedSites: [BlockedSite]) {
        guard !blockedSites.isEmpty else { return }

        if let safariUrl = activeSafariURL(), isBlocked(urlString: safariUrl, blockedSites: blockedSites) {
            closeSafariTab()
        }

        if let chromeUrl = activeChromeURL(), isBlocked(urlString: chromeUrl, blockedSites: blockedSites) {
            closeChromeTab()
        }
    }

    private static func isBlocked(urlString: String, blockedSites: [BlockedSite]) -> Bool {
        guard let host = URL(string: urlString)?.host?.lowercased() else { return false }
        return blockedSites.contains { blocked in
            let domain = blocked.domain.lowercased()
            return host == domain || host.hasSuffix("." + domain)
        }
    }

    private static func activeSafariURL() -> String? {
        let script = """
        tell application \"Safari\"
            if it is running then
                if (count of windows) > 0 then
                    return URL of front document
                end if
            end if
        end tell
        """
        return runAppleScript(script)
    }

    private static func activeChromeURL() -> String? {
        let script = """
        tell application \"Google Chrome\"
            if it is running then
                if (count of windows) > 0 then
                    return URL of active tab of front window
                end if
            end if
        end tell
        """
        return runAppleScript(script)
    }

    private static func closeSafariTab() {
        let script = """
        tell application \"Safari\"
            if it is running then
                if (count of windows) > 0 then
                    close (current tab of front window)
                end if
            end if
        end tell
        """
        _ = runAppleScript(script)
    }

    private static func closeChromeTab() {
        let script = """
        tell application \"Google Chrome\"
            if it is running then
                if (count of windows) > 0 then
                    close (active tab of front window)
                end if
            end if
        end tell
        """
        _ = runAppleScript(script)
    }

    @discardableResult
    private static func runAppleScript(_ source: String) -> String? {
        var errorInfo: NSDictionary?
        let script = NSAppleScript(source: source)
        let result = script?.executeAndReturnError(&errorInfo)
        if let _ = errorInfo {
            return nil
        }
        return result?.stringValue
    }
}
