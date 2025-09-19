import Foundation

actor AnalysisService {
    private var rollingAngles: [JointType: [Double]] = [:]
    private let isoThresholds = IsoThresholds()

    func processLivePose(_ pose: PoseFrame) {
        for (joint, angle) in pose.jointAngles {
            var history = rollingAngles[joint, default: []]
            history.append(angle)
            if history.count > 120 {
                history.removeFirst()
            }
            rollingAngles[joint] = history
        }
    }

    func finalizeSession(with builder: PoseSessionBuilder) async -> PoseSession {
        let aggregated = rollingAngles.mapValues { values -> Double in
            guard !values.isEmpty else { return 0 }
            return values.reduce(0, +) / Double(values.count)
        }

        let assessments = aggregated.map { joint, value in
            isoThresholds.assessment(for: joint, angle: value)
        }

        let metrics = rollingAngles.flatMap { joint, values -> [PoseMetric] in
            values.enumerated().map { index, value in
                PoseMetric(joint: joint, timestamp: Date().addingTimeInterval(Double(index) / 30), value: value)
            }
        }

        let session = builder.build(with: assessments, metrics: metrics)
        rollingAngles.removeAll()
        return session
    }
}
