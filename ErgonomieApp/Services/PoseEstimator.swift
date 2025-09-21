import Combine
import CoreGraphics
import Foundation
import Vision

final class PoseEstimator {
    private let request = VNDetectHumanBodyPoseRequest()
    private let processingQueue = DispatchQueue(label: "pose.estimator.processing")
    private var jointPositionCache: [JointType: CachedJoint] = [:]

    private let smoothingFactor: CGFloat = 0.25
    private let cacheDuration: TimeInterval = 0.75

    func estimatePose(from pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation) -> AnyPublisher<PoseFrame, Never> {
        Future { promise in
            self.processingQueue.async {
                let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:])
                do {
                    try handler.perform([self.request])
                    let frame = try self.makePoseFrame(timestamp: Date())
                    promise(.success(frame))
                } catch {
                    print("Erreur estimation pose : \(error)")
                    promise(.success(self.emptyPoseFrame()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func makePoseFrame(timestamp: Date) throws -> PoseFrame {
        guard let observation = request.results?.first as? VNHumanBodyPoseObservation else {
            throw PoseEstimatorError.noObservation
        }

        let recognizedPoints = try observation.recognizedPoints(.all)
        cleanupCache(now: timestamp)

        var jointPositions: [JointType: NormalizedPoint] = [:]
        var extrapolated: Set<JointType> = []

        for joint in JointType.allCases {
            let threshold = confidenceThreshold(for: joint)
            if let point = recognizedPoints[joint.visionJointName], point.confidence >= threshold {
                let normalized = NormalizedPoint(x: CGFloat(point.x), y: CGFloat(point.y))
                let smoothed = smoothedPoint(for: joint, newPoint: normalized)
                jointPositions[joint] = smoothed
                jointPositionCache[joint] = CachedJoint(point: smoothed, timestamp: timestamp)
            } else if let cached = cachedPoint(for: joint, now: timestamp) {
                jointPositions[joint] = cached.point
                extrapolated.insert(joint)
            }
        }

        let jointAngles = PoseMath.computeAngles(for: jointPositions)
        let criticalJoint = PoseMath.criticalJoint(for: jointAngles)
        let isoScore = PoseMath.computeISOScore(from: jointAngles)

        return PoseFrame(
            timestamp: timestamp,
            jointPositions: jointPositions,
            jointAngles: jointAngles,
            repetitionEstimate: PoseMath.repetitionIndex(from: jointAngles),
            mostCriticalJoint: criticalJoint,
            isoScore: isoScore,
            extrapolatedJoints: extrapolated
        )
    }

    private func emptyPoseFrame() -> PoseFrame {
        PoseFrame(
            timestamp: Date(),
            jointPositions: [:],
            jointAngles: [:],
            repetitionEstimate: 0,
            mostCriticalJoint: nil,
            isoScore: 0,
            extrapolatedJoints: []
        )
    }

    private func confidenceThreshold(for joint: JointType) -> Float {
        switch joint {
        case .torso, .leftHip, .rightHip:
            return 0.12
        case .leftKnee, .rightKnee, .leftAnkle, .rightAnkle:
            return 0.1
        default:
            return 0.2
        }
    }

    private func smoothedPoint(for joint: JointType, newPoint: NormalizedPoint) -> NormalizedPoint {
        guard let cached = jointPositionCache[joint] else {
            return newPoint
        }

        return NormalizedPoint(
            x: cached.point.x + (newPoint.x - cached.point.x) * smoothingFactor,
            y: cached.point.y + (newPoint.y - cached.point.y) * smoothingFactor
        )
    }

    private func cachedPoint(for joint: JointType, now: Date) -> CachedJoint? {
        guard let cached = jointPositionCache[joint] else { return nil }
        if now.timeIntervalSince(cached.timestamp) <= cacheDuration {
            return cached
        }
        jointPositionCache.removeValue(forKey: joint)
        return nil
    }

    private func cleanupCache(now: Date) {
        jointPositionCache = jointPositionCache.filter { now.timeIntervalSince($0.value.timestamp) <= cacheDuration }
    }
}

private extension JointType {
    var visionJointName: VNHumanBodyPoseObservation.JointName {
        switch self {
        case .head:
            return .head
        case .neck:
            return .neck
        case .leftShoulder:
            return .leftShoulder
        case .rightShoulder:
            return .rightShoulder
        case .leftElbow:
            return .leftElbow
        case .rightElbow:
            return .rightElbow
        case .leftWrist:
            return .leftWrist
        case .rightWrist:
            return .rightWrist
        case .torso:
            return .root
        case .leftHip:
            return .leftHip
        case .rightHip:
            return .rightHip
        case .leftKnee:
            return .leftKnee
        case .rightKnee:
            return .rightKnee
        case .leftAnkle:
            return .leftAnkle
        case .rightAnkle:
            return .rightAnkle
        }
    }
}

private struct CachedJoint {
    let point: NormalizedPoint
    let timestamp: Date
}

enum PoseEstimatorError: Error {
    case noObservation
}
