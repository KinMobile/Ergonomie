import SwiftUI

struct RiskMapView: View {
    let summary: SessionSummary

    private var jointSummaries: [JointType: SessionSummary.JointSummary] {
        Dictionary(uniqueKeysWithValues: summary.jointSummaries.map { ($0.joint, $0) })
    }

    private var highlightedJoints: [SessionSummary.JointSummary] {
        Array(
            summary.jointSummaries
                .filter { $0.isoStatus != .compliant && $0.isoStatus != .unknown }
                .sorted { $0.isoStatus.severityRank > $1.isoStatus.severityRank }
                .prefix(3)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GeometryReader { geometry in
                let size = geometry.size
                ZStack {
                    ForEach(BodySegment.allCases, id: \.self) { segment in
                        let descriptor = segment.descriptor(in: size)
                        let status = status(for: segment)
                        let color = color(for: status)

                        segment.shape
                            .fill(color)
                            .frame(width: descriptor.size.width, height: descriptor.size.height)
                            .position(descriptor.center)
                            .overlay(
                                segment.label
                                    .font(.caption2.weight(.semibold))
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(4)
                                    .background(Color.black.opacity(0.35))
                                    .clipShape(Capsule())
                                    .padding(.top, segment == .head ? 8 : 0),
                                alignment: .top
                            )
                    }
                }
            }
            .aspectRatio(3 / 4, contentMode: .fit)
            .frame(maxWidth: .infinity)

            if !highlightedJoints.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Segments à surveiller")
                        .font(.subheadline.weight(.semibold))
                    ForEach(highlightedJoints, id: \.joint) { summary in
                        HStack {
                            Label(summary.joint.localizedName, systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(color(for: summary.isoStatus))
                            Spacer()
                            Text(summary.isoDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.tertiarySystemBackground))
                        )
                    }
                }
            }

            RiskLegend()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
    }

    private func status(for segment: BodySegment) -> SessionSummary.JointSummary.IsoStatus {
        let joints = segment.joints
        let statuses = joints.compactMap { jointSummaries[$0]?.isoStatus }
        guard let maxStatus = statuses.max(by: { $0.severityRank < $1.severityRank }) else {
            return .unknown
        }
        return maxStatus
    }

    private func color(for status: SessionSummary.JointSummary.IsoStatus) -> Color {
        switch status {
        case .critical:
            return Color.red.opacity(0.75)
        case .attention:
            return Color.orange.opacity(0.7)
        case .compliant:
            return Color.green.opacity(0.45)
        case .unknown:
            return Color.gray.opacity(0.3)
        }
    }
}

private struct RiskLegend: View {
    var body: some View {
        ViewThatFits {
            HStack(spacing: 12) {
                LegendItem(color: .red.opacity(0.75), title: "Critique", subtitle: "Action immédiate")
                LegendItem(color: .orange.opacity(0.7), title: "Surveillance", subtitle: "Ajustements rapides")
                LegendItem(color: .green.opacity(0.45), title: "Conforme", subtitle: "Dans la norme ISO")
            }
            VStack(alignment: .leading, spacing: 8) {
                LegendItem(color: .red.opacity(0.75), title: "Critique", subtitle: "Action immédiate")
                LegendItem(color: .orange.opacity(0.7), title: "Surveillance", subtitle: "Ajustements rapides")
                LegendItem(color: .green.opacity(0.45), title: "Conforme", subtitle: "Dans la norme ISO")
            }
        }
    }
}

private struct LegendItem: View {
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 16, height: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

private enum BodySegment: CaseIterable {
    case head
    case neck
    case torso
    case leftArm
    case rightArm
    case leftLeg
    case rightLeg

    var joints: [JointType] {
        switch self {
        case .head:
            return [.head]
        case .neck:
            return [.neck]
        case .torso:
            return [.torso, .leftHip, .rightHip]
        case .leftArm:
            return [.leftShoulder, .leftElbow, .leftWrist]
        case .rightArm:
            return [.rightShoulder, .rightElbow, .rightWrist]
        case .leftLeg:
            return [.leftHip, .leftKnee, .leftAnkle]
        case .rightLeg:
            return [.rightHip, .rightKnee, .rightAnkle]
        }
    }

    var label: Text {
        switch self {
        case .head:
            return Text("Tête")
        case .neck:
            return Text("Cou")
        case .torso:
            return Text("Torse")
        case .leftArm:
            return Text("Bras G")
        case .rightArm:
            return Text("Bras D")
        case .leftLeg:
            return Text("Jambe G")
        case .rightLeg:
            return Text("Jambe D")
        }
    }

    var shape: AnyShape {
        switch self {
        case .head:
            return AnyShape(Circle())
        case .neck:
            return AnyShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        case .torso:
            return AnyShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        case .leftArm, .rightArm:
            return AnyShape(Capsule())
        case .leftLeg, .rightLeg:
            return AnyShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    func descriptor(in size: CGSize) -> (size: CGSize, center: CGPoint) {
        let width = size.width
        let height = size.height

        switch self {
        case .head:
            return (CGSize(width: width * 0.22, height: height * 0.18), CGPoint(x: width / 2, y: height * 0.18))
        case .neck:
            return (CGSize(width: width * 0.12, height: height * 0.08), CGPoint(x: width / 2, y: height * 0.3))
        case .torso:
            return (CGSize(width: width * 0.32, height: height * 0.34), CGPoint(x: width / 2, y: height * 0.52))
        case .leftArm:
            return (CGSize(width: width * 0.18, height: height * 0.32), CGPoint(x: width * 0.23, y: height * 0.48))
        case .rightArm:
            return (CGSize(width: width * 0.18, height: height * 0.32), CGPoint(x: width * 0.77, y: height * 0.48))
        case .leftLeg:
            return (CGSize(width: width * 0.2, height: height * 0.36), CGPoint(x: width * 0.35, y: height * 0.82))
        case .rightLeg:
            return (CGSize(width: width * 0.2, height: height * 0.36), CGPoint(x: width * 0.65, y: height * 0.82))
        }
    }
}

private struct AnyShape: InsettableShape {
    private let _path: (CGRect) -> Path
    private let _inset: (CGFloat) -> AnyShape

    init<S: InsettableShape>(_ shape: S) {
        _path = { rect in shape.path(in: rect) }
        _inset = { amount in AnyShape(shape.inset(by: amount)) }
    }

    func path(in rect: CGRect) -> Path {
        _path(rect)
    }

    func inset(by amount: CGFloat) -> AnyShape {
        _inset(amount)
    }
}
