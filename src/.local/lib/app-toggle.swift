import AppKit
import ApplicationServices
import Darwin

struct ToggleError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

struct Frame: Decodable {
    let x: Double
    let y: Double
}

struct Window: Decodable {
    let id: Int
    let pid: pid_t
    let title: String
    let frame: Frame
    let space: Int
    let subrole: String
    let isMinimized: Bool
    let isFullscreen: Bool

    enum CodingKeys: String, CodingKey {
        case id, pid, title, frame, space, subrole
        case isMinimized = "is-minimized"
        case isFullscreen = "is-native-fullscreen"
    }
}

struct Space: Decodable {
    let index: Int
    let isFullscreen: Bool

    enum CodingKeys: String, CodingKey {
        case index
        case isFullscreen = "is-native-fullscreen"
    }
}

struct WindowDescription: Decodable {
    let id: Int
    let bounds: Bounds

    struct Bounds: Decodable {
        let x: Double
        let y: Double
        enum CodingKeys: String, CodingKey { case x = "X", y = "Y" }
    }

    enum CodingKeys: String, CodingKey {
        case id = "kCGWindowNumber"
        case bounds = "kCGWindowBounds"
    }
}

func livePositions() throws -> [Int: CGPoint] {
    guard let descriptions = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) else {
        throw ToggleError(message: "ウィンドウの現在位置を取得できませんでした。")
    }
    let data = try PropertyListSerialization.data(fromPropertyList: descriptions, format: .binary, options: 0)
    let windows = try PropertyListDecoder().decode([WindowDescription].self, from: data)
    return Dictionary(windows.map { ($0.id, CGPoint(x: $0.bounds.x, y: $0.bounds.y)) }, uniquingKeysWith: { first, _ in first })
}

func checkPOSIX(_ status: Int32, _ action: String) throws {
    guard status == 0 else {
        throw ToggleError(message: "\(action): \(String(cString: strerror(status)))")
    }
}

func command(_ path: String, _ arguments: [String]) throws -> Data {
    let output = Pipe()
    var actions: posix_spawn_file_actions_t?
    try checkPOSIX(posix_spawn_file_actions_init(&actions), "プロセスの準備")
    defer { posix_spawn_file_actions_destroy(&actions) }
    try checkPOSIX(posix_spawn_file_actions_adddup2(&actions, output.fileHandleForWriting.fileDescriptor, STDOUT_FILENO), "出力先の設定")
    try checkPOSIX(posix_spawn_file_actions_addclose(&actions, output.fileHandleForReading.fileDescriptor), "読み取り側の設定")
    try checkPOSIX(posix_spawn_file_actions_addclose(&actions, output.fileHandleForWriting.fileDescriptor), "書き込み側の設定")
    let strings = ([path] + arguments).map { strdup($0) }
    let environment = ProcessInfo.processInfo.environment.map { strdup("\($0.key)=\($0.value)") }
    defer { (strings + environment).forEach { free($0) } }
    guard (strings + environment).allSatisfy({ $0 != nil }) else { throw ToggleError(message: "コマンド引数のメモリを確保できませんでした。") }
    var argv = strings + [nil]
    var envp = environment + [nil]
    var pid: pid_t = 0
    try checkPOSIX(posix_spawn(&pid, path, &actions, nil, &argv, &envp), path)
    output.fileHandleForWriting.closeFile()
    let data = output.fileHandleForReading.readDataToEndOfFile()
    var status: Int32 = 0
    while waitpid(pid, &status, 0) < 0 {
        if errno != EINTR { throw ToggleError(message: "\(path) の終了待ち: \(String(cString: strerror(errno)))") }
    }
    guard status == 0 else {
        let code = (status & 0x7f) == 0 ? (status >> 8) & 0xff : 128 + (status & 0x7f)
        throw ToggleError(message: "\(path) \(arguments.joined(separator: " ")) が失敗しました (exit \(code))。")
    }
    return data
}

func waitFor<T>(_ description: String, _ check: () throws -> T?) throws -> T {
    let deadline = Date().addingTimeInterval(5)
    repeat {
        if let result = try check() { return result }
        RunLoop.current.run(until: Date().addingTimeInterval(0.02))
    } while Date() < deadline
    throw ToggleError(message: "\(description)が5秒以内に完了しませんでした。")
}

func attribute(_ element: AXUIElement, _ name: String) throws -> CFTypeRef? {
    var value: CFTypeRef?
    let error = AXUIElementCopyAttributeValue(element, name as CFString, &value)
    if error == .noValue || error == .attributeUnsupported { return nil }
    guard error == .success else {
        throw ToggleError(message: "\(name) の取得に失敗しました (AXError \(error.rawValue))。アクセシビリティ権限を確認してください。")
    }
    return value
}

func focusedWindow(_ app: NSRunningApplication) throws -> AXUIElement? {
    guard let value = try attribute(AXUIElementCreateApplication(app.processIdentifier), kAXFocusedWindowAttribute),
          CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
    return unsafeBitCast(value, to: AXUIElement.self)
}

func position(_ window: AXUIElement) throws -> CGPoint? {
    guard let value = try attribute(window, kAXPositionAttribute),
          CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
    var point = CGPoint.zero
    guard AXValueGetValue(unsafeBitCast(value, to: AXValue.self), .cgPoint, &point) else {
        throw ToggleError(message: "ウィンドウ位置を読み取れませんでした。")
    }
    return point
}

func closeEnough(_ first: CGFloat, _ second: CGFloat) -> Bool {
    abs(first - second) < 2
}

func matches(_ window: Window, title: String?, point: CGPoint?, livePoint: CGPoint?) -> Bool {
    guard let point else { return false }
    let expected = livePoint ?? CGPoint(x: window.frame.x, y: window.frame.y)
    return (title == nil || window.title == title) &&
        closeEnough(expected.x, point.x) && closeEnough(expected.y, point.y)
}

func toggle(bundleID: String, yabai: String) throws {
    func app() -> NSRunningApplication? {
        NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first
    }
    func query<T: Decodable>(_ arguments: [String]) throws -> T {
        try JSONDecoder().decode(T.self, from: command(yabai, ["query"] + arguments))
    }
    var running = app()
    if let running, running.isActive {
        // 戻り値が false でも非同期に完了するため、実際の状態で判定する。
        running.hide()
        let _: Bool = try waitFor("アプリの非表示") { running.isHidden ? true : nil }
        return
    }

    let destination: Space = try query(["--spaces", "--space"])
    guard !destination.isFullscreen else {
        throw ToggleError(message: "フルスクリーン専用デスクトップには移動できません。通常のデスクトップで実行してください。")
    }
    func windows(for app: NSRunningApplication) throws -> [Window] {
        let all: [Window] = try query(["--windows"])
        return all.filter { $0.pid == app.processIdentifier && $0.subrole == "AXStandardWindow" }
    }
    var candidates = try running.map { try windows(for: $0) } ?? []
    if candidates.isEmpty {
        _ = try command("/usr/bin/open", ["-g", "-b", bundleID])
        let started = try waitFor("アプリの起動", app)
        running = started
        candidates = try waitFor("ウィンドウの生成") {
            let found = try windows(for: started)
            return found.isEmpty ? nil : found
        }
    }
    guard let running else { throw ToggleError(message: "アプリが見つかりません。") }
    let focused = try focusedWindow(running)
    let title = try focused.flatMap { try attribute($0, kAXTitleAttribute) as? String }
    let point = try focused.flatMap(position)
    // yabai の非表示ウィンドウの座標キャッシュが古い場合があるため現在値を使う。
    let positions = try livePositions()
    guard let selected = candidates.first(where: { matches($0, title: title, point: point, livePoint: positions[$0.id]) }) ?? candidates.first else {
        throw ToggleError(message: "対象ウィンドウが見つかりません。")
    }
    guard !selected.isFullscreen else {
        throw ToggleError(message: "対象ウィンドウのフルスクリーンを解除してから実行してください。")
    }
    if selected.isMinimized {
        _ = try command(yabai, ["window", "--deminimize", String(selected.id)])
    }
    if selected.space != destination.index {
        _ = try command(yabai, ["window", String(selected.id), "--space", String(destination.index)])
    }
    running.unhide()
    _ = try command(yabai, ["window", "--focus", String(selected.id)])
    // skhd の最大化ショートカットと同じ処理を毎回適用する。
    _ = try command(yabai, ["window", String(selected.id), "--grid", "1:1:0:0:1:1"])
    let _: Bool = try waitFor("ウィンドウの表示") {
        NSWorkspace.shared.frontmostApplication?.processIdentifier == running.processIdentifier ? true : nil
    }
}

do {
    guard CommandLine.arguments.count == 3 else {
        throw ToggleError(message: "Usage: app-toggle <bundle-id> <yabai-run>")
    }
    try toggle(bundleID: CommandLine.arguments[1], yabai: CommandLine.arguments[2])
} catch {
    FileHandle.standardError.write(Data("app-toggle: \(error.localizedDescription)\n".utf8))
    exit(1)
}
