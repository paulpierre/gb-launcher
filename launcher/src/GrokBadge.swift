// grok-badge: a click-through colored badge pinned to one process's main window.
//
// Privacy notes: this only reads window owner PID, number, layer, alpha and
// bounds from CGWindowListCopyWindowInfo. It never reads window titles, never
// uses Accessibility APIs and never captures screen contents, so it does not
// need (or trigger) Screen Recording / Accessibility / Automation permissions.

import AppKit
import CoreGraphics

// MARK: - Arguments

struct Options {
    var pid: pid_t = 0
    var label = ""
    var number = ""
    var color = NSColor.systemPurple
    var iconPath: String?
    var border = false
    var activate = false
    var logPath: String?
    var interval: TimeInterval = 0.1
    var renderIcon: String?
    var renderSize = 1024
    var always = false
    var debug = false
}

func usage() -> Never {
    let text = """
    usage: grok-badge --pid <pid> [--label <text>] [--number <n>] [--color <name|#RRGGBB>]
                      [--icon <image path>] [--border] [--log <file>] [--interval <seconds>]
                      [--always] [--debug]
      --always  show the badge whenever the window is on screen, not only while
                that instance is the frontmost app
      --debug   log placement details (frame, screen, visibility, frontmost pid)
           grok-badge --pid <pid> --activate
           grok-badge --render-icon <out.png> [--size 1024] [--number <n>] [--color <c>] [--icon <image>]
    """
    FileHandle.standardError.write((text + "\n").data(using: .utf8)!)
    exit(64)
}

let presetColors: [String: String] = [
    "purple": "#8B5CF6", "blue": "#3B82F6", "green": "#22C55E", "orange": "#F97316",
    "red": "#EF4444", "pink": "#EC4899", "teal": "#14B8A6", "yellow": "#EAB308",
    "gray": "#6B7280", "grey": "#6B7280", "indigo": "#6366F1", "cyan": "#06B6D4",
]

func parseColor(_ raw: String) -> NSColor? {
    var s = raw.trimmingCharacters(in: .whitespaces).lowercased()
    if let preset = presetColors[s] { s = preset.lowercased() }
    if s.hasPrefix("#") { s.removeFirst() }
    guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
    return NSColor(srgbRed: CGFloat((v >> 16) & 0xFF) / 255,
                   green: CGFloat((v >> 8) & 0xFF) / 255,
                   blue: CGFloat(v & 0xFF) / 255, alpha: 1)
}

func parseArgs() -> Options {
    var o = Options()
    var args = Array(CommandLine.arguments.dropFirst())
    func next(_ flag: String) -> String {
        guard !args.isEmpty else { FileHandle.standardError.write("missing value for \(flag)\n".data(using: .utf8)!); usage() }
        return args.removeFirst()
    }
    while !args.isEmpty {
        let a = args.removeFirst()
        switch a {
        case "--pid": o.pid = pid_t(next(a)) ?? 0
        case "--label": o.label = next(a)
        case "--number": o.number = next(a)
        case "--color":
            let v = next(a)
            guard let c = parseColor(v) else { FileHandle.standardError.write("bad color: \(v)\n".data(using: .utf8)!); exit(64) }
            o.color = c
        case "--icon": o.iconPath = next(a)
        case "--border": o.border = true
        case "--activate": o.activate = true
        case "--log": o.logPath = next(a)
        case "--interval": o.interval = max(0.03, TimeInterval(next(a)) ?? 0.1)
        case "--render-icon": o.renderIcon = next(a)
        case "--size": o.renderSize = max(16, Int(next(a)) ?? 1024)
        case "--always": o.always = true
        case "--debug": o.debug = true
        case "-h", "--help": usage()
        default: FileHandle.standardError.write("unknown argument: \(a)\n".data(using: .utf8)!); usage()
        }
    }
    if o.pid <= 0 && o.renderIcon == nil { usage() }
    return o
}

let opts = parseArgs()

func processAlive(_ pid: pid_t) -> Bool {
    kill(pid, 0) == 0 || errno == EPERM
}

// MARK: - Logging

final class Logger {
    private let handle: FileHandle?
    init(path: String?) {
        guard let path else { handle = nil; return }
        if !FileManager.default.fileExists(atPath: path) {
            FileManager.default.createFile(atPath: path, contents: nil)
        }
        handle = FileHandle(forWritingAtPath: path)
        handle?.seekToEndOfFile()
    }
    func log(_ msg: String) {
        guard let handle else { return }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        handle.write("\(f.string(from: Date())) \(msg)\n".data(using: .utf8)!)
    }
}

let logger = Logger(path: opts.logPath)

// MARK: - Render-icon mode (offscreen PNG for shortcut .app icons)

if let out = opts.renderIcon {
    let size = CGFloat(opts.renderSize)
    guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: opts.renderSize, pixelsHigh: opts.renderSize,
                                     bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                     colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
          let ctx = NSGraphicsContext(bitmapImageRep: rep) else { exit(1) }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx
    let rect = NSRect(x: 0, y: 0, width: size, height: size).insetBy(dx: size * 0.06, dy: size * 0.06)
    let shape = NSBezierPath(roundedRect: rect, xRadius: size * 0.22, yRadius: size * 0.22)
    if let p = opts.iconPath, let img = NSImage(contentsOfFile: (p as NSString).expandingTildeInPath) {
        shape.addClip()
        img.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
    } else {
        opts.color.setFill()
        shape.fill()
        let text = (opts.number.isEmpty ? "•" : opts.number) as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: size * 0.5, weight: .heavy), .foregroundColor: NSColor.white,
        ]
        let sz = text.size(withAttributes: attrs)
        text.draw(at: NSPoint(x: rect.midX - sz.width / 2, y: rect.midY - sz.height / 2), withAttributes: attrs)
    }
    NSGraphicsContext.restoreGraphicsState()
    guard let png = rep.representation(using: .png, properties: [:]) else { exit(1) }
    do { try png.write(to: URL(fileURLWithPath: out)) } catch { exit(1) }
    exit(0)
}

// MARK: - Activate mode

if opts.activate {
    guard let app = NSRunningApplication(processIdentifier: opts.pid) else {
        FileHandle.standardError.write("no running app with pid \(opts.pid)\n".data(using: .utf8)!)
        exit(1)
    }
    if app.isHidden { app.unhide() }
    let ok = app.activate(options: [.activateAllWindows])
    logger.log("activate pid=\(opts.pid) ok=\(ok)")
    exit(ok ? 0 : 1)
}

// MARK: - Window lookup (owner PID + bounds only)

struct TargetWindow: Equatable {
    var number: Int
    var bounds: CGRect // CoreGraphics global coords, top-left origin, points
}

func findMainWindow(pid: pid_t) -> TargetWindow? {
    let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
    guard let list = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return nil }
    var best: TargetWindow?
    for w in list {
        guard let owner = w[kCGWindowOwnerPID as String] as? Int32, owner == pid,
              let layer = w[kCGWindowLayer as String] as? Int, layer == 0,
              let number = w[kCGWindowNumber as String] as? Int,
              let bd = w[kCGWindowBounds as String] as? NSDictionary,
              let rect = CGRect(dictionaryRepresentation: bd as CFDictionary)
        else { continue }
        let alpha = (w[kCGWindowAlpha as String] as? Double) ?? 1
        if alpha <= 0.01 || rect.width < 200 || rect.height < 150 { continue }
        if best == nil || rect.width * rect.height > best!.bounds.width * best!.bounds.height {
            best = TargetWindow(number: number, bounds: rect)
        }
    }
    return best
}

/// Convert CG (top-left origin of the primary display) to AppKit (bottom-left origin).
func toAppKit(_ r: CGRect) -> NSRect {
    let primaryHeight = NSScreen.screens.first?.frame.height ?? r.maxY
    return NSRect(x: r.minX, y: primaryHeight - r.maxY, width: r.width, height: r.height)
}

// MARK: - Views

final class BadgeView: NSView {
    let label: String
    let number: String
    let color: NSColor
    let icon: NSImage?
    static let height: CGFloat = 32
    static let iconSize: CGFloat = 24

    init(label: String, number: String, color: NSColor, icon: NSImage?) {
        self.label = label; self.number = number; self.color = color; self.icon = icon
        super.init(frame: .zero)
        setFrameSize(NSSize(width: intrinsicWidth(), height: Self.height))
    }
    required init?(coder: NSCoder) { fatalError() }

    private var textAttrs: [NSAttributedString.Key: Any] {
        [.font: NSFont.systemFont(ofSize: 13, weight: .semibold), .foregroundColor: NSColor.white]
    }
    private var numberAttrs: [NSAttributedString.Key: Any] {
        [.font: NSFont.systemFont(ofSize: 13, weight: .heavy), .foregroundColor: color]
    }

    func intrinsicWidth() -> CGFloat {
        var w: CGFloat = 4 // left pad
        w += Self.iconSize + 6 // icon or number disc
        if !label.isEmpty { w += (label as NSString).size(withAttributes: textAttrs).width + 4 }
        return ceil(w + 8) // right pad
    }

    override func draw(_ dirtyRect: NSRect) {
        let pill = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: Self.height / 2, yRadius: Self.height / 2)
        color.withAlphaComponent(0.92).setFill()
        pill.fill()
        NSColor.white.withAlphaComponent(0.35).setStroke()
        pill.lineWidth = 1
        pill.stroke()

        let disc = NSRect(x: 4, y: (Self.height - Self.iconSize) / 2, width: Self.iconSize, height: Self.iconSize)
        if let icon {
            NSGraphicsContext.saveGraphicsState()
            NSBezierPath(roundedRect: disc, xRadius: 6, yRadius: 6).addClip()
            icon.draw(in: disc, from: .zero, operation: .sourceOver, fraction: 1)
            NSGraphicsContext.restoreGraphicsState()
        } else {
            NSColor.white.setFill()
            NSBezierPath(ovalIn: disc).fill()
            let n = (number.isEmpty ? "•" : number) as NSString
            let sz = n.size(withAttributes: numberAttrs)
            n.draw(at: NSPoint(x: disc.midX - sz.width / 2, y: disc.midY - sz.height / 2), withAttributes: numberAttrs)
        }
        if !label.isEmpty {
            let l = label as NSString
            let sz = l.size(withAttributes: textAttrs)
            l.draw(at: NSPoint(x: disc.maxX + 6, y: (Self.height - sz.height) / 2), withAttributes: textAttrs)
        }
    }
}

final class BorderView: NSView {
    let color: NSColor
    init(color: NSColor) { self.color = color; super.init(frame: .zero) }
    required init?(coder: NSCoder) { fatalError() }
    override func draw(_ dirtyRect: NSRect) {
        let p = NSBezierPath(roundedRect: bounds.insetBy(dx: 1.5, dy: 1.5), xRadius: 10, yRadius: 10)
        p.lineWidth = 3
        color.withAlphaComponent(0.9).setStroke()
        p.stroke()
    }
}

func makePanel(content: NSView) -> NSPanel {
    let panel = NSPanel(contentRect: NSRect(origin: .zero, size: content.frame.size),
                        styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = false
    panel.ignoresMouseEvents = true
    panel.isFloatingPanel = true
    panel.level = .floating
    panel.hidesOnDeactivate = false
    panel.isReleasedWhenClosed = false
    // Visible on every Space, but we hide it whenever the target window is not
    // on screen (other Space, minimized, hidden), so it only shows with it.
    panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
    panel.contentView = content
    return panel
}

// MARK: - Controller

final class Controller {
    let badge: NSPanel
    let badgeView: BadgeView
    let border: NSPanel?
    var last: TargetWindow?
    var visible = false
    var timer: Timer?
    var lastDebug = ""
    var lastDebugAt = Date.distantPast

    init() {
        var icon: NSImage?
        if let p = opts.iconPath, !p.isEmpty {
            icon = NSImage(contentsOfFile: (p as NSString).expandingTildeInPath)
            if icon == nil { logger.log("icon not loadable, falling back to pill: \(p)") }
        }
        badgeView = BadgeView(label: opts.label, number: opts.number, color: opts.color, icon: icon)
        badge = makePanel(content: badgeView)
        border = opts.border ? makePanel(content: BorderView(color: opts.color)) : nil
    }

    func start() {
        logger.log("start pid=\(opts.pid) label=\(opts.label) border=\(opts.border) always=\(opts.always) debug=\(opts.debug)")
        tick()
        timer = Timer.scheduledTimer(withTimeInterval: opts.interval, repeats: true) { [weak self] _ in self?.tick() }
    }

    func hide(_ why: String) {
        guard visible else { return }
        badge.orderOut(nil); border?.orderOut(nil)
        visible = false
        logger.log("hidden (\(why))")
    }

    /// Debug line, logged when it changes (or every 5 s while unchanged).
    func debug(_ line: String) {
        guard opts.debug else { return }
        if line != lastDebug || Date().timeIntervalSince(lastDebugAt) > 5 {
            logger.log("debug \(line)")
            lastDebug = line
            lastDebugAt = Date()
        }
    }

    func tick() {
        guard processAlive(opts.pid) else {
            logger.log("target pid \(opts.pid) exited; badge exiting")
            exit(0)
        }
        let front = NSWorkspace.shared.frontmostApplication?.processIdentifier ?? -1
        let isFront = front == opts.pid
        guard let w = findMainWindow(pid: opts.pid) else {
            debug("no on-screen window for pid=\(opts.pid) frontmost=\(front)")
            last = nil; hide("window not on screen"); return
        }
        if !isFront && !opts.always {
            debug("window=\(w.number) on screen but frontmost=\(front) != \(opts.pid)")
            hide("instance not frontmost"); return
        }
        let frame = toAppKit(w.bounds)
        let size = badgeView.frame.size
        let origin = NSPoint(x: frame.maxX - size.width - 12, y: frame.maxY - size.height - 8)
        let target = NSRect(origin: origin, size: size)
        if w != last || !visible {
            badge.setFrame(target, display: true)
            border?.setFrame(frame, display: true)
            if w != last { logger.log("track window=\(w.number) bounds=\(Int(w.bounds.minX)),\(Int(w.bounds.minY)) \(Int(w.bounds.width))x\(Int(w.bounds.height))") }
            last = w
        }
        if isFront {
            // Our instance is frontmost: float above it (and only it is in front).
            badge.level = .floating; border?.level = .floating
            border?.orderFrontRegardless()
            badge.orderFrontRegardless()
        } else {
            // --always while another app is in front: sit just above the target
            // window at normal level so we don't cover other apps.
            badge.level = .normal; border?.level = .normal
            border?.order(.above, relativeTo: w.number)
            badge.order(.above, relativeTo: w.number)
        }
        if !visible { visible = true; logger.log("shown") }
        let onScreen = NSScreen.screens.contains { $0.frame.intersects(badge.frame) }
        debug("window=\(w.number) cg=\(Int(w.bounds.minX)),\(Int(w.bounds.minY)),\(Int(w.bounds.width))x\(Int(w.bounds.height)) cocoa=\(Int(badge.frame.minX)),\(Int(badge.frame.minY)),\(Int(badge.frame.width))x\(Int(badge.frame.height)) onScreen=\(onScreen) isVisible=\(badge.isVisible) level=\(badge.level.rawValue) frontmost=\(front) screens=\(NSScreen.screens.map { "\(Int($0.frame.minX)),\(Int($0.frame.minY)),\(Int($0.frame.width))x\(Int($0.frame.height))" }.joined(separator: ";"))")
    }
}

// MARK: - Main

let app = NSApplication.shared
app.setActivationPolicy(.accessory) // no Dock icon, no Cmd+Tab entry
signal(SIGTERM) { _ in exit(0) }
signal(SIGINT) { _ in exit(0) }
let controller = Controller()
controller.start()
app.run()
