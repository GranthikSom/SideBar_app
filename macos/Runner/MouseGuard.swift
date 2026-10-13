import Cocoa
import CoreGraphics
import Carbon

/// MouseGuard enforces a system-wide boundary inset on configured screen edges.
/// Toggled globally via Control + Option + G.
public final class MouseGuard {
    public static let shared = MouseGuard()

    // MARK: - Configuration
    // ponytail: Edge flags and inset are simple native properties without a settings UI or JSON config.
    // Upgrade path: expose via Flutter MethodChannel or persist to UserDefaults if runtime user preferences are needed.
    public var inset: CGFloat = 1.0
    public var guardTop: Bool = true
    public var guardBottom: Bool = true
    public var guardLeft: Bool = true
    public var guardRight: Bool = true

    /// If false, borders between adjacent displays are not guarded, allowing mouse passage between monitors.
    /// If true, boundaries are guarded on each display independently.
    public var guardInterDisplayBorders: Bool = false

    // MARK: - State
    public private(set) var isEnabled: Bool = false
    private var machPort: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isWarping: Bool = false

    // Carbon hotkey (Control + Option + G)
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let hotKeySignature: OSType = 0x4D475544 // 'MGUD'
    private let hotKeyId: UInt32 = 1

    // Display bounds cache in Core Graphics coordinates
    private var cachedDisplays: [CGRect] = []

    private init() {
        refreshDisplays()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    deinit {
        stop()
        unregisterHotKey()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Lifecycle
    public func start() {
        registerHotKey()
        enable()
    }

    public func stop() {
        disable()
        unregisterHotKey()
    }

    public func toggle() {
        if isEnabled {
            disable()
        } else {
            enable()
        }
    }

    public func enable() {
        guard !isEnabled else { return }

        // Check Accessibility permissions
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let isTrusted = AXIsProcessTrustedWithOptions(options)
        guard isTrusted else {
            NSLog("[MouseGuard] Accessibility permission required. Please enable in System Settings -> Privacy & Security -> Accessibility.")
            return
        }

        refreshDisplays()

        if machPort == nil {
            let mask: CGEventMask = (1 << CGEventType.mouseMoved.rawValue)
                | (1 << CGEventType.leftMouseDragged.rawValue)
                | (1 << CGEventType.rightMouseDragged.rawValue)
                | (1 << CGEventType.otherMouseDragged.rawValue)

            let callback: CGEventTapCallBack = { proxy, type, event, refcon in
                guard let refcon = refcon else {
                    return Unmanaged.passUnretained(event)
                }
                let guardInstance = Unmanaged<MouseGuard>.fromOpaque(refcon).takeUnretainedValue()
                return guardInstance.handleEvent(proxy: proxy, type: type, event: event)
            }

            guard let port = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: mask,
                callback: callback,
                userInfo: Unmanaged.passUnretained(self).toOpaque()
            ) else {
                NSLog("[MouseGuard] Failed to create CGEventTap. Ensure Accessibility permissions are granted and app-sandbox is disabled.")
                return
            }

            machPort = port
            let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
            runLoopSource = source
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }

        if let port = machPort {
            CGEvent.tapEnable(tap: port, enable: true)
        }
        isEnabled = true
        NSLog("[MouseGuard] Enabled.")
    }

    public func disable() {
        guard isEnabled else { return }
        if let port = machPort {
            CGEvent.tapEnable(tap: port, enable: false)
        }
        isEnabled = false
        NSLog("[MouseGuard] Disabled. Normal mouse movement restored.")
    }

    // MARK: - Event Handling
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let port = machPort {
                CGEvent.tapEnable(tap: port, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard isEnabled, !isWarping else {
            return Unmanaged.passUnretained(event)
        }

        let originalLocation = event.location
        let clampedLocation = clamp(point: originalLocation)

        if clampedLocation.x != originalLocation.x || clampedLocation.y != originalLocation.y {
            isWarping = true
            CGWarpMouseCursorPosition(clampedLocation)
            event.location = clampedLocation
            isWarping = false
        }

        return Unmanaged.passUnretained(event)
    }

    // MARK: - Display & Coordinate Clamping
    @objc private func screensDidChange() {
        refreshDisplays()
    }

    private func refreshDisplays() {
        var count: UInt32 = 0
        CGGetActiveDisplayList(0, nil, &count)
        guard count > 0 else {
            cachedDisplays = [NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)]
            return
        }
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: Int(count))
        CGGetActiveDisplayList(count, &displayIDs, &count)
        cachedDisplays = displayIDs.map { CGDisplayBounds($0) }
    }

    private func findDisplay(for point: CGPoint, in displays: [CGRect]) -> CGRect {
        for rect in displays {
            if rect.contains(point) {
                return rect
            }
        }
        // Fallback for overshoot outside all display rects: pick closest display
        // ponytail: Euclidean distance fallback for rapid cursor velocity overshoots.
        // Upgrade path: incorporate previous frame's display if high-DPI sub-pixel jump tracking is needed.
        return displays.min(by: { rect1, rect2 in
            let d1 = distance(from: point, to: rect1)
            let d2 = distance(from: point, to: rect2)
            return d1 < d2
        }) ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
    }

    private func distance(from point: CGPoint, to rect: CGRect) -> CGFloat {
        let dx = max(rect.minX - point.x, 0, point.x - rect.maxX)
        let dy = max(rect.minY - point.y, 0, point.y - rect.maxY)
        return hypot(dx, dy)
    }

    private func hasDisplay(at point: CGPoint, in displays: [CGRect]) -> Bool {
        return displays.contains { $0.contains(point) }
    }

    public func clamp(point: CGPoint, displays: [CGRect]? = nil) -> CGPoint {
        let activeDisplays = displays ?? cachedDisplays
        guard !activeDisplays.isEmpty else { return point }
        let d = findDisplay(for: point, in: activeDisplays)
        var p = point

        // Left edge
        if guardLeft && p.x < d.minX + inset {
            if guardInterDisplayBorders || !hasDisplay(at: CGPoint(x: d.minX - 1, y: p.y), in: activeDisplays) {
                p.x = d.minX + inset
            }
        }
        // Right edge
        if guardRight && p.x > d.maxX - inset {
            if guardInterDisplayBorders || !hasDisplay(at: CGPoint(x: d.maxX + 1, y: p.y), in: activeDisplays) {
                p.x = d.maxX - inset
            }
        }
        // Top edge (in Core Graphics coordinates, origin is top-left, minY is the top edge)
        if guardTop && p.y < d.minY + inset {
            if guardInterDisplayBorders || !hasDisplay(at: CGPoint(x: p.x, y: d.minY - 1), in: activeDisplays) {
                p.y = d.minY + inset
            }
        }
        // Bottom edge (maxY is the bottom edge)
        if guardBottom && p.y > d.maxY - inset {
            if guardInterDisplayBorders || !hasDisplay(at: CGPoint(x: p.x, y: d.maxY + 1), in: activeDisplays) {
                p.y = d.maxY - inset
            }
        }

        return p
    }

    // MARK: - Carbon Global Hotkey (Control + Option + G)
    private func registerHotKey() {
        guard hotKeyRef == nil else { return }

        // ANSI 'G' key code is 5 (kVK_ANSI_G)
        let keyCode: UInt32 = 5
        let modifiers: UInt32 = UInt32(controlKey | optionKey)
        let hotKeyID = EventHotKeyID(signature: hotKeySignature, id: hotKeyId)

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, theEvent, userData) -> OSStatus in
                guard let userData = userData, let theEvent = theEvent else { return noErr }
                var id = EventHotKeyID()
                GetEventParameter(
                    theEvent,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &id
                )
                let guardInstance = Unmanaged<MouseGuard>.fromOpaque(userData).takeUnretainedValue()
                if id.signature == guardInstance.hotKeySignature && id.id == guardInstance.hotKeyId {
                    guardInstance.toggle()
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )

        if status == noErr {
            RegisterEventHotKey(
                keyCode,
                modifiers,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &hotKeyRef
            )
            NSLog("[MouseGuard] Registered global shortcut Control + Option + G.")
        } else {
            NSLog("[MouseGuard] Failed to install Carbon event handler (status: %d)", status)
        }
    }

    private func unregisterHotKey() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }
    }
}
