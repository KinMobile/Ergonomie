import SwiftUI

struct CaptureScreen: View {
    @EnvironmentObject private var captureViewModel: CaptureViewModel
    @EnvironmentObject private var dashboardViewModel: DashboardViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            CameraPreviewView(session: captureViewModel.captureService.session)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                PoseOverlayView(pose: captureViewModel.latestPose)
                    .frame(height: 200)
                    .padding(.horizontal)

                CaptureControls()
            }
            .padding()
            .background(.regularMaterial)
        }
        .onAppear {
            captureViewModel.configureIfNeeded()
            dashboardViewModel.bind(to: captureViewModel)
        }
        .onDisappear {
            captureViewModel.stop()
        }
    }
}

private struct CaptureControls: View {
    @EnvironmentObject private var captureViewModel: CaptureViewModel

    var body: some View {
        HStack(spacing: 24) {
            Button(action: captureViewModel.toggleRecording) {
                Label(captureViewModel.isRecording ? "Arrêter" : "Enregistrer",
                      systemImage: captureViewModel.isRecording ? "stop.circle" : "record.circle")
                    .font(.title3.bold())
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(Color.accentColor.opacity(0.2))
                    .clipShape(Capsule())
            }

            if let message = captureViewModel.statusMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
}
