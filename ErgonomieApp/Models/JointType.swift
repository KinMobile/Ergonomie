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

    var localizedName: String {
        switch self {
        case .head:
            return "Tête"
        case .neck:
            return "Cou"
        case .leftShoulder:
            return "Épaule gauche"
        case .rightShoulder:
            return "Épaule droite"
        case .leftElbow:
            return "Coude gauche"
        case .rightElbow:
            return "Coude droit"
        case .leftWrist:
            return "Poignet gauche"
        case .rightWrist:
            return "Poignet droit"
        case .torso:
            return "Torse"
        case .leftHip:
            return "Hanche gauche"
        case .rightHip:
            return "Hanche droite"
        case .leftKnee:
            return "Genou gauche"
        case .rightKnee:
            return "Genou droit"
        case .leftAnkle:
            return "Cheville gauche"
        case .rightAnkle:
            return "Cheville droite"
        }
    }
}
