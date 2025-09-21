import Combine
import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var sessions: [PoseSession] = []
    @Published private(set) var liveMetrics: LiveMetrics?
    @Published private(set) var aggregatedInsights: AggregatedInsights?

    private let dataStore = DataStore.shared
    private var captureViewModel: CaptureViewModel?

    func bind(to captureViewModel: CaptureViewModel) {
        guard self.captureViewModel !== captureViewModel else { return }
        self.captureViewModel = captureViewModel
        captureViewModel.$latestPose
            .compactMap { $0 }
            .map { pose in
                LiveMetrics(pose: pose)
            }
            .assign(to: &$liveMetrics)
    }

    func loadSessions() async {
        do {
            sessions = try await dataStore.fetchSessions()
            updateAggregates()
        } catch {
            print("Erreur chargement sessions : \(error)")
        }
    }

    func exportLatestReport() async -> ExportResult {
        guard let session = sessions.sorted(by: { $0.metadata.date > $1.metadata.date }).first else {
            return ExportResult.failure("Aucune session disponible")
        }
        do {
            let url = try ReportService().exportPDF(for: session)
            return ExportResult.success("PDF exporté : \(url.lastPathComponent)")
        } catch {
            return ExportResult.failure("Échec export PDF : \(error.localizedDescription)")
        }
    }

    func exportCSV() async -> ExportResult {
        do {
            let url = try ReportService().exportCSV(for: sessions)
            return ExportResult.success("CSV exporté : \(url.lastPathComponent)")
        } catch {
            return ExportResult.failure("Échec export CSV : \(error.localizedDescription)")
        }
    }

    var mostRecentSession: PoseSession? {
        sessions.sorted(by: { $0.metadata.date > $1.metadata.date }).first
    }

    func recommendations(for summary: SessionSummary) -> [AggregatedInsights.RecommendedAction] {
        AggregatedInsights.recommendations(for: summary)
    }

    private func updateAggregates() {
        aggregatedInsights = AggregatedInsights(sessions: sessions)
    }
}

struct LiveMetrics {
    private let pose: PoseFrame

    init(pose: PoseFrame) {
        self.pose = pose
    }

    var repetitionFrequency: String {
        "\(pose.repetitionEstimate, specifier: "%.1f") cycles/min"
    }

    var criticalPostureDescription: String {
        pose.mostCriticalJoint?.localizedName ?? "Stable"
    }

    var isoScoreDescription: String {
        "Score ISO : \(pose.isoScore)"
    }
}

struct ExportResult {
    let isSuccess: Bool
    let message: String

    static func success(_ message: String) -> ExportResult {
        ExportResult(isSuccess: true, message: message)
    }

    static func failure(_ message: String) -> ExportResult {
        ExportResult(isSuccess: false, message: message)
    }
}

struct AggregatedInsights {
    struct BodyZoneExposure: Identifiable {
        enum BodyZone: String, CaseIterable {
            case headAndNeck
            case trunk
            case leftUpperLimb
            case rightUpperLimb
            case leftLowerLimb
            case rightLowerLimb

            var localizedName: String {
                switch self {
                case .headAndNeck:
                    return "Tête & cou"
                case .trunk:
                    return "Torse"
                case .leftUpperLimb:
                    return "Membre supérieur gauche"
                case .rightUpperLimb:
                    return "Membre supérieur droit"
                case .leftLowerLimb:
                    return "Membre inférieur gauche"
                case .rightLowerLimb:
                    return "Membre inférieur droit"
                }
            }
        }

        let zone: BodyZone
        let criticalDuration: TimeInterval
        let attentionDuration: TimeInterval
        let compliantDuration: TimeInterval
        let joints: [JointType]

        var id: BodyZone { zone }

        var totalDuration: TimeInterval {
            criticalDuration + attentionDuration + compliantDuration
        }

        var dominantStatus: SessionSummary.JointSummary.IsoStatus {
            if criticalDuration > 0 { return .critical }
            if attentionDuration > 0 { return .attention }
            if compliantDuration > 0 { return .compliant }
            return .unknown
        }

        var formattedExposure: String {
            totalDuration.formattedHoursAndMinutes
        }
    }

    struct RecommendedAction: Identifiable {
        let id = UUID()
        let title: String
        let details: String
    }

    static let defaultNormativeReferences = [
        "ISO 11226 – Postures de travail statiques",
        "ISO 11228-3 – Manutentions manuelles de charges",
        "EN 1005-4 – Sécurité des machines : posture de travail",
        "CSA Z1004 – Ergonomie au travail"
    ]

    let totalDuration: TimeInterval
    let criticalDuration: TimeInterval
    let attentionDuration: TimeInterval
    let compliantDuration: TimeInterval
    let bodyZoneExposures: [BodyZoneExposure]
    let recurringCriticalJoints: [JointType: Int]
    let recommendedActions: [RecommendedAction]
    let normativeReferences: [String]

    init(sessions: [PoseSession]) {
        totalDuration = sessions.reduce(0) { $0 + $1.summary.duration }

        var criticalDuration: TimeInterval = 0
        var attentionDuration: TimeInterval = 0
        var compliantDuration: TimeInterval = 0
        var recurringCriticalJoints: [JointType: Int] = [:]
        var zoneAccumulators: [BodyZoneExposure.BodyZone: (critical: TimeInterval, attention: TimeInterval, compliant: TimeInterval, joints: Set<JointType>)] = [:]

        for session in sessions {
            let summary = session.summary
            let duration = summary.duration

            var hasCritical = false
            var hasAttention = false

            for jointSummary in summary.jointSummaries {
                let zone = AggregatedInsights.bodyZone(for: jointSummary.joint)
                var accumulator = zoneAccumulators[zone, default: (0, 0, 0, [])]
                accumulator.joints.insert(jointSummary.joint)

                switch jointSummary.isoStatus {
                case .critical:
                    accumulator.critical += duration
                    recurringCriticalJoints[jointSummary.joint, default: 0] += 1
                    hasCritical = true
                case .attention:
                    accumulator.attention += duration
                    hasAttention = true
                case .compliant:
                    accumulator.compliant += duration
                case .unknown:
                    break
                }

                zoneAccumulators[zone] = accumulator
            }

            if hasCritical {
                criticalDuration += duration
            } else if hasAttention {
                attentionDuration += duration
            } else if !summary.jointSummaries.isEmpty {
                compliantDuration += duration
            }
        }

        self.criticalDuration = criticalDuration
        self.attentionDuration = attentionDuration
        self.compliantDuration = compliantDuration
        self.recurringCriticalJoints = recurringCriticalJoints

        bodyZoneExposures = BodyZoneExposure.BodyZone.allCases.map { zone in
            let accumulator = zoneAccumulators[zone, default: (0, 0, 0, [])]
            return BodyZoneExposure(
                zone: zone,
                criticalDuration: accumulator.critical,
                attentionDuration: accumulator.attention,
                compliantDuration: accumulator.compliant,
                joints: Array(accumulator.joints).sorted()
            )
        }

        recommendedActions = AggregatedInsights.buildRecommendedActions(
            criticalDuration: criticalDuration,
            attentionDuration: attentionDuration,
            recurringCriticalJoints: recurringCriticalJoints
        )

        normativeReferences = AggregatedInsights.defaultNormativeReferences
    }

    static func recommendations(for summary: SessionSummary) -> [RecommendedAction] {
        let criticalJoints = summary.jointSummaries.filter { $0.isoStatus == .critical }
        let attentionJoints = summary.jointSummaries.filter { $0.isoStatus == .attention }

        var actions: [RecommendedAction] = []

        if !criticalJoints.isEmpty {
            let names = criticalJoints.map { $0.joint.localizedName }.joined(separator: ", ")
            actions.append(
                RecommendedAction(
                    title: "Corriger immédiatement les postures critiques",
                    details: "Les articulations \(names) dépassent les seuils critiques ISO. Mettre en place des ajustements de poste ou une rotation des tâches sous 7 jours."
                )
            )
        }

        if !attentionJoints.isEmpty {
            let names = attentionJoints.map { $0.joint.localizedName }.joined(separator: ", ")
            actions.append(
                RecommendedAction(
                    title: "Plan d'amélioration ciblé",
                    details: "Suivre \(names) avec des micro-pauses et un coaching postural en s'appuyant sur les référentiels ISO 11226/11228."
                )
            )
        }

        if actions.isEmpty {
            actions.append(
                RecommendedAction(
                    title: "Maintenir la vigilance",
                    details: "Aucune alerte critique détectée. Consolider les bonnes pratiques et planifier une nouvelle observation d'ici 30 jours."
                )
            )
        }

        return actions
    }

    private static func bodyZone(for joint: JointType) -> BodyZoneExposure.BodyZone {
        switch joint {
        case .head, .neck:
            return .headAndNeck
        case .torso:
            return .trunk
        case .leftShoulder, .leftElbow, .leftWrist:
            return .leftUpperLimb
        case .rightShoulder, .rightElbow, .rightWrist:
            return .rightUpperLimb
        case .leftHip, .leftKnee, .leftAnkle:
            return .leftLowerLimb
        case .rightHip, .rightKnee, .rightAnkle:
            return .rightLowerLimb
        }
    }

    private static func buildRecommendedActions(criticalDuration: TimeInterval,
                                                 attentionDuration: TimeInterval,
                                                 recurringCriticalJoints: [JointType: Int]) -> [RecommendedAction] {
        var actions: [RecommendedAction] = []

        if criticalDuration > 0 {
            actions.append(
                RecommendedAction(
                    title: "Déployer un plan correctif prioritaire",
                    details: "\(criticalDuration.formattedHoursAndMinutes) passées en zone critique. Revoir l'organisation du poste, l'aide mécanique et la formation gestes & postures."
                )
            )
        }

        if attentionDuration > 0 {
            actions.append(
                RecommendedAction(
                    title: "Mettre en place un suivi renforcé",
                    details: "\(attentionDuration.formattedHoursAndMinutes) en zone de vigilance. Instaurer des pauses actives et valider les réglages ergonomiques."
                )
            )
        }

        if !recurringCriticalJoints.isEmpty {
            let topJoints = recurringCriticalJoints.sorted { $0.value > $1.value }.prefix(3)
            let description = topJoints
                .map { "\($0.key.localizedName) (\($0.value)×)" }
                .joined(separator: ", ")
            actions.append(
                RecommendedAction(
                    title: "Cibler les zones récurrentes",
                    details: "Les articulations les plus sollicitées : \(description). Prioriser des mesures correctives sur ces segments."
                )
            )
        }

        if actions.isEmpty {
            actions.append(
                RecommendedAction(
                    title: "Poursuivre la surveillance",
                    details: "Aucune dérive majeure observée. Conserver le dispositif de suivi et sensibiliser les opérateurs."
                )
            )
        }

        return actions
    }
}

extension TimeInterval {
    var formattedHoursAndMinutes: String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = self >= 3600 ? [.hour, .minute] : [.minute, .second]
        return formatter.string(from: self) ?? "0m"
    }
}
