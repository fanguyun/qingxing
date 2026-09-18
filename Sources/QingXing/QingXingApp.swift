import SwiftUI
import AppKit

@main
struct QingXingApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(model: model)
        } label: {
            Image(systemName: model.menuBarSymbol)
                .foregroundStyle(model.menuBarTint)
        }
        .menuBarExtraStyle(.window)

        Window("轻醒设置", id: "settings") {
            SettingsView(model: model)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 560, height: 700)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
