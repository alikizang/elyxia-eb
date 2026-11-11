import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // Ouvre l'application en grand (maximisée / plein écran de travail)
    if let screen = NSScreen.main {
      self.setFrame(screen.visibleFrame, display: true)
    }
    self.minSize = NSSize(width: 1024, height: 700)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
    self.zoom(nil)
  }
}
