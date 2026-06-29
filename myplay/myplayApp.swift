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

// ✅ CORRIGIDO: Controlador de Orientação
class OrientationManager: ObservableObject {
    static let shared = OrientationManager()
    
    @Published var orientationLock: UIInterfaceOrientationMask = .portrait
    
    func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        orientationLock = orientation
        // ✅ iOS 16+ - notifica a UI para atualizar
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }
}

// ✅ CORRIGIDO: UIViewController extension
extension UIViewController {
    @objc dynamic var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return OrientationManager.shared.orientationLock
    }
}
