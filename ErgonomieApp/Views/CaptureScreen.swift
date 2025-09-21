import AVFoundation
import SwiftUI

struct CaptureScreen: View {
    @EnvironmentObject private var captureViewModel: CaptureViewModel
    @EnvironmentObject private var dashboardViewModel: DashboardViewModel
    @State private var bottomPanelHeight: CGFloat = 0

    var body: some View {
        ZStack {
            CameraPreviewView(session: captureViewModel.captureService.session)
                .ignoresSafeArea()

            if captureViewModel.authorizationStatus != .authorized {
                PermissionOverlay(status: captureViewModel.authorizationStatus)
            }

            VStack {
                Spacer()

                BottomPanel()
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .padding()
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(key: BottomPanelHeightPreferenceKey.self, value: proxy.size.height)
                        }
                    )
            }
        }
        .overlay(alignment: .bottomTrailing) {
            PoseOverlayView(pose: captureViewModel.latestPose, contentInset: 10)
                .frame(width: 140, height: 220)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 8)
                .padding(.trailing, 24)
                .padding(.bottom, bottomPanelHeight + 24)
                .allowsHitTesting(false)
        }
        .onPreferenceChange(BottomPanelHeightPreferenceKey.self) { height in
            bottomPanelHeight = height
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

private struct BottomPanelHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct CaptureControls: View {
    @EnvironmentObject private var captureViewModel: CaptureViewModel

    var body: some View {
        HStack(spacing: 16) {
            Button(action: captureViewModel.startLiveAnalysis) {
                Label("Lancer l'analyse", systemImage: "play.circle.fill")
                    .font(.headline)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(captureViewModel.isLiveAnalyzing ? Color.accentColor.opacity(0.15) : Color.accentColor)
                    .foregroundColor(captureViewModel.isLiveAnalyzing ? .accentColor : .white)
                    .clipShape(Capsule())
            }
            .disabled(captureViewModel.isLiveAnalyzing)

            if captureViewModel.isLiveAnalyzing {
                Button(role: .destructive, action: captureViewModel.stopLiveAnalysis) {
                    Label("Terminer", systemImage: "stop.circle")
                        .font(.headline)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color.red.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
    }
}

private struct BottomPanel: View {
    @EnvironmentObject private var captureViewModel: CaptureViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if captureViewModel.isLiveAnalyzing, let pose = captureViewModel.latestPose, !pose.jointAngles.isEmpty {
                LiveAnglesPanel(pose: pose)
            }

            CaptureControls()

            if let summary = captureViewModel.lastSessionSummary, !captureViewModel.isLiveAnalyzing {
                SessionSummaryCard(summary: summary)
            }

            if let message = captureViewModel.statusMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LiveAnglesPanel: View {
    let pose: PoseFrame

    private var sortedAngles: [(JointType, Double)] {
        pose.jointAngles.sorted { $0.key < $1.key }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Angles en direct")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                ForEach(sortedAngles, id: \.0) { joint, angle in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(joint.localizedName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(angle, specifier: "%.1f")°")
                            .font(.title3.weight(.bold))
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }
}

private struct SessionSummaryCard: View {
    let summary: SessionSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rapport d'analyse")
                .font(.headline)

            HStack {
                Label(summary.formattedDuration, systemImage: "clock")
                Spacer()
                Label("\(summary.frameCount) frames", systemImage: "video")
            }
            .font(.subheadline)

            if summary.hasJointData {
                Divider()
                ForEach(summary.jointSummaries) { jointSummary in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(jointSummary.joint.localizedName)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(jointSummary.movementCount) mouvements")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(jointSummary.averageDescription)
                            .font(.body)
                        Text(jointSummary.rangeDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(jointSummary.isoDescription)
                            .font(.caption2)
                            .foregroundColor(jointSummary.isoStatus.tintColor)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct PermissionOverlay: View {
    let status: AVAuthorizationStatus

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundColor(.white)
            Text(permissionMessage)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.horizontal)
        }
        .padding(32)
        .background(Color.black.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var permissionMessage: String {
        switch status {
        case .denied, .restricted:
            return "L'application nécessite l'accès à la caméra pour analyser les mouvements. Activez l'autorisation dans Réglages."
        case .notDetermined:
            return "Autorisez l'accès à la caméra pour démarrer l'analyse."
        default:
            return "Caméra non disponible"
        }
    }
}
