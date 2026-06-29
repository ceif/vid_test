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

// ✅ CORRIGIDO: UIViewController extension
extension UIViewController {
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return OrientationManager.shared.orientationLock
    }
    
    open override var shouldAutorotate: Bool {
        return true
    }
}
