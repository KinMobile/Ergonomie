import CoreGraphics
import Foundation

enum PoseMath {
    static func computeAngles(for joints: [JointType: NormalizedPoint]) -> [JointType: Double] {
        var angles: [JointType: Double] = [:]

        func angle(between joint: JointType, _ first: JointType, _ second: JointType) -> Double? {
            guard let center = joints[joint],
                  let pointA = joints[first],
                  let pointB = joints[second] else {
                return nil
            }
            let vectorA = CGVector(dx: pointA.x - center.x, dy: pointA.y - center.y)
            let vectorB = CGVector(dx: pointB.x - center.x, dy: pointB.y - center.y)
            let dotProduct = vectorA.dx * vectorB.dx + vectorA.dy * vectorB.dy
            let magnitudeA = sqrt(vectorA.dx * vectorA.dx + vectorA.dy * vectorA.dy)
            let magnitudeB = sqrt(vectorB.dx * vectorB.dx + vectorB.dy * vectorB.dy)
            guard magnitudeA > 0, magnitudeB > 0 else { return nil }
            let cosine = max(-1, min(1, dotProduct / (magnitudeA * magnitudeB)))
            let radians = acos(cosine)
            return radians * 180 / .pi
        }

        let definitions: [(JointType, JointType, JointType)] = [
            (.leftElbow, .leftShoulder, .leftWrist),
            (.rightElbow, .rightShoulder, .rightWrist),
            (.leftShoulder, .torso, .leftElbow),
            (.rightShoulder, .torso, .rightElbow),
            (.torso, .leftHip, .rightHip),
            (.leftKnee, .leftHip, .leftAnkle),
            (.rightKnee, .rightHip, .rightAnkle),
            (.leftHip, .torso, .leftKnee),
            (.rightHip, .torso, .rightKnee)
        ]

        for definition in definitions {
            if let value = angle(between: definition.0, definition.1, definition.2) {
                angles[definition.0] = value
            }
        }
        return angles
    }

    static func criticalJoint(for angles: [JointType: Double]) -> JointType? {
        angles.max(by: { lhs, rhs in
            isoWeight(for: lhs.key) * lhs.value < isoWeight(for: rhs.key) * rhs.value
        })?.key
    }

    static func repetitionIndex(from angles: [JointType: Double]) -> Double {
        let average = angles.values.reduce(0, +) / Double(max(angles.count, 1))
        return min(60, max(0, average / 3))
    }

    static func computeISOScore(from angles: [JointType: Double]) -> Int {
        let total = angles.reduce(0.0) { partial, element in
            partial + element.value * isoWeight(for: element.key)
        }
        return Int(total / Double(max(angles.count, 1)))
    }

    private static func isoWeight(for joint: JointType) -> Double {
        switch joint {
        case .leftShoulder, .rightShoulder:
            return 1.5
        case .leftElbow, .rightElbow:
            return 1.2
        case .torso:
            return 2.0
        case .leftHip, .rightHip:
            return 1.3
        default:
            return 1.0
        }
    }
}
