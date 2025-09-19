import Foundation

final class PoseSessionBuilder {
    private var frames: [PoseFrame] = []
    private var metadata = SessionMetadata(date: Date(), taskName: "", operatorName: "", notes: "")

    func updateMetadata(task: String, operatorName: String, notes: String) {
        metadata = SessionMetadata(date: Date(), taskName: task, operatorName: operatorName, notes: notes)
    }

    func addPoseFrame(_ frame: PoseFrame) {
        frames.append(frame)
    }

    var frameCount: Int {
        frames.count
    }

    var sessionDuration: TimeInterval {
        guard let first = frames.first?.timestamp, let last = frames.last?.timestamp else { return 0 }
        return max(0, last.timeIntervalSince(first))
    }

    var recordedFrames: [PoseFrame] {
        frames
    }

    func build(with assessments: [JointAssessment], metrics: [PoseMetric], summary: SessionSummary) -> PoseSession {
        PoseSession(
            id: UUID(),
            metadata: metadata,
            frames: frames,
            assessments: assessments,
            metrics: metrics,
            summary: summary
        )
    }
}
