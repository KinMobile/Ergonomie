import SwiftUI

struct PoseOverlayView: View {
    let pose: PoseFrame?
    var contentInset: CGFloat = 12
    var jointColor: Color = .accentColor

    private var extrapolatedColor: Color {
        jointColor.opacity(0.4)
    }

    var body: some View {
        GeometryReader { geometry in
            let drawingWidth = max(geometry.size.width - contentInset * 2, 0)
            let drawingHeight = max(geometry.size.height - contentInset * 2, 0)

            ZStack {
                if let pose {
                    ForEach(pose.jointConnections, id: \.self) { connection in
                        if let start = pose.jointPositions[connection.0],
                           let end = pose.jointPositions[connection.1] {
                            let startPoint = CGPoint(
                                x: contentInset + start.x * drawingWidth,
                                y: contentInset + (1 - start.y) * drawingHeight
                            )
                            let endPoint = CGPoint(
                                x: contentInset + end.x * drawingWidth,
                                y: contentInset + (1 - end.y) * drawingHeight
                            )

                            let usesCache = pose.extrapolatedJoints.contains(connection.0) ||
                                pose.extrapolatedJoints.contains(connection.1)

                            Path { path in
                                path.move(to: startPoint)
                                path.addLine(to: endPoint)
                            }
                            .stroke(usesCache ? extrapolatedColor : jointColor, lineWidth: 2)
                        }
                    }

                    ForEach(pose.jointPositions.keys.sorted(), id: \.self) { joint in
                        if let normalized = pose.jointPositions[joint] {
                            let position = CGPoint(
                                x: contentInset + normalized.x * drawingWidth,
                                y: contentInset + (1 - normalized.y) * drawingHeight
                            )
                            let isExtrapolated = pose.extrapolatedJoints.contains(joint)

                            JointView(
                                joint: joint,
                                angle: pose.jointAngles[joint],
                                position: position,
                                isExtrapolated: isExtrapolated,
                                jointColor: jointColor,
                                extrapolatedColor: extrapolatedColor
                            )
                        }
                    }
                } else {
                    Text("Aucune pose détectée")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: pose?.id)
        }
    }
}

private struct JointView: View {
    let joint: JointType
    let angle: Double?
    let position: CGPoint
    let isExtrapolated: Bool
    let jointColor: Color
    let extrapolatedColor: Color

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(isExtrapolated ? extrapolatedColor : jointColor)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )

            VStack(spacing: 2) {
                Text(joint.localizedName)
                    .font(.caption2.weight(.semibold))
                if let angle {
                    Text("\(angle, specifier: "%.0f")°")
                        .font(.caption2)
                } else if isExtrapolated {
                    Text("Stabilisé")
                        .font(.caption2)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(.thinMaterial)
            .clipShape(Capsule())
            .foregroundColor(.white)
            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
        }
        .position(position)
    }
}
