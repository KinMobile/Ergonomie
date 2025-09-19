import Combine
import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var sessions: [PoseSession] = []
    @Published private(set) var liveMetrics: LiveMetrics?

    private let dataStore = DataStore.shared
    private var captureViewModel: CaptureViewModel?

    func bind(to captureViewModel: CaptureViewModel) {
        guard self.captureViewModel !== captureViewModel else { return }
        self.captureViewModel = captureViewModel
        captureViewModel.$latestPose
            .compactMap { $0 }
            .map { pose in
                LiveMetrics(pose: pose)
            }
            .assign(to: &$liveMetrics)
    }

    func loadSessions() async {
        do {
            sessions = try await dataStore.fetchSessions()
        } catch {
            print("Erreur chargement sessions : \(error)")
        }
    }

    func exportLatestReport() async -> ExportResult {
        guard let session = sessions.sorted(by: { $0.metadata.date > $1.metadata.date }).first else {
            return ExportResult.failure("Aucune session disponible")
        }
        do {
            let url = try ReportService().exportPDF(for: session)
            return ExportResult.success("PDF exporté : \(url.lastPathComponent)")
        } catch {
            return ExportResult.failure("Échec export PDF : \(error.localizedDescription)")
        }
    }

    func exportCSV() async -> ExportResult {
        do {
            let url = try ReportService().exportCSV(for: sessions)
            return ExportResult.success("CSV exporté : \(url.lastPathComponent)")
        } catch {
            return ExportResult.failure("Échec export CSV : \(error.localizedDescription)")
        }
    }
}

struct LiveMetrics {
    private let pose: PoseFrame

    init(pose: PoseFrame) {
        self.pose = pose
    }

    var repetitionFrequency: String {
        "\(pose.repetitionEstimate, specifier: "%.1f") cycles/min"
    }

    var criticalPostureDescription: String {
        pose.mostCriticalJoint?.rawValue ?? "Stable"
    }

    var isoScoreDescription: String {
        "Score ISO : \(pose.isoScore)"
    }
}

struct ExportResult {
    let isSuccess: Bool
    let message: String

    static func success(_ message: String) -> ExportResult {
        ExportResult(isSuccess: true, message: message)
    }

    static func failure(_ message: String) -> ExportResult {
        ExportResult(isSuccess: false, message: message)
    }
}
