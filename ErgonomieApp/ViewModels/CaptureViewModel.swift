import AVFoundation
import Combine
import Foundation
import Vision

@MainActor
final class CaptureViewModel: ObservableObject {
    @Published private(set) var latestPose: PoseFrame?
    @Published private(set) var isRecording = false
    @Published private(set) var statusMessage: String?

    let captureService = CaptureService()
    private let poseEstimator = PoseEstimator()
    private let analysisService = AnalysisService()
    private let dataStore = DataStore.shared

    private var cancellables = Set<AnyCancellable>()
    private var currentSessionBuilder = PoseSessionBuilder()

    func configureIfNeeded() {
        guard !captureService.isConfigured else { return }

        captureService.requestAuthorizationIfNeeded()
        captureService.configureSession()

        captureService.sampleBufferPublisher
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .compactMap { CMSampleBufferGetImageBuffer($0) }
            .flatMap { [poseEstimator] pixelBuffer in
                poseEstimator.estimatePose(from: pixelBuffer)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pose in
                self?.handlePoseFrame(pose)
            }
            .store(in: &cancellables)

        captureService.$isSessionRunning
            .receive(on: DispatchQueue.main)
            .map { $0 ? nil : "Caméra arrêtée" }
            .assign(to: &$statusMessage)

        captureService.startRunning()
    }

    func toggleRecording() {
        isRecording.toggle()
        if isRecording {
            statusMessage = "Enregistrement en cours"
            currentSessionBuilder = PoseSessionBuilder()
        } else {
            statusMessage = "Analyse en cours"
            Task {
                await finalizeSession()
            }
        }
    }

    func stop() {
        captureService.stopRunning()
        isRecording = false
    }

    private func handlePoseFrame(_ pose: PoseFrame) {
        latestPose = pose
        guard isRecording else { return }
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
                statusMessage = "Session enregistrée"
            }
        } catch {
            await MainActor.run {
                statusMessage = "Erreur sauvegarde : \(error.localizedDescription)"
            }
        }
    }
}
