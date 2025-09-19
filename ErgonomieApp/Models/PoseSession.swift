import Foundation
import SwiftUI

struct PoseSession: Identifiable, Codable {
    let id: UUID
    let metadata: SessionMetadata
    let frames: [PoseFrame]
    let assessments: [JointAssessment]
    let metrics: [PoseMetric]
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
