//
//  ContentView.swift
//  xc_BlockerApp
//
//  Created by 🌊 on 05/02/2026.
//


import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var controller: SessionController
    @State private var durationMinutesText: String = "30"
    @State private var newDomain: String = ""
    @State private var newBundleId: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Blocker")
                .font(.system(size: 28, weight: .semibold))

            sessionSection

            Divider()

            blockedSitesSection

            Divider()

            blockedAppsSection

            Divider()

            permissionsSection
        }
        .padding(20)
        .frame(minWidth: 640, minHeight: 720)
    }

    private var sessionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Start Now Session")
                .font(.headline)

            HStack(spacing: 12) {
                Text("Duration (minutes):")
                TextField("30", text: $durationMinutesText)
                    .frame(width: 80)
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 12) {
                Button("Start Now") {
                    let minutes = Int(durationMinutesText) ?? 30
                    controller.startSession(durationMinutes: max(minutes, 1))
                }
                .disabled(!controller.canStartSession)

                Button("Cancel (Hesitation)") {
                    controller.cancelHesitation()
                }
                .disabled(!controller.isInHesitation)
            }

            if controller.isInHesitation {
                Text("Hesitation window: \(controller.hesitationRemaining) seconds remaining")
                    .foregroundColor(.orange)
            } else if controller.isActive {
                Text("Session active. Ends at \(controller.sessionEndTimeString)")
                    .foregroundColor(.red)
            } else {
                Text("Idle")
                    .foregroundColor(.secondary)
            }
        }
    }

    private var blockedSitesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Blocked Websites")
                .font(.headline)

            HStack(spacing: 8) {
                TextField("youtube.com", text: $newDomain)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    controller.addSite(domain: newDomain)
                    newDomain = ""
                }
                .disabled(newDomain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            List {
                ForEach(controller.blockedSites) { site in
                    HStack {
                        Text(site.domain)
                        Spacer()
                        Button("Remove") {
                            controller.removeSite(site)
                        }
                    }
                }
            }
            .frame(height: 200)
        }
    }

    private var blockedAppsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Blocked Apps")
                .font(.headline)

            HStack(spacing: 8) {
                TextField("Bundle ID (e.g., com.valvesoftware.steam)", text: $newBundleId)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    controller.addApp(bundleId: newBundleId)
                    newBundleId = ""
                }
                .disabled(newBundleId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Text("Running apps (click to add):")
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 12) {
                    ForEach(controller.runningApps, id: \.bundleId) { app in
                        Button(app.name) {
                            controller.addApp(bundleId: app.bundleId)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 4)
            }

            List {
                ForEach(controller.blockedApps) { app in
                    HStack {
                        Text("\(app.name) — \(app.bundleId)")
                        Spacer()
                        Button("Remove") {
                            controller.removeApp(app)
                        }
                    }
                }
            }
            .frame(height: 220)
        }
    }

    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Permissions")
                .font(.headline)

            HStack(spacing: 12) {
                Button("Request Accessibility") {
                    controller.requestAccessibility()
                }

                if controller.isAccessibilityTrusted {
                    Text("Accessibility enabled")
                        .foregroundColor(.green)
                } else {
                    Text("Accessibility not enabled")
                        .foregroundColor(.secondary)
                }
            }

            Text("Safari/Chrome control needs Automation permission the first time you run a session.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }
}
