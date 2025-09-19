import SwiftUI

@main
struct ErgonomieApp: App {
    @StateObject private var captureViewModel = CaptureViewModel()
    @StateObject private var dashboardViewModel = DashboardViewModel()

    var body: some Scene {
        WindowGroup {
            TabView {
                CaptureScreen()
                    .tabItem {
                        Label("Capture", systemImage: "video")
                    }
                    .environmentObject(captureViewModel)
                    .environmentObject(dashboardViewModel)

                DashboardView()
                    .tabItem {
                        Label("Tableau de bord", systemImage: "waveform")
                    }
                    .environmentObject(dashboardViewModel)

                ReportsView()
                    .tabItem {
                        Label("Rapports", systemImage: "doc.text")
                    }
                    .environmentObject(dashboardViewModel)
            }
        }
    }
}
