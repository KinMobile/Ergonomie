import AVFoundation
import Combine
import Foundation
import Vision

@MainActor
final class CaptureViewModel: ObservableObject {
    @Published private(set) var latestPose: PoseFrame?
    @Published private(set) var isLiveAnalyzing = false
    @Published private(set) var statusMessage: String?
    @Published private(set) var authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @Published private(set) var lastSessionSummary: SessionSummary?

    let captureService = CaptureService()
    private let poseEstimator = PoseEstimator()
    private let analysisService = AnalysisService()
    private let dataStore = DataStore.shared

    private var cancellables = Set<AnyCancellable>()
    private var currentSessionBuilder = PoseSessionBuilder()
    private var hasConfiguredPipeline = false

    func configureIfNeeded() {
        captureService.requestAuthorizationIfNeeded { [weak self] granted in
            guard let self else { return }
            Task { @MainActor in
                self.authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
                guard granted else {
                    self.statusMessage = "Autorisation caméra requise"
                    return
                }
                self.setupSessionIfNeeded()
            }
        }
    }

    func startLiveAnalysis() {
        guard authorizationStatus == .authorized else {
            statusMessage = "Autorisation caméra requise"
            return
        }
        guard !isLiveAnalyzing else { return }

        lastSessionSummary = nil
        currentSessionBuilder = PoseSessionBuilder()
        isLiveAnalyzing = true
        statusMessage = "Analyse en direct"

        Task {
            await analysisService.startSession()
        }
    }

    func stopLiveAnalysis() {
        guard isLiveAnalyzing else { return }

        isLiveAnalyzing = false
        statusMessage = "Analyse en cours"

        Task {
            await finalizeSession()
        }
    }

    func stop() {
        captureService.stopRunning()
        isLiveAnalyzing = false
    }

    private func handlePoseFrame(_ pose: PoseFrame) {
        latestPose = pose
        guard isLiveAnalyzing else { return }
        currentSessionBuilder.addPoseFrame(pose)
        Task {
            await analysisService.processLivePose(pose)
        }
    }

    private func finalizeSession() async {
        let session = await analysisService.finalizeSession(with: currentSessionBuilder)
        do {
            try await dataStore.save(session: session)
            await MainActor.run {
                lastSessionSummary = session.summary
                statusMessage = "Rapport enregistré"
            }
        } catch {
            await MainActor.run {
                statusMessage = "Erreur sauvegarde : \(error.localizedDescription)"
            }
        }
    }

    private func setupSessionIfNeeded() {
        guard !hasConfiguredPipeline else {
            captureService.startRunning()
            statusMessage = "Caméra prête"
            return
        }

        captureService.configureSession()

        captureService.sampleBufferPublisher
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .compactMap { CMSampleBufferGetImageBuffer($0) }
            .flatMap { [poseEstimator, captureService] pixelBuffer in
                poseEstimator.estimatePose(from: pixelBuffer, orientation: captureService.imageOrientation)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pose in
                self?.handlePoseFrame(pose)
            }
            .store(in: &cancellables)

        captureService.$isSessionRunning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] running in
                guard let self else { return }
                if running {
                    if !self.isLiveAnalyzing {
                        self.statusMessage = "Caméra prête"
                    }
                } else {
                    self.statusMessage = "Caméra arrêtée"
                    self.isLiveAnalyzing = false
                }
            }
            .store(in: &cancellables)

        captureService.startRunning()
        hasConfiguredPipeline = true
    }
}
