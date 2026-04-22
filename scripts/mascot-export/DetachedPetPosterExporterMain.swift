import AppKit
import Foundation
import SwiftUI

@MainActor
@main
struct DetachedPetPosterExporterMain {
    static func main() throws {
        let options = try PosterOptions(arguments: Array(CommandLine.arguments.dropFirst()))
        try options.prepareOutputDirectory()

        let outputURL = options.outputDirectory.appendingPathComponent(options.outputName)
        let posterView = DetachedPetPosterView(options: options)
            .frame(width: options.canvasSize.width, height: options.canvasSize.height)

        let renderer = ImageRenderer(content: posterView)
        renderer.scale = 1
        renderer.isOpaque = true
        renderer.proposedSize = .init(width: options.canvasSize.width, height: options.canvasSize.height)

        guard let cgImage = renderer.cgImage else {
            throw PosterExportError.failedToRender(outputURL.path)
        }

        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw PosterExportError.failedToEncode(outputURL.path)
        }

        try data.write(to: outputURL, options: .atomic)
        print("wrote \(outputURL.path)")
    }
}

private struct PosterOptions {
    let outputDirectory: URL
    let outputName: String
    let canvasSize: CGSize
    let iconURL: URL
    let notchPreviewURL: URL

    init(arguments: [String]) throws {
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        var outputDirectory = cwd.appendingPathComponent("docs/images", isDirectory: true)
        var outputName = "ping-island-undocked-pet-feature.png"
        var width = 2800
        var height = 1800
        var iconURL = cwd.appendingPathComponent("PingIsland/Assets.xcassets/AppIcon.appiconset/icon_1024x1024.png")
        var notchPreviewURL = cwd.appendingPathComponent("docs/images/notch-panel.png")

        var index = 0
        while index < arguments.count {
            let argument = arguments[index]
            switch argument {
            case "--output-dir":
                index += 1
                outputDirectory = URL(
                    fileURLWithPath: try Self.value(after: argument, at: index, in: arguments),
                    isDirectory: true
                )
            case "--output-name":
                index += 1
                outputName = try Self.value(after: argument, at: index, in: arguments)
            case "--width":
                index += 1
                width = try Self.intValue(after: argument, at: index, in: arguments)
            case "--height":
                index += 1
                height = try Self.intValue(after: argument, at: index, in: arguments)
            case "--icon":
                index += 1
                iconURL = URL(fileURLWithPath: try Self.value(after: argument, at: index, in: arguments))
            case "--notch-preview":
                index += 1
                notchPreviewURL = URL(fileURLWithPath: try Self.value(after: argument, at: index, in: arguments))
            case "--help", "-h":
                throw PosterExportError.helpText
            default:
                throw PosterExportError.unknownArgument(argument)
            }
            index += 1
        }

        guard width > 0, height > 0 else {
            throw PosterExportError.invalidValue("canvas", "\(width)x\(height)")
        }

        self.outputDirectory = outputDirectory
        self.outputName = outputName
        self.canvasSize = CGSize(width: width, height: height)
        self.iconURL = iconURL
        self.notchPreviewURL = notchPreviewURL
    }

    func prepareOutputDirectory() throws {
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
    }

    private static func value(after flag: String, at index: Int, in arguments: [String]) throws -> String {
        guard arguments.indices.contains(index) else {
            throw PosterExportError.missingValue(flag)
        }
        return arguments[index]
    }

    private static func intValue(after flag: String, at index: Int, in arguments: [String]) throws -> Int {
        let raw = try value(after: flag, at: index, in: arguments)
        guard let value = Int(raw) else {
            throw PosterExportError.invalidValue(flag, raw)
        }
        return value
    }
}

private enum PosterExportError: LocalizedError {
    case missingValue(String)
    case invalidValue(String, String)
    case unknownArgument(String)
    case failedToRender(String)
    case failedToEncode(String)
    case helpText

    var errorDescription: String? {
        switch self {
        case .missingValue(let flag):
            return "Missing value for \(flag)"
        case .invalidValue(let flag, let value):
            return "Invalid value for \(flag): \(value)"
        case .unknownArgument(let argument):
            return "Unknown argument: \(argument)"
        case .failedToRender(let path):
            return "Failed to render poster for \(path)"
        case .failedToEncode(let path):
            return "Failed to encode PNG for \(path)"
        case .helpText:
            return """
            Usage: render-detached-pet-poster.sh [options]

              --output-dir <path>    Output directory (default: docs/images)
              --output-name <name>   Output filename (default: ping-island-undocked-pet-feature.png)
              --width <pixels>       Canvas width (default: 2800)
              --height <pixels>      Canvas height (default: 1800)
              --icon <path>          App icon path
              --notch-preview <path> Notch preview image path
            """
        }
    }
}

private struct DetachedPetPosterView: View {
    let options: PosterOptions

    var body: some View {
        ZStack {
            Color.black

            Circle()
                .fill(Color(red: 0.98, green: 0.64, blue: 0.26).opacity(0.24))
                .frame(width: 780, height: 780)
                .blur(radius: 90)
                .offset(x: -760, y: -520)

            Circle()
                .fill(Color(red: 0.22, green: 0.74, blue: 0.64).opacity(0.20))
                .frame(width: 860, height: 860)
                .blur(radius: 100)
                .offset(x: 780, y: 460)

            VStack(spacing: 38) {
                header

                demoCard
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 120)
            .padding(.vertical, 92)
        }
    }

    private var header: some View {
        HStack(spacing: 30) {
            appIcon

            VStack(alignment: .leading, spacing: 12) {
                Text("PING ISLAND 0.4.0")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(Color.white.opacity(0.52))

                Text("Pet Undocking")
                    .font(.system(size: 96, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white)

                Text("A settings-style preview for the floating pet workflow.")
                    .font(.system(size: 26, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.64))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    private var appIcon: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.38),
                            Color.white.opacity(0.10),
                            .clear,
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 160
                    )
                )
                .frame(width: 220, height: 220)

            RoundedRectangle(cornerRadius: 78, style: .continuous)
                .fill(.white.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 78, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 1.5)
                )
                .frame(width: 170, height: 170)

            if let icon = posterImage(from: options.iconURL) {
                icon
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 134, height: 134)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            }
        }
        .frame(width: 220, height: 220)
    }

    private var demoCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 46, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.27, green: 0.17, blue: 0.08),
                            Color(red: 0.10, green: 0.08, blue: 0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 46, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )

            SettingsStyleFloatingPreview(notchPreviewURL: options.notchPreviewURL)
                .padding(48)
        }
        .frame(height: 1120)
    }
}

private struct SettingsStyleFloatingPreview: View {
    let notchPreviewURL: URL

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.035))

            if let preview = posterImage(from: notchPreviewURL) {
                preview
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 880, height: 185)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                    .offset(x: -180, y: -280)
            }

            VStack {
                HStack {
                    Text("Bottom-right floating")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.46))
                    Spacer()
                }
                Spacer()
            }
            .padding(30)

            Path { path in
                path.move(to: CGPoint(x: 500, y: 260))
                path.addQuadCurve(
                    to: CGPoint(x: 760, y: 520),
                    control: CGPoint(x: 625, y: 410)
                )
            }
            .stroke(
                Color.white.opacity(0.85),
                style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [8, 10])
            )

            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.white.opacity(0.16))
                        .frame(width: 42, height: 4)

                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 18, height: 4)
                }

                HStack(alignment: .bottom, spacing: 4) {
                    MascotView(kind: .claude, status: .dragging, size: 96, animationTime: 0.35)

                    Text("2")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 1.0, green: 0.55, blue: 0.26))
                        .offset(y: -6)
                }
            }
            .offset(x: 330, y: 315)

            SettingsStyleFloatingBubble()
                .offset(x: 130, y: 20)
        }
    }
}

private func posterImage(from url: URL) -> Image? {
    guard let image = NSImage(contentsOf: url) else { return nil }
    return Image(nsImage: image)
}

private struct SettingsStyleFloatingBubble: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color(red: 1.0, green: 0.67, blue: 0.25))
                    .frame(width: 10, height: 10)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.white.opacity(0.92))
                    .frame(width: 180, height: 16)
            }

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.white.opacity(0.22))
                .frame(height: 12)

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.white.opacity(0.16))
                .frame(width: 230, height: 12)

            HStack(spacing: 10) {
                bubbleTag(width: 72)
                bubbleTag(width: 58)
                bubbleTag(width: 92)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .frame(width: 420, alignment: .leading)
        .background(
            FloatingDemoBubbleShape()
                .fill(Color.black.opacity(0.88))
                .overlay(
                    FloatingDemoBubbleShape()
                        .stroke(Color.white.opacity(0.08), lineWidth: 1.5)
                )
        )
        .shadow(color: .black.opacity(0.20), radius: 24, x: 0, y: 14)
    }

    private func bubbleTag(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 999, style: .continuous)
            .fill(Color.white.opacity(0.08))
            .frame(width: width, height: 32)
            .background(
                Capsule(style: .continuous)
                    .fill(.clear)
            )
    }
}

private struct FloatingDemoBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path(roundedRect: rect, cornerRadius: 30)
        path.move(to: CGPoint(x: rect.minX + 120, y: rect.maxY - 18))
        path.addLine(to: CGPoint(x: rect.minX + 145, y: rect.maxY + 24))
        path.addLine(to: CGPoint(x: rect.minX + 170, y: rect.maxY - 18))
        path.closeSubpath()
        return path
    }
}
