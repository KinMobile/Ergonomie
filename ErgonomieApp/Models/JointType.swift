import Foundation

enum JointType: String, CaseIterable, Codable, Comparable {
    case head
    case neck
    case leftShoulder
    case rightShoulder
    case leftElbow
    case rightElbow
    case leftWrist
    case rightWrist
    case torso
    case leftHip
    case rightHip
    case leftKnee
    case rightKnee
    case leftAnkle
    case rightAnkle

    static func < (lhs: JointType, rhs: JointType) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
