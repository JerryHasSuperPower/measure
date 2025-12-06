import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
    
    // 在 awakeFromNib 之后设置窗口大小和位置
    if let screen = NSScreen.main {
      let screenRect = screen.visibleFrame
      // 设置窗口大小为屏幕的75%左右，最小1000x700
      let windowWidth = max(1000.0, min(1400.0, screenRect.width * 0.75))
      let windowHeight = max(700.0, min(900.0, screenRect.height * 0.75))
      
      // 居中显示
      let x = screenRect.origin.x + (screenRect.width - windowWidth) / 2
      let y = screenRect.origin.y + (screenRect.height - windowHeight) / 2
      
      let windowFrame = NSRect(x: x, y: y, width: windowWidth, height: windowHeight)
      self.setFrame(windowFrame, display: true)
    }
    
    // 确保窗口显示在前台
    self.makeKeyAndOrderFront(nil)
    self.center()
  }
}
