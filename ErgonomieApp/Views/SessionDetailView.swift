import Charts
import SwiftUI

struct SessionDetailView: View {
    let session: PoseSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeader("Synthèse de session")
                SessionSummarySection(summary: session.summary)

                SectionHeader("Résumé ISO")
                ForEach(session.assessments.sorted(by: { $0.jointType.rawValue < $1.jointType.rawValue }), id: \.jointType) { assessment in
                    AssessmentCard(assessment: assessment)
                }

                SectionHeader("Angles clés")
                Chart(session.metrics) { metric in
                    LineMark(
                        x: .value("Temps", metric.timestamp),
                        y: .value("Angle", metric.value)
                    )
                    .foregroundStyle(by: .value("Articulation", metric.joint.rawValue))
                }
                .frame(height: 240)
            }
            .padding()
        }
        .navigationTitle(session.metadata.taskName)
    }
}

private struct SectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.title2.bold())
    }
}

private struct AssessmentCard: View {
    let assessment: JointAssessment

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(assessment.jointType.localizedName)
                    .font(.headline)
                Spacer()
                Label(assessment.riskLevel.description, systemImage: assessment.riskLevel.iconName)
                    .foregroundColor(assessment.riskLevel.tintColor)
            }
            Text(assessment.summary)
                .font(.body)
            Text("Recommandations : \(assessment.recommendations.joined(separator: ", "))")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }
}

private struct SessionSummarySection: View {
    let summary: SessionSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(summary.formattedDuration, systemImage: "clock")
                Spacer()
                Label("\(summary.frameCount) frames", systemImage: "video")
            }
            .font(.subheadline)

            if summary.hasJointData {
                Divider()
                ForEach(summary.jointSummaries) { jointSummary in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(jointSummary.joint.localizedName)
                                .font(.headline)
                            Spacer()
                            Text("\(jointSummary.movementCount) mouvements")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text("Angle moyen : \(jointSummary.averageAngle, specifier: "%.1f")°")
                            .font(.subheadline)
                        Text(jointSummary.rangeDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(jointSummary.isoDescription)
                            .font(.caption2)
                            .foregroundColor(jointSummary.isoStatus.tintColor)
                    }
                    .padding(.vertical, 8)
                }
            } else {
                Text("Aucune donnée articulatoire enregistrée.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }
}
