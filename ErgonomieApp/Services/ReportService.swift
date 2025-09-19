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
            for assessment in session.assessments {
                let text = "• \(assessment.jointType.rawValue): \(assessment.riskLevel.description)"
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
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Sessions.csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
