import Foundation
import SwiftUI

struct PoseSession: Identifiable, Codable {
    let id: UUID
    let metadata: SessionMetadata
    let frames: [PoseFrame]
    let assessments: [JointAssessment]
    let metrics: [PoseMetric]
    let summary: SessionSummary

    init(id: UUID, metadata: SessionMetadata, frames: [PoseFrame], assessments: [JointAssessment], metrics: [PoseMetric], summary: SessionSummary) {
        self.id = id
        self.metadata = metadata
        self.frames = frames
        self.assessments = assessments
        self.metrics = metrics
        self.summary = summary
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case metadata
        case frames
        case assessments
        case metrics
        case summary
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        metadata = try container.decode(SessionMetadata.self, forKey: .metadata)
        frames = try container.decode([PoseFrame].self, forKey: .frames)
        assessments = try container.decode([JointAssessment].self, forKey: .assessments)
        metrics = try container.decode([PoseMetric].self, forKey: .metrics)
        if let decodedSummary = try container.decodeIfPresent(SessionSummary.self, forKey: .summary) {
            summary = decodedSummary
        } else {
            summary = SessionSummary.fallback(from: frames)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(metadata, forKey: .metadata)
        try container.encode(frames, forKey: .frames)
        try container.encode(assessments, forKey: .assessments)
        try container.encode(metrics, forKey: .metrics)
        try container.encode(summary, forKey: .summary)
    }
}

struct SessionMetadata: Codable {
    let date: Date
    let taskName: String
    let operatorName: String
    let notes: String

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct PoseMetric: Identifiable, Codable {
    let id = UUID()
    let joint: JointType
    let timestamp: Date
    let value: Double
}

struct SessionSummary: Codable {
    struct JointSummary: Identifiable, Codable {
        enum IsoStatus: String, Codable {
            case compliant
            case attention
            case critical
            case unknown

            var description: String {
                switch self {
                case .compliant:
                    return "Conforme aux normes"
                case .attention:
                    return "Surveillance requise"
                case .critical:
                    return "Dépassement critique"
                case .unknown:
                    return "Normes indisponibles"
                }
            }

            var tintColor: Color {
                switch self {
                case .compliant:
                    return .green
                case .attention:
                    return .orange
                case .critical:
                    return .red
                case .unknown:
                    return .gray
                }
            }
        }

        let joint: JointType
        let movementCount: Int
        let averageAngle: Double
        let minAngle: Double
        let maxAngle: Double
        let isoWarning: Double?
        let isoCritical: Double?
        let isoStatus: IsoStatus

        var id: JointType { joint }

        var averageDescription: String {
            "\(averageAngle, specifier: "%.1f")°"
        }

        var rangeDescription: String {
            "Min \(minAngle, specifier: "%.0f")° – Max \(maxAngle, specifier: "%.0f")°"
        }

        var isoDescription: String {
            switch isoStatus {
            case .unknown:
                return isoStatus.description
            case .compliant:
                return isoStatus.description
            case .attention, .critical:
                if let warning = isoWarning, let critical = isoCritical {
                    return "\(isoStatus.description) (alerte \(Int(warning))°, critique \(Int(critical))°)"
                } else {
                    return "\(isoStatus.description) (seuils indisponibles)"
                }
            }
        }
    }

    let duration: TimeInterval
    let frameCount: Int
    let jointSummaries: [JointSummary]

    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = duration >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        return formatter.string(from: duration) ?? "0s"
    }

    var hasJointData: Bool {
        !jointSummaries.isEmpty
    }

    static func fallback(from frames: [PoseFrame]) -> SessionSummary {
        let duration: TimeInterval
        if let first = frames.first?.timestamp, let last = frames.last?.timestamp {
            duration = max(0, last.timeIntervalSince(first))
        } else {
            duration = 0
        }

        var accumulator: [JointType: (sum: Double, count: Int, min: Double, max: Double)] = [:]
        for frame in frames {
            for (joint, angle) in frame.jointAngles {
                var entry = accumulator[joint] ?? (0, 0, .greatestFiniteMagnitude, -.greatestFiniteMagnitude)
                entry.sum += angle
                entry.count += 1
                entry.min = Swift.min(entry.min, angle)
                entry.max = Swift.max(entry.max, angle)
                accumulator[joint] = entry
            }
        }

        let thresholds = IsoThresholds()
        let jointSummaries = accumulator.map { joint, value -> JointSummary in
            let average = value.count > 0 ? value.sum / Double(value.count) : 0
            let threshold = thresholds.threshold(for: joint)
            let isoStatus: JointSummary.IsoStatus
            if let threshold {
                if average >= threshold.critical {
                    isoStatus = .critical
                } else if average >= threshold.warning {
                    isoStatus = .attention
                } else {
                    isoStatus = .compliant
                }
            } else {
                isoStatus = .unknown
            }

            return JointSummary(
                joint: joint,
                movementCount: 0,
                averageAngle: average,
                minAngle: value.min.isFinite ? value.min : 0,
                maxAngle: value.max.isFinite ? value.max : 0,
                isoWarning: threshold?.warning,
                isoCritical: threshold?.critical,
                isoStatus: isoStatus
            )
        }
        .sorted(by: { $0.joint < $1.joint })

        return SessionSummary(duration: duration, frameCount: frames.count, jointSummaries: jointSummaries)
    }
}

struct JointAssessment: Codable {
    enum RiskLevel: String, Codable {
        case low
        case medium
        case high

        var description: String {
            switch self {
            case .low:
                return "Faible"
            case .medium:
                return "Modéré"
            case .high:
                return "Élevé"
            }
        }

        var iconName: String {
            switch self {
            case .low:
                return "checkmark.circle"
            case .medium:
                return "exclamationmark.triangle"
            case .high:
                return "xmark.octagon"
            }
        }

        var tintColor: Color {
            switch self {
            case .low:
                return .green
            case .medium:
                return .orange
            case .high:
                return .red
            }
        }
    }

    let jointType: JointType
    let riskLevel: RiskLevel
    let summary: String
    let recommendations: [String]
}
