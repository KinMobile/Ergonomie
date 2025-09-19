import Foundation
import PDFKit
import UIKit

struct ReportService {
    func exportPDF(for session: PoseSession) throws -> URL {
        let pageBounds = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)
        let data = renderer.pdfData { context in
            context.beginPage()
            let title = "Rapport ergonomique – \(session.metadata.taskName)"
            title.draw(at: CGPoint(x: 32, y: 32), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 22)])
            var yOffset: CGFloat = 80

            let summary = session.summary
            let summaryText = "Durée : \(summary.formattedDuration)  •  Frames : \(summary.frameCount)"
            summaryText.draw(at: CGPoint(x: 40, y: yOffset), withAttributes: [.font: UIFont.systemFont(ofSize: 14)])
            yOffset += 28

            if summary.hasJointData {
                "Analyse articulations :".draw(at: CGPoint(x: 40, y: yOffset), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 16)])
                yOffset += 24
                for jointSummary in summary.jointSummaries {
                    let jointTitle = "• \(jointSummary.joint.localizedName) – \(jointSummary.movementCount) mouvements"
                    jointTitle.draw(at: CGPoint(x: 40, y: yOffset), withAttributes: [.font: UIFont.systemFont(ofSize: 13)])
                    yOffset += 20
                    let angleText = "   Angle moyen : \(String(format: "%.1f", jointSummary.averageAngle))° (min \(Int(jointSummary.minAngle))° / max \(Int(jointSummary.maxAngle))°)"
                    angleText.draw(at: CGPoint(x: 40, y: yOffset), withAttributes: [.font: UIFont.systemFont(ofSize: 12)])
                    yOffset += 18
                    let isoText = "   ISO : \(jointSummary.isoDescription)"
                    isoText.draw(at: CGPoint(x: 40, y: yOffset), withAttributes: [.font: UIFont.systemFont(ofSize: 12)])
                    yOffset += 24
                }
            }

            yOffset += 8
            for assessment in session.assessments {
                let text = "• \(assessment.jointType.localizedName): \(assessment.riskLevel.description)"
                text.draw(at: CGPoint(x: 40, y: yOffset), withAttributes: [.font: UIFont.systemFont(ofSize: 14)])
                yOffset += 24
            }
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Rapport-\(session.id).pdf")
        try data.write(to: url)
        return url
    }

    func exportCSV(for sessions: [PoseSession]) throws -> URL {
        var csv = "session_id,task_name,joint,timestamp,angle\n"
        for session in sessions {
            for metric in session.metrics {
                csv.append("\(session.id.uuidString),\(session.metadata.taskName),\(metric.joint.rawValue),\(metric.timestamp.timeIntervalSince1970),\(metric.value)\n")
            }
        }
        csv.append("\n")
        csv.append("session_id,task_name,joint,movements,average_angle,min_angle,max_angle,iso_status\n")
        for session in sessions {
            for jointSummary in session.summary.jointSummaries {
                csv.append("\(session.id.uuidString),\(session.metadata.taskName),\(jointSummary.joint.rawValue),\(jointSummary.movementCount),\(jointSummary.averageAngle),\(jointSummary.minAngle),\(jointSummary.maxAngle),\(jointSummary.isoStatus.rawValue)\n")
            }
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Sessions.csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
