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

    func build(with assessments: [JointAssessment], metrics: [PoseMetric]) -> PoseSession {
        PoseSession(id: UUID(), metadata: metadata, frames: frames, assessments: assessments, metrics: metrics)
    }
}
