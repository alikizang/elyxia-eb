import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    super.awakeFromNib()

    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // Taille minimale garantie
    self.minSize = NSSize(width: 1024, height: 700)

    // Ouvre l'application en grand (toute la surface de travail visible de l'écran)
    if let screen = NSScreen.main {
      self.setFrame(screen.visibleFrame, display: true)
    }

    RegisterGeneratedPlugins(registry: flutterViewController)
  }
}
