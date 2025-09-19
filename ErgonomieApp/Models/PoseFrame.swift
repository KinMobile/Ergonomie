import CoreGraphics
import Foundation

typealias NormalizedPoint = CGPoint

struct PoseFrame: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let jointPositions: [JointType: NormalizedPoint]
    let jointAngles: [JointType: Double]
    let repetitionEstimate: Double
    let mostCriticalJoint: JointType?
    let isoScore: Int

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
}
