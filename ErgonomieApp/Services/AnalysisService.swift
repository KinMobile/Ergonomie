import Foundation

actor AnalysisService {
    private struct AngleAccumulator {
        var min: Double = .greatestFiniteMagnitude
        var max: Double = -.greatestFiniteMagnitude
        var sum: Double = 0
        var count: Int = 0

        mutating func add(_ value: Double) {
            min = Swift.min(min, value)
            max = Swift.max(max, value)
            sum += value
            count += 1
        }

        var average: Double {
            guard count > 0 else { return 0 }
            return sum / Double(count)
        }
    }

    private let isoThresholds = IsoThresholds()
    private var accumulators: [JointType: AngleAccumulator] = [:]
    private var movementCounts: [JointType: Int] = [:]
    private var lastAngles: [JointType: Double] = [:]

    func startSession() {
        accumulators.removeAll()
        movementCounts.removeAll()
        lastAngles.removeAll()
    }

    func processLivePose(_ pose: PoseFrame) {
        for (joint, angle) in pose.jointAngles {
            var accumulator = accumulators[joint, default: AngleAccumulator()]
            accumulator.add(angle)
            accumulators[joint] = accumulator

            if let last = lastAngles[joint], abs(angle - last) >= 7 {
                movementCounts[joint, default: 0] += 1
            }
            lastAngles[joint] = angle
        }
    }

    func finalizeSession(with builder: PoseSessionBuilder) async -> PoseSession {
        let frames = builder.recordedFrames
        let metrics = frames.flatMap { frame -> [PoseMetric] in
            frame.jointAngles.map { joint, value in
                PoseMetric(joint: joint, timestamp: frame.timestamp, value: value)
            }
        }

        let assessments = accumulators.map { joint, accumulator in
            isoThresholds.assessment(for: joint, angle: accumulator.average)
        }

        let jointSummaries = accumulators.map { joint, accumulator -> SessionSummary.JointSummary in
            let threshold = isoThresholds.threshold(for: joint)
            let minAngle = accumulator.min.isFinite ? accumulator.min : 0
            let maxAngle = accumulator.max.isFinite ? accumulator.max : 0
            let average = accumulator.average
            let isoStatus: SessionSummary.JointSummary.IsoStatus
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

            return SessionSummary.JointSummary(
                joint: joint,
                movementCount: movementCounts[joint, default: 0],
                averageAngle: average,
                minAngle: minAngle,
                maxAngle: maxAngle,
                isoWarning: threshold?.warning,
                isoCritical: threshold?.critical,
                isoStatus: isoStatus
            )
        }
        .sorted(by: { $0.joint < $1.joint })

        let summary = SessionSummary(
            duration: builder.sessionDuration,
            frameCount: builder.frameCount,
            jointSummaries: jointSummaries
        )

        let session = builder.build(
            with: assessments.sorted(by: { $0.jointType < $1.jointType }),
            metrics: metrics.sorted(by: { $0.timestamp < $1.timestamp }),
            summary: summary
        )

        startSession()
        return session
    }
}
