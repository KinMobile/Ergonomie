import Combine
import CoreGraphics
import Foundation
import Vision

final class PoseEstimator {
    private let request = VNDetectHumanBodyPoseRequest()

    func estimatePose(from pixelBuffer: CVPixelBuffer) -> AnyPublisher<PoseFrame, Never> {
        Future { promise in
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
            do {
                try handler.perform([self.request])
                let frame = try self.makePoseFrame()
                promise(.success(frame))
            } catch {
                print("Erreur estimation pose : \(error)")
                promise(.success(self.emptyPoseFrame()))
            }
        }
        .eraseToAnyPublisher()
    }

    private func makePoseFrame() throws -> PoseFrame {
        guard let observation = request.results?.first as? VNHumanBodyPoseObservation else {
            throw PoseEstimatorError.noObservation
        }

        let recognizedPoints = try observation.recognizedPoints(.all)
        var jointPositions: [JointType: NormalizedPoint] = [:]
        for joint in JointType.allCases {
            if let point = recognizedPoints[joint.visionJointName], point.confidence > 0.2 {
                jointPositions[joint] = NormalizedPoint(x: CGFloat(point.x), y: CGFloat(point.y))
            }
        }

        let jointAngles = PoseMath.computeAngles(for: jointPositions)
        let criticalJoint = PoseMath.criticalJoint(for: jointAngles)
        let isoScore = PoseMath.computeISOScore(from: jointAngles)

        return PoseFrame(
            timestamp: Date(),
            jointPositions: jointPositions,
            jointAngles: jointAngles,
            repetitionEstimate: PoseMath.repetitionIndex(from: jointAngles),
            mostCriticalJoint: criticalJoint,
            isoScore: isoScore
        )
    }

    private func emptyPoseFrame() -> PoseFrame {
        PoseFrame(
            timestamp: Date(),
            jointPositions: [:],
            jointAngles: [:],
            repetitionEstimate: 0,
            mostCriticalJoint: nil,
            isoScore: 0
        )
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

enum PoseEstimatorError: Error {
    case noObservation
}
