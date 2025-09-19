import AVFoundation
import Combine
import Foundation

final class CaptureService: NSObject, ObservableObject {
    @Published private(set) var isSessionRunning = false

    private(set) lazy var session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "capture.session.queue")
    private let sampleBufferSubject = PassthroughSubject<CMSampleBuffer, Never>()

    var isConfigured = false

    var sampleBufferPublisher: AnyPublisher<CMSampleBuffer, Never> {
        sampleBufferSubject.eraseToAnyPublisher()
    }

    func requestAuthorizationIfNeeded() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted {
                    print("Accès caméra refusé")
                }
            }
        default:
            print("Autorisations caméra insuffisantes")
        }
    }

    func configureSession() {
        guard !isConfigured else { return }
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Caméra arrière indisponible")
            session.commitConfiguration()
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }

            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            output.setSampleBufferDelegate(self, queue: sessionQueue)
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
        } catch {
            print("Erreur configuration session : \(error)")
        }

        session.commitConfiguration()
        isConfigured = true
    }

    func startRunning() {
        guard isConfigured else { return }
        sessionQueue.async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = true
            }
        }
    }

    func stopRunning() {
        guard isConfigured else { return }
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = false
            }
        }
    }
}

extension CaptureService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        sampleBufferSubject.send(sampleBuffer)
    }
}
