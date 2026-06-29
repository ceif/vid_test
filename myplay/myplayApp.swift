import SwiftUI
import Combine

@main
struct myplayApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// ✅ CORRIGIDO: Controlador de Orientação Global
class OrientationManager: ObservableObject {
    static let shared = OrientationManager()
    
    @Published var orientationLock: UIInterfaceOrientationMask = .portrait
    
    func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        orientationLock = orientation
        // ✅ Força a atualização
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }
}

// ✅ CORRIGIDO: UIViewController extension - SEM OVERRIDE
extension UIViewController {
    // ✅ Usa @objc dynamic para permitir substituição em tempo de execução
    @objc dynamic var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return OrientationManager.shared.orientationLock
    }
    
    @objc dynamic var shouldAutorotate: Bool {
        return true
    }
}

// ✅ CORRIGIDO: SceneDelegate ou AppDelegate para iOS 15/16
// Se estiver a usar AppDelegate, adicione este método
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return OrientationManager.shared.orientationLock
    }
}
