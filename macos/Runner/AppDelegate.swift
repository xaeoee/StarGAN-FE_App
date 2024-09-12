import Cocoa
import FlutterMacOS
import AVFoundation

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    AVCaptureDevice.requestAccess(for: .video) { granted in
      if granted {
        print("Camera access granted")
      } else {
        print("Camera access denied")
      }
    }
  }
}