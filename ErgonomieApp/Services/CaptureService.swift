import AVFoundation
import Combine
import Foundation
import ImageIO
import UIKit

final class CaptureService: NSObject, ObservableObject {
    @Published private(set) var isSessionRunning = false
    @Published private(set) var imageOrientation: CGImagePropertyOrientation

    private(set) lazy var session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "capture.session.queue")
    private let sampleBufferSubject = PassthroughSubject<CMSampleBuffer, Never>()
    private let videoOutput = AVCaptureVideoDataOutput()

    private var currentVideoOrientation: AVCaptureVideoOrientation = .portrait {
        didSet {
            let targetOrientation = currentVideoOrientation.cgImageOrientation(for: .back)
            DispatchQueue.main.async { [weak self] in
                self?.imageOrientation = targetOrientation
            }
            applyCurrentOrientation()
        }
    }

    var isConfigured = false

    var sampleBufferPublisher: AnyPublisher<CMSampleBuffer, Never> {
        sampleBufferSubject.eraseToAnyPublisher()
    }

    override init() {
        imageOrientation = AVCaptureVideoOrientation.portrait.cgImageOrientation(for: .back)
        super.init()
        configureOrientationMonitoring()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                completion(true)
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted {
                    print("Accès caméra refusé")
                }
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        default:
            DispatchQueue.main.async {
                print("Autorisations caméra insuffisantes")
                completion(false)
            }
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

            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            }
            applyCurrentOrientation()
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
        if connection.isVideoOrientationSupported, connection.videoOrientation != currentVideoOrientation {
            connection.videoOrientation = currentVideoOrientation
        }
        if connection.isVideoMirroringSupported {
            connection.isVideoMirrored = false
        }
        sampleBufferSubject.send(sampleBuffer)
    }
}

// MARK: - Orientation handling

private extension CaptureService {
    func configureOrientationMonitoring() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDeviceOrientationChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    @objc func handleDeviceOrientationChange() {
        guard let deviceOrientation = UIDevice.current.captureVideoOrientation else { return }
        guard deviceOrientation != currentVideoOrientation else { return }
        currentVideoOrientation = deviceOrientation
    }

    func applyCurrentOrientation() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard let connection = self.videoOutput.connection(with: .video) else { return }
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = self.currentVideoOrientation
            }
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = false
            }
        }
    }
}

private extension UIDevice {
    var captureVideoOrientation: AVCaptureVideoOrientation? {
        switch orientation {
        case .portrait:
            return .portrait
        case .landscapeRight:
            return .landscapeLeft
        case .landscapeLeft:
            return .landscapeRight
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return nil
        }
    }
}

private extension AVCaptureVideoOrientation {
    func cgImageOrientation(for position: AVCaptureDevice.Position) -> CGImagePropertyOrientation {
        switch (self, position) {
        case (.portrait, .back):
            return .right
        case (.portrait, .front):
            return .leftMirrored
        case (.portraitUpsideDown, .back):
            return .left
        case (.portraitUpsideDown, .front):
            return .rightMirrored
        case (.landscapeLeft, .back):
            return .down
        case (.landscapeLeft, .front):
            return .upMirrored
        case (.landscapeRight, .back):
            return .up
        case (.landscapeRight, .front):
            return .downMirrored
        @unknown default:
            return .right
        }
    }
}
