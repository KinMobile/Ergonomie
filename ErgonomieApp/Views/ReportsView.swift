import SwiftUI

struct ReportsView: View {
    @EnvironmentObject private var dashboardViewModel: DashboardViewModel
    @State private var exportResult: ExportResult?
    @State private var selectedSessionID: PoseSession.ID?
    @State private var includeHeatmap = true
    @State private var includeActionPlan = true
    @State private var includeRawAngles = false

    private var selectedSession: PoseSession? {
        if let id = selectedSessionID {
            return dashboardViewModel.sessions.first(where: { $0.id == id })
        }
        return dashboardViewModel.mostRecentSession
    }

    private var normativeReferences: [String] {
        dashboardViewModel.aggregatedInsights?.normativeReferences ?? AggregatedInsights.defaultNormativeReferences
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Sélection de session") {
                    if dashboardViewModel.sessions.isEmpty {
                        Text("Aucune session enregistrée.")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Session", selection: $selectedSessionID) {
                            Text("Plus récente")
                                .tag(PoseSession.ID?.none)
                            ForEach(dashboardViewModel.sessions) { session in
                                Text("\(session.metadata.taskName) – \(session.metadata.formattedDate)")
                                    .tag(PoseSession.ID?.some(session.id))
                            }
                        }
                        Toggle("Inclure la cartographie", isOn: $includeHeatmap)
                        Toggle("Inclure le plan d'action", isOn: $includeActionPlan)
                        Toggle("Joindre les angles bruts", isOn: $includeRawAngles)
                    }
                }

                if let session = selectedSession {
                    if includeHeatmap {
                        Section("Cartographie ergonomique") {
                            RiskMapView(summary: session.summary)
                                .frame(height: 280)
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                .listRowBackground(Color.clear)
                        }
                    }

                    if includeActionPlan {
                        Section("Plan d'action prioritaire") {
                            ActionChecklistView(
                                session: session,
                                recommendations: dashboardViewModel.recommendations(for: session.summary),
                                normativeReferences: normativeReferences
                            )
                        }
                    }

                    Section("Synthèse ISO") {
                        ForEach(session.summary.jointSummaries.filter { $0.isoStatus != .compliant }) { jointSummary in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(jointSummary.joint.localizedName)
                                    .font(.subheadline.weight(.semibold))
                                Text(jointSummary.isoDescription)
                                    .font(.caption)
                                    .foregroundColor(jointSummary.isoStatus.tintColor)
                            }
                            .padding(.vertical, 4)
                        }
                        if includeRawAngles {
                            NavigationLink("Consulter les angles détaillés") {
                                SessionDetailView(session: session)
                            }
                        }
                    }
                }

                Section("Exporter") {
                    Button("Exporter le dernier rapport PDF") {
                        Task {
                            exportResult = await dashboardViewModel.exportLatestReport()
                        }
                    }
                    .disabled(dashboardViewModel.sessions.isEmpty)

                    Button("Exporter les données CSV") {
                        Task {
                            exportResult = await dashboardViewModel.exportCSV()
                        }
                    }
                    .disabled(dashboardViewModel.sessions.isEmpty)
                }

                if let exportResult {
                    Section("Dernière exportation") {
                        Text(exportResult.message)
                            .foregroundColor(exportResult.isSuccess ? .green : .red)
                    }
                }
            }
            .navigationTitle("Rapports")
            .task {
                await dashboardViewModel.loadSessions()
            }
        }
    }
}

private struct ActionChecklistView: View {
    let session: PoseSession
    let recommendations: [AggregatedInsights.RecommendedAction]
    let normativeReferences: [String]

    private var duration: String {
        session.summary.formattedDuration
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session analysée : \(session.metadata.taskName)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Durée observée : \(duration)")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Actions recommandées")
                    .font(.headline)
                ForEach(recommendations) { recommendation in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recommendation.title)
                            .font(.subheadline.weight(.semibold))
                        Text(recommendation.details)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.tertiarySystemBackground))
                    )
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Références normatives")
                    .font(.headline)
                ForEach(normativeReferences, id: \.self) { reference in
                    Label(reference, systemImage: "book")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
