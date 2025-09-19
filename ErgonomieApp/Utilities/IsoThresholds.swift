import Foundation

struct IsoThresholds: Codable {
    struct Threshold: Codable {
        let warning: Double
        let critical: Double
        let maxDuration: TimeInterval
    }

    private let thresholds: [JointType: Threshold]

    init() {
        if let url = Bundle.main.url(forResource: "isoThresholds", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([String: Threshold].self, from: data) {
            var mapped: [JointType: Threshold] = [:]
            for (key, value) in decoded {
                if let joint = JointType(rawValue: key) {
                    mapped[joint] = value
                }
            }
            thresholds = mapped
        } else {
            thresholds = [:]
        }
    }

    func assessment(for joint: JointType, angle: Double) -> JointAssessment {
        let threshold = thresholds[joint] ?? Threshold(warning: 45, critical: 75, maxDuration: 4)
        let riskLevel: JointAssessment.RiskLevel
        if angle >= threshold.critical {
            riskLevel = .high
        } else if angle >= threshold.warning {
            riskLevel = .medium
        } else {
            riskLevel = .low
        }

        let summary = "Angle moyen : \(Int(angle))° (seuil alerte : \(Int(threshold.warning))°)"
        let recommendations: [String]
        switch riskLevel {
        case .low:
            recommendations = ["Maintenir la posture dans les limites actuelles"]
        case .medium:
            recommendations = ["Planifier des pauses", "Ajuster le poste"]
        case .high:
            recommendations = ["Action immédiate", "Revoir l'organisation du travail"]
        }

        return JointAssessment(jointType: joint, riskLevel: riskLevel, summary: summary, recommendations: recommendations)
    }
}
