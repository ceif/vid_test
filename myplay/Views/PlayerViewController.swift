import SwiftUI
import AVKit

struct PlayerViewController: UIViewControllerRepresentable {
    let player: AVPlayer?
    let isReady: Bool
    let isLoading: Bool
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        
        // ✅ ATIVA O PICTURE-IN-PICTURE
        controller.allowsPictureInPicturePlayback = true
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        // ✅ INICIA PiP AUTOMATICAMENTE AO IR PARA SEGUNDO PLANO (iOS 14.2+)
    //    if #available(iOS 14.2, *) {
    //        controller.canStartPictureInPictureAutomaticallyFromInline = true
    //    }
        
        // ✅ CONFIGURAÇÕES VISUAIS
        controller.videoGravity = .resize
        controller.showsPlaybackControls = true
        
        // ✅ PERMITE FULLSCREEN
        controller.modalPresentationStyle = .fullScreen
        controller.entersFullScreenWhenPlaybackBegins = false
        controller.exitsFullScreenWhenPlaybackEnds = false
        
        // ✅ DELEGATE PARA CONTROLO PiP
        controller.delegate = context.coordinator
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if uiViewController.player !== player {
            uiViewController.player = player
        }
        
        if isReady && !isLoading {
            uiViewController.showsPlaybackControls = true
        } else {
            uiViewController.showsPlaybackControls = false
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, AVPlayerViewControllerDelegate {
        func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(_ playerViewController: AVPlayerViewController) -> Bool {
            return false
        }
        
        func playerViewControllerWillStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
            print("🎬 PiP vai começar")
        }
        
        func playerViewControllerDidStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
            print("🎬 PiP começou")
        }
        
        func playerViewControllerWillStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
            print("🛑 PiP vai parar")
        }
        
        func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
            print("🛑 PiP parou")
        }
        
        func playerViewController(_ playerViewController: AVPlayerViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
            completionHandler(true)
        }
        
        func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            print("📺 Fullscreen vai começar")
        }
        
        func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            print("📺 Fullscreen vai terminar")
        }
    }
}
