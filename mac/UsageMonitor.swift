// Claude Code / Codex 사용량 메뉴바 앱 (macOS)
// 메뉴바: "C 4% · X 96%" (각 서비스의 5시간/1주일 중 높은 값)
// 왼쪽 클릭: 웹 화면 팝오버 · 오른쪽 클릭: 메뉴
import Cocoa
import WebKit

let PORT = ProcessInfo.processInfo.environment["USAGE_PORT"] ?? "8787"
let BASE = "http://127.0.0.1:\(PORT)"

final class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate {
    var item: NSStatusItem!
    let popover = NSPopover()
    var web: WKWebView!
    var server: Process?
    var timer: Timer?

    func applicationDidFinishLaunching(_ n: Notification) {
        startServer()

        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let b = item.button {
            b.title = "C – · X –"
            b.target = self
            b.action = #selector(clicked(_:))
            b.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        web = WKWebView(frame: NSRect(x: 0, y: 0, width: 290, height: 310))
        web.navigationDelegate = self
        let vc = NSViewController()
        vc.view = web
        popover.contentViewController = vc
        popover.contentSize = NSSize(width: 290, height: 310)
        popover.behavior = .transient

        // 서버가 뜰 시간을 조금 준 뒤 첫 조회
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self.refresh(); self.loadPage() }
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in self?.refresh() }
    }

    func applicationWillTerminate(_ n: Notification) {
        server?.terminate()
    }

    // MARK: 서버
    func startServer() {
        guard let res = Bundle.main.resourcePath else { return }
        let py = ["/opt/homebrew/bin/python3", "/usr/local/bin/python3", "/usr/bin/python3"]
            .first { FileManager.default.isExecutableFile(atPath: $0) } ?? "/usr/bin/python3"
        let p = Process()
        p.executableURL = URL(fileURLWithPath: py)
        p.arguments = [res + "/server.py"]
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        // 이미 다른 서버가 포트를 쓰고 있으면 이 프로세스는 바로 종료되고 기존 서버를 그대로 사용
        try? p.run()
        server = p
    }

    // MARK: 메뉴바 숫자
    func refresh() {
        guard let url = URL(string: BASE + "/api/usage") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let j = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async { self.item.button?.title = "C ? · X ?" }
                return
            }
            DispatchQueue.main.async { self.render(j) }
        }.resume()
    }

    func pct(_ s: [String: Any]?, _ k: String) -> Double? {
        guard let w = s?[k] as? [String: Any] else { return nil }
        return (w["pct"] as? NSNumber)?.doubleValue
    }

    func color(_ v: Double) -> NSColor {
        v >= 90 ? .systemRed : v >= 70 ? .systemOrange : .labelColor
    }

    func render(_ j: [String: Any]) {
        let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize - 1, weight: .medium)
        let out = NSMutableAttributedString()
        var tip: [String] = []
        for (i, (key, label, name)) in [("claude", "C", "Claude Code"), ("codex", "X", "Codex")].enumerated() {
            let s = j[key] as? [String: Any]
            if i > 0 { out.append(NSAttributedString(string: " · ", attributes: [.font: font, .foregroundColor: NSColor.secondaryLabelColor])) }
            out.append(NSAttributedString(string: label + " ", attributes: [.font: font, .foregroundColor: NSColor.labelColor]))
            if (s?["ok"] as? Bool) == true {
                let f = pct(s, "five") ?? 0, w = pct(s, "week") ?? 0, m = max(f, w)
                out.append(NSAttributedString(string: "\(Int(m.rounded()))%", attributes: [.font: font, .foregroundColor: color(m)]))
                tip.append("\(name)  5시간 \(Int(f.rounded()))% · 1주일 \(Int(w.rounded()))%")
            } else {
                out.append(NSAttributedString(string: "!", attributes: [.font: font, .foregroundColor: NSColor.systemRed]))
                tip.append("\(name)  오류: \(s?["error"] as? String ?? "?")")
            }
        }
        item.button?.attributedTitle = out
        item.button?.toolTip = tip.joined(separator: "\n")
    }

    // MARK: 클릭
    @objc func clicked(_ sender: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            let m = NSMenu()
            m.addItem(withTitle: "새로고침", action: #selector(forceRefresh), keyEquivalent: "r").target = self
            m.addItem(withTitle: "브라우저에서 열기", action: #selector(openBrowser), keyEquivalent: "o").target = self
            m.addItem(.separator())
            m.addItem(withTitle: "종료", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
            item.menu = m
            item.button?.performClick(nil)
            item.menu = nil
            return
        }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            web.evaluateJavaScript("typeof load==='function' && load()") { _, err in
                if err != nil { self.loadPage() }
            }
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
            refresh()
        }
    }

    @objc func forceRefresh() {
        guard let url = URL(string: BASE + "/api/usage?force=1") else { return }
        URLSession.shared.dataTask(with: url) { _, _, _ in
            DispatchQueue.main.async { self.refresh(); self.loadPage() }
        }.resume()
    }

    @objc func openBrowser() {
        if let u = URL(string: BASE) { NSWorkspace.shared.open(u) }
    }

    func loadPage() {
        if let u = URL(string: BASE) { web.load(URLRequest(url: u)) }
    }

    // 페이지 내용 높이에 맞춰 팝오버 크기 조절
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            webView.evaluateJavaScript("document.body.scrollHeight") { h, _ in
                if let h = (h as? NSNumber)?.doubleValue, h > 50 {
                    self.popover.contentSize = NSSize(width: 290, height: min(h, 600))
                }
            }
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // Dock 아이콘 없음
app.run()
