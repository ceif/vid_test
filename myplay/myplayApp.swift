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

// ✅ EXTENSÃO PARA ORIENTAÇÃO
extension UIViewController {
    @objc dynamic var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIApplication.orientationLock
    }
}
