import SwiftUI
import AVKit
import Combine

struct ContentView: View {
    // MARK: - Estado
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var contentKeySession: AVContentKeySession?
    @State private var fairPlayDelegate: SimpleFairPlayDelegate?
    @State private var cancellables = Set<AnyCancellable>()
    @State private var isReady = false
    @State private var isLoading = false
    @State private var showSettings = false
    @State private var isFullscreen = false
    
    // MARK: - ViewModels
    @StateObject private var canaisViewModel: CanaisViewModel
    
    // MARK: - UserDefaults para configurações
    @AppStorage("canaisURL") private var canaisURL = "http://myney/canais.json"
    @AppStorage("certificateURL") private var certificateURL = ""
    @AppStorage("licenseURL") private var licenseURL = ""
    @AppStorage("authToken") private var authToken = ""
    
    // MARK: - Canal selecionado
    @State private var selectedCanal: Canal?
    @State private var currentVideoURL: String = ""
    
    // MARK: - Inicialização
    init() {
        let url = UserDefaults.standard.string(forKey: "canaisURL") ?? "http://myney/canais.json"
        _canaisViewModel = StateObject(wrappedValue: CanaisViewModel(canaisURL: url))
    }
    
    var body: some View {
        GeometryReader { geometry in
            NavigationStack {
                VStack(spacing: 0) {
                    // ✅ PLAYER VIEW
                    playerView(height: geometry.size.height)
                    
                    // ✅ CONTROLES
                    controlsView
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Grid de Canais
                    CanalGridView(
                        viewModel: canaisViewModel,
                        onCanalSelected: { canal in
                            selecionarCanal(canal)
                        }
                    )
                    .padding(.top, 4)
                }
                .navigationTitle("📺 TV")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showSettings.toggle() }) {
                            Image(systemName: "gear")
                        }
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                        .onDisappear {
                            let novaURL = UserDefaults.standard.string(forKey: "canaisURL") ?? "http://myney/canais.json"
                            canaisViewModel.verificarEAtualizarURL(novaURL)
                            
                            if let canal = selectedCanal {
                                reloadPlayer(with: canal)
                            }
                        }
                }
                .alert("Erro", isPresented: $showError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(errorMessage)
                }
                .onAppear {
                    carregarConfiguracoes()
                    canaisViewModel.carregarCanais()                    
                }
                .onDisappear {
                    player?.pause()
                    contentKeySession = nil
                    fairPlayDelegate = nil
                    cancellables.removeAll()
                }
                // ✅ SUPORTA ORIENTAÇÃO EM FULLSCREEN
                .onChange(of: isFullscreen) { newValue in
                    if newValue {
                        // ✅ Permite todas as orientações em fullscreen
                        OrientationManager.lockOrientation(.all)
                    } else {
                        // ✅ Volta para portrait
                        OrientationManager.lockOrientation(.portrait)
                    }
                }
            }
        }
    }
    
    // ✅ VIEW DO PLAYER
    @ViewBuilder
    private func playerView(height: CGFloat) -> some View {
        let playerHeight = isFullscreen ? height : height * 0.35
        
        if let player = player {
            PlayerViewController(
                player: player,
                isReady: isReady,
                isLoading: isLoading
            )
            .frame(height: playerHeight)
            .padding(.horizontal, isFullscreen ? 0 : 16)
            .overlay(loadingOverlay)
            .onTapGesture(count: 2) {
                toggleFullscreen()
            }
        } else {
            emptyPlayerView(height: playerHeight)
        }
    }
    
    // ✅ OVERLAY DE CARREGAMENTO
    @ViewBuilder
    private var loadingOverlay: some View {
        if isLoading || !isReady {
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                Text(isLoading ? "A obter licença..." : "A carregar...")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .padding(20)
            .background(Color.black.opacity(0.7))
            .cornerRadius(12)
        }
    }
    
    // ✅ VIEW QUANDO NÃO HÁ PLAYER
    @ViewBuilder
    private func emptyPlayerView(height: CGFloat) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "tv")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("Selecione um canal")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .padding(.horizontal)
    }
    
    // ✅ CONTROLES DO PLAYER
    @ViewBuilder
    private var controlsView: some View {
        if player != nil {
            HStack {
                // Botão Play/Pause
                Button(action: togglePlayPause) {
                    HStack {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        Text(isPlaying ? "Pausar" : "Reproduzir")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(isReady ? Color.blue : Color.gray)
                    .cornerRadius(25)
                }
                .disabled(!isReady)
                
                Spacer()
                
                if let canal = selectedCanal {
                    Text("📺 \(canal.nome)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.trailing, 8)
                }
                
                // ✅ BOTÃO DE FULLSCREEN
                Button(action: toggleFullscreen) {
                    Image(systemName: isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }
                .padding(.trailing, 8)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Funções

     
    private func toggleFullscreen() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isFullscreen.toggle()
            
            // ✅ Usa o OrientationManager para controlar orientação
            if isFullscreen {
                // ✅ Permite todas as orientações
                OrientationManager.lockOrientation(.all)
                // ✅ Força landscape
                UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            } else {
                // ✅ Volta para portrait
                OrientationManager.lockOrientation(.portrait)
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            }
            
            // ✅ Atualiza a UI
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            }
        }
    }
    
    private func carregarConfiguracoes() {
        if certificateURL.isEmpty {
            certificateURL = "https://seu-servidor.com/certificate.der"
        }
        if licenseURL.isEmpty {
            licenseURL = "https://seu-servidor.com/license"
        }
    }
    
    private func selecionarCanal(_ canal: Canal) {
        selectedCanal = canal
        currentVideoURL = canal.url
        reloadPlayer(with: canal)
    }
    
    private func reloadPlayer(with canal: Canal) {
        guard let url = URL(string: canal.url) else {
            errorMessage = "URL do canal inválida"
            showError = true
            return
        }
        
        player?.pause()
        player = nil
        contentKeySession = nil
        fairPlayDelegate = nil
        cancellables.removeAll()
        isReady = false
        
        setupPlayer(with: url)
    }
    
    private func setupPlayer(with url: URL) {
        print("📱 iOS Version: \(UIDevice.current.systemVersion)")
        print("🎬 Video URL: \(url)")
        print("🔑 License URL: \(licenseURL)")
        
        guard let licenseURL = URL(string: licenseURL),
              let certificateURL = URL(string: certificateURL) else {
            errorMessage = "Configurações DRM inválidas. Verifique nas definições."
            showError = true
            return
        }
        
        let asset = AVURLAsset(url: url)
        setupFairPlay(for: asset, certificateURL: certificateURL, licenseURL: licenseURL)
        
        let playerItem = AVPlayerItem(asset: asset)
        let newPlayer = AVPlayer(playerItem: playerItem)
        player = newPlayer
        
        playerItem.publisher(for: \.status)
            .sink { status in
                handleItemStatusChange(status)
            }
            .store(in: &cancellables)
        
        newPlayer.publisher(for: \.timeControlStatus)
            .sink { status in
                isPlaying = (status == .playing)
                if status == .waitingToPlayAtSpecifiedRate {
                    isLoading = true
                } else {
                    isLoading = false
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { notification in
            if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
                self.errorMessage = "Erro: \(error.localizedDescription)"
                self.showError = true
                print("❌ Erro: \(error)")
                self.isLoading = false
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            print("🏁 Vídeo terminou")
            isPlaying = false
        }
        
        newPlayer.play()
        isPlaying = true
        print("▶️ Player iniciado")
    }
    
    private func handleItemStatusChange(_ status: AVPlayerItem.Status) {
        switch status {
        case .readyToPlay:
            print("✅ Pronto para reproduzir")
            isReady = true
            isLoading = false
            errorMessage = ""
        case .failed:
            if let error = player?.currentItem?.error {
                print("❌ Erro no item: \(error)")
                handlePlayerError(error)
                isReady = false
                isLoading = false
            }
        case .unknown:
            print("⏳ Carregando...")
            isReady = false
        @unknown default:
            break
        }
    }
    
    private func handlePlayerError(_ error: Error) {
        let nsError = error as NSError
        
        switch nsError.code {
        case -42681:
            errorMessage = "Erro de licença: O servidor não autorizou a reprodução. Verifique o token de autenticação."
        case -11835:
            errorMessage = "Conteúdo não autorizado. Verifique as credenciais de DRM."
        case -12660:
            errorMessage = "Erro 403: Acesso negado ao servidor."
        case -1102:
            errorMessage = "Permissão negada. Verifique as credenciais."
        default:
            errorMessage = "Erro: \(error.localizedDescription)"
        }
        showError = true
    }
    
    private func setupFairPlay(for asset: AVURLAsset, certificateURL: URL, licenseURL: URL) {
        let session = AVContentKeySession(keySystem: .fairPlayStreaming)
        session.addContentKeyRecipient(asset)
        
        let delegate = SimpleFairPlayDelegate(
            certificateURL: certificateURL,
            licenseURL: licenseURL,
            authToken: authToken
        )
        session.setDelegate(delegate, queue: DispatchQueue.main)
        
        self.contentKeySession = session
        self.fairPlayDelegate = delegate
        
        print("✅ FairPlay configurado")
    }
    
    private func togglePlayPause() {
        guard let player = player, isReady else { return }
        
        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            player.play()
        }
    }
}

// MARK: - Delegate FairPlay (manter igual)
class SimpleFairPlayDelegate: NSObject, AVContentKeySessionDelegate {
    private let certificateURL: URL
    private let licenseURL: URL
    private let authToken: String
    private let urlSession: URLSession
    
    init(certificateURL: URL, licenseURL: URL, authToken: String) {
        self.certificateURL = certificateURL
        self.licenseURL = licenseURL
        self.authToken = authToken
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.urlSession = URLSession(configuration: config)
        
        super.init()
    }
    
    func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVContentKeyRequest) {
        guard let contentIdentifier = keyRequest.identifier as? String else {
            print("❌ Sem identificador de conteúdo")
            keyRequest.processContentKeyResponseError(
                NSError(domain: "FairPlay", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sem identificador"])
            )
            return
        }
        
        print("🔑 Solicitando chave para: \(contentIdentifier.prefix(50))...")
        
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                let certificateData = try Data(contentsOf: self.certificateURL)
                print("📜 Certificado carregado: \(certificateData.count) bytes")
                
                let contentIdentifierData = contentIdentifier.data(using: .utf8)!
                let spcData = try await keyRequest.makeStreamingContentKeyRequestData(
                    forApp: certificateData,
                    contentIdentifier: contentIdentifierData,
                    options: nil
                )
                print("✅ SPC criado: \(spcData.count) bytes")
                
                let responseData = try await self.sendSPCToLicenseServer(spcData: spcData)
                print("✅ Resposta recebida: \(responseData.count) bytes")
                
                let ckcData = try self.extractCKCFromResponse(responseData)
                print("✅ CKC extraído: \(ckcData.count) bytes")
                
                await MainActor.run {
                    let keyResponse = AVContentKeyResponse(fairPlayStreamingKeyResponseData: ckcData)
                    keyRequest.processContentKeyResponse(keyResponse)
                }
                
            } catch {
                print("❌ Erro no processo de licença: \(error)")
                await MainActor.run {
                    keyRequest.processContentKeyResponseError(error)
                }
            }
        }
    }
    
    private func sendSPCToLicenseServer(spcData: Data) async throws -> Data {
        var request = URLRequest(url: licenseURL)
        request.httpMethod = "POST"
        request.httpBody = spcData
        
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if !authToken.isEmpty {
            request.setValue(authToken, forHTTPHeaderField: "nv-authorizations")
        }
        
        print("📡 Enviando SPC para: \(licenseURL)")
        
        let (data, response) = try await urlSession.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 Status Code: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Erro desconhecido"
                throw NSError(
                    domain: "FairPlay",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "Servidor retornou erro \(httpResponse.statusCode): \(errorMessage)"]
                )
            }
        }
        
        guard !data.isEmpty else {
            throw NSError(
                domain: "FairPlay",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Resposta do servidor vazia"]
            )
        }
        
        return data
    }
    
    private func extractCKCFromResponse(_ data: Data) throws -> Data {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("📡 Resposta não é JSON, assumindo dados binários")
            return data
        }
        
        print("📡 Resposta é JSON")
        
        if let ckcMessage = json["CkcMessage"] as? String {
            print("📡 Encontrado campo 'CkcMessage'")
            
            guard let ckcData = Data(base64Encoded: ckcMessage) else {
                print("❌ Erro ao decodificar Base64 do CkcMessage")
                throw NSError(
                    domain: "FairPlay",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "CkcMessage não é um Base64 válido"]
                )
            }
            
            print("✅ CKC decodificado do Base64: \(ckcData.count) bytes")
            return ckcData
        }
        
        let possibleKeys = ["license", "ckc", "key", "contentKey", "data", "payload"]
        for key in possibleKeys {
            if let value = json[key] as? String {
                print("📡 Tentando campo alternativo '\(key)'")
                if let ckcData = Data(base64Encoded: value) {
                    print("✅ CKC decodificado do campo '\(key)': \(ckcData.count) bytes")
                    return ckcData
                }
            }
        }
        
        print("⚠️ Nenhum campo de CKC encontrado, retornando JSON inteiro")
        return data
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
