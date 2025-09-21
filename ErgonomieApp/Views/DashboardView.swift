import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var dashboardViewModel: DashboardViewModel

    var body: some View {
        NavigationView {
            List {
                Section("Session en cours") {
                    if let metrics = dashboardViewModel.liveMetrics {
                        LiveMetricsSection(metrics: metrics)
                    } else {
                        Text("Aucune donnée en direct")
                            .foregroundColor(.secondary)
                    }
                }

                if let summary = dashboardViewModel.mostRecentSession?.summary {
                    Section("Cartographie des risques") {
                        RiskMapView(summary: summary)
                            .frame(height: 280)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowBackground(Color.clear)
                    }
                }

                if let insights = dashboardViewModel.aggregatedInsights {
                    Section("Analyse stratégique") {
                        AggregatedInsightsSection(insights: insights)
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

                if let insights = dashboardViewModel.aggregatedInsights {
                    Section("Référentiels ergonomiques") {
                        ForEach(insights.normativeReferences, id: \.self) { reference in
                            Label(reference, systemImage: "checkmark.seal")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Tableau de bord")
            .task {
                await dashboardViewModel.loadSessions()
            }
        }
    }
}

private struct LiveMetricsSection: View {
    let metrics: LiveMetrics

    var body: some View {
        VStack(spacing: 12) {
            MetricRow(title: "Fréquence répétitions", value: metrics.repetitionFrequency, icon: "gobackward")
            MetricRow(title: "Posture critique", value: metrics.criticalPostureDescription, icon: "figure.wave")
            MetricRow(title: "Score ISO", value: metrics.isoScoreDescription, icon: "chart.bar.doc.horizontal")
        }
        .padding(.vertical, 8)
    }
}

private struct MetricRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
            }
            Spacer()
        }
    }
}

private struct AggregatedInsightsSection: View {
    let insights: AggregatedInsights

    private var exposures: [AggregatedInsights.BodyZoneExposure] {
        insights.bodyZoneExposures
            .filter { $0.totalDuration > 0 }
            .sorted { lhs, rhs in
                if lhs.dominantStatus.severityRank == rhs.dominantStatus.severityRank {
                    return lhs.totalDuration > rhs.totalDuration
                }
                return lhs.dominantStatus.severityRank > rhs.dominantStatus.severityRank
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ViewThatFits {
                HStack(spacing: 16) {
                    DurationBadge(title: "Durée critique", value: insights.criticalDuration.formattedHoursAndMinutes, tint: .red)
                    DurationBadge(title: "Zone de vigilance", value: insights.attentionDuration.formattedHoursAndMinutes, tint: .orange)
                    DurationBadge(title: "Conforme", value: insights.compliantDuration.formattedHoursAndMinutes, tint: .green)
                }
                VStack(spacing: 12) {
                    DurationBadge(title: "Durée critique", value: insights.criticalDuration.formattedHoursAndMinutes, tint: .red)
                    DurationBadge(title: "Zone de vigilance", value: insights.attentionDuration.formattedHoursAndMinutes, tint: .orange)
                    DurationBadge(title: "Conforme", value: insights.compliantDuration.formattedHoursAndMinutes, tint: .green)
                }
            }

            if !exposures.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Zones sensibles récurrentes")
                        .font(.headline)
                    ForEach(exposures) { exposure in
                        BodyZoneExposureRow(exposure: exposure)
                    }
                }
            }

            if !insights.recommendedActions.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommandations inspirées de Nawo Live")
                        .font(.headline)
                    ForEach(insights.recommendedActions) { action in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(action.title)
                                .font(.subheadline.weight(.semibold))
                            Text(action.details)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

private struct DurationBadge: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .foregroundColor(tint)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

private struct BodyZoneExposureRow: View {
    let exposure: AggregatedInsights.BodyZoneExposure

    private var tint: Color {
        switch exposure.dominantStatus {
        case .critical:
            return .red
        case .attention:
            return .orange
        case .compliant:
            return .green
        case .unknown:
            return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(exposure.zone.localizedName)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(exposure.dominantStatus.description)
                    .font(.caption)
                    .foregroundColor(tint)
            }
            Text("Exposition cumulée : \(exposure.formattedExposure)")
                .font(.caption)
                .foregroundColor(.secondary)
            if !exposure.joints.isEmpty {
                Text("Articulations suivies : \(exposure.joints.map { $0.localizedName }.joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}
