import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var dashboardViewModel: DashboardViewModel

    var body: some View {
        NavigationView {
            List {
                Section("Session en cours") {
                    if let metrics = dashboardViewModel.liveMetrics {
                        MetricRow(title: "Fréquence répétitions", value: metrics.repetitionFrequency)
                        MetricRow(title: "Posture critique", value: metrics.criticalPostureDescription)
                        MetricRow(title: "Score ISO", value: metrics.isoScoreDescription)
                    } else {
                        Text("Aucune donnée en direct")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Historique") {
                    ForEach(dashboardViewModel.sessions) { session in
                        NavigationLink(destination: SessionDetailView(session: session)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.metadata.taskName)
                                    .font(.headline)
                                Text(session.metadata.formattedDate)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tableau de bord")
            .task {
                await dashboardViewModel.loadSessions()
            }
        }
    }
}

private struct MetricRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .bold()
        }
    }
}
