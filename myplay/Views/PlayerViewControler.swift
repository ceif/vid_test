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
        
        // ✅ INICIA PiP AUTOMATICAMENTE AO IR PARA SEGUNDO PLANO (iOS 14.2+)
        if #available(iOS 14.2, *) {
            controller.canStartPictureInPictureAutomaticallyFromInline = true
        }
        
        // ✅ CONFIGURAÇÕES VISUAIS
        controller.videoGravity = .resizeAspect
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
        // Atualiza o player se necessário
        if uiViewController.player !== player {
            uiViewController.player = player
        }
        
        // ✅ MOSTRA/ESCONDE CONTROLES CONSOANTE O ESTADO
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
        // ✅ PERMITE QUE A APP CONTINUE A FUNCIONAR QUANDO O PiP COMEÇA
        func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(_ playerViewController: AVPlayerViewController) -> Bool {
            return false // Não fecha a view quando o PiP começa
        }
        
        // ✅ EVENTOS DO PiP
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
        
        // ✅ RESTAURA A UI QUANDO O PiP TERMINA
        func playerViewController(_ playerViewController: AVPlayerViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
            completionHandler(true)
        }
        
        // ✅ EVENTOS DE FULLSCREEN
        func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            print("📺 Fullscreen vai começar")
        }
        
        func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            print("📺 Fullscreen vai terminar")
        }
    }
}
