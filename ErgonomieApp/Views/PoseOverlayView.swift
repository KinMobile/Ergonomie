import SwiftUI

struct PoseOverlayView: View {
    let pose: PoseFrame?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let pose {
                    ForEach(pose.jointPositions.keys.sorted(), id: \.self) { joint in
                        if let normalized = pose.jointPositions[joint] {
                            let position = CGPoint(x: normalized.x * geometry.size.width,
                                                   y: (1 - normalized.y) * geometry.size.height)
                            JointView(name: joint.rawValue, position: position)
                        }
                    }

                    ForEach(pose.jointConnections, id: \.self) { connection in
                        if let start = pose.jointPositions[connection.0],
                           let end = pose.jointPositions[connection.1] {
                            let startPoint = CGPoint(x: start.x * geometry.size.width,
                                                     y: (1 - start.y) * geometry.size.height)
                            let endPoint = CGPoint(x: end.x * geometry.size.width,
                                                   y: (1 - end.y) * geometry.size.height)
                            Path { path in
                                path.move(to: startPoint)
                                path.addLine(to: endPoint)
                            }
                            .stroke(Color.orange, lineWidth: 2)
                        }
                    }
                } else {
                    Text("Aucune pose détectée")
                        .foregroundColor(.secondary)
                }
            }
            .animation(.easeInOut, value: pose?.id)
        }
    }
}

private struct JointView: View {
    let name: String
    let position: CGPoint

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 10, height: 10)
            Text(name)
                .font(.caption2)
                .foregroundColor(.white)
                .padding(4)
                .background(Color.black.opacity(0.6))
                .clipShape(Capsule())
        }
        .position(position)
    }
}
