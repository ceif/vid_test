import SwiftUI
import Combine

@main
struct myplayApp: App {
    // ✅ Usa AppDelegate para controlar orientação
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// ✅ AppDelegate para controlar orientação
class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.portrait
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}

// ✅ Classe auxiliar com métodos estáticos
class OrientationManager {
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        AppDelegate.orientationLock = orientation
        // ✅ Força a atualização
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }
}
