import SwiftUI

@main
struct myplayApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // ✅ Permite todas as orientações quando em fullscreen
                }
        }
    }
}

// ✅ EXTENSÃO PARA CONTROLAR ORIENTAÇÃO
extension UIViewController {
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIApplication.orientationLock
    }
}
