import CoreGraphics
import Foundation

typealias NormalizedPoint = CGPoint

struct PoseFrame: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let jointPositions: [JointType: NormalizedPoint]
    let jointAngles: [JointType: Double]
    let repetitionEstimate: Double
    let mostCriticalJoint: JointType?
    let isoScore: Int
    let extrapolatedJoints: Set<JointType>

    init(id: UUID = UUID(),
         timestamp: Date,
         jointPositions: [JointType: NormalizedPoint],
         jointAngles: [JointType: Double],
         repetitionEstimate: Double,
         mostCriticalJoint: JointType?,
         isoScore: Int,
         extrapolatedJoints: Set<JointType>) {
        self.id = id
        self.timestamp = timestamp
        self.jointPositions = jointPositions
        self.jointAngles = jointAngles
        self.repetitionEstimate = repetitionEstimate
        self.mostCriticalJoint = mostCriticalJoint
        self.isoScore = isoScore
        self.extrapolatedJoints = extrapolatedJoints
    }

    var jointConnections: [(JointType, JointType)] {
        [
            (.head, .neck),
            (.neck, .torso),
            (.torso, .leftShoulder),
            (.torso, .rightShoulder),
            (.leftShoulder, .leftElbow),
            (.leftElbow, .leftWrist),
            (.rightShoulder, .rightElbow),
            (.rightElbow, .rightWrist),
            (.torso, .leftHip),
            (.leftHip, .leftKnee),
            (.leftKnee, .leftAnkle),
            (.torso, .rightHip),
            (.rightHip, .rightKnee),
            (.rightKnee, .rightAnkle)
        ]
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case jointPositions
        case jointAngles
        case repetitionEstimate
        case mostCriticalJoint
        case isoScore
        case extrapolatedJoints
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        jointPositions = try container.decode([JointType: NormalizedPoint].self, forKey: .jointPositions)
        jointAngles = try container.decode([JointType: Double].self, forKey: .jointAngles)
        repetitionEstimate = try container.decode(Double.self, forKey: .repetitionEstimate)
        mostCriticalJoint = try container.decodeIfPresent(JointType.self, forKey: .mostCriticalJoint)
        isoScore = try container.decode(Int.self, forKey: .isoScore)
        extrapolatedJoints = try container.decodeIfPresent(Set<JointType>.self, forKey: .extrapolatedJoints) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(jointPositions, forKey: .jointPositions)
        try container.encode(jointAngles, forKey: .jointAngles)
        try container.encode(repetitionEstimate, forKey: .repetitionEstimate)
        try container.encodeIfPresent(mostCriticalJoint, forKey: .mostCriticalJoint)
        try container.encode(isoScore, forKey: .isoScore)
        if !extrapolatedJoints.isEmpty {
            try container.encode(extrapolatedJoints, forKey: .extrapolatedJoints)
        }
    }
}
