import SwiftUI
import AVKit
import Combine

struct ContentView: View {
    // MARK: - URLs (SUBSTITUA PELAS SUAS)
    private let videoURL = URL(string: "https")!
    private let certificateURL = URL(string: "https://")!
    private let licenseURL = URL(string: "https://")!
    
    // MARK: - Headers de Autenticação (ADICIONE OS SEUS)
    private let authToken = "eyJ"
    private let brandGuid = ""
    
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
    
    var body: some View {
        VStack {
            if let player = player {
                VideoPlayer(player: player)
                    //.frame(height: UIScreen.main.bounds.height * 0.5)
                    //.cornerRadius(16)
                    .padding(.horizontal)
                    .overlay(
                        Group {
                            if isLoading || !isReady {
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                    Text(isLoading ? "A obter licença..." : "A carregar...")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                                .padding(20)
                                //.background(Color.black.opacity(0.7))
                                //.cornerRadius(12)
                            }
                        }
                    )
            } else {
                ProgressView("Inicializando player...")
                    .frame(height: 300)
            }
            
            Spacer()
            
            Button(action: togglePlayPause) {
                HStack {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    Text(isPlaying ? "Pausar" : "Reproduzir")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(isReady ? Color.blue : Color.gray)
                .cornerRadius(25)
            }
            .disabled(!isReady)
            .padding(.bottom, 40)
        }
        .background(Color.black.opacity(0.05))
        .alert("Erro", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            contentKeySession = nil
            fairPlayDelegate = nil
            cancellables.removeAll()
        }
    }
    
    // MARK: - Configuração do Player
    private func setupPlayer() {
        print("📱 iOS Version: \(UIDevice.current.systemVersion)")
        print("🎬 Video URL: \(videoURL)")
        print("🔑 License URL: \(licenseURL)")
        
        let asset = AVURLAsset(url: videoURL)
        
        // Sempre configura DRM para conteúdo protegido
        setupFairPlay(for: asset)
        
        let playerItem = AVPlayerItem(asset: asset)
        let newPlayer = AVPlayer(playerItem: playerItem)
        player = newPlayer
        
        // Observa status do item
        playerItem.publisher(for: \.status)
            .sink { status in
                handleItemStatusChange(status)
            }
            .store(in: &cancellables)
        
        // Observa status de reprodução
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
        
        // Observa erros
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
        
        // Inicia reprodução
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
        
        // Mapeamento de erros comuns do FairPlay
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
    
    private func setupFairPlay(for asset: AVURLAsset) {
        let session = AVContentKeySession(keySystem: .fairPlayStreaming)
        session.addContentKeyRecipient(asset)
        
        let delegate = SimpleFairPlayDelegate(
            certificateURL: certificateURL,
            licenseURL: licenseURL,
            authToken: authToken,
            brandGuid: brandGuid
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

// MARK: - Delegate FairPlay Melhorado
class SimpleFairPlayDelegate: NSObject, AVContentKeySessionDelegate {
    private let certificateURL: URL
    private let licenseURL: URL
    private let authToken: String
    private let brandGuid: String
    private let urlSession: URLSession
    
    init(certificateURL: URL, licenseURL: URL, authToken: String, brandGuid: String) {
        self.certificateURL = certificateURL
        self.licenseURL = licenseURL
        self.authToken = authToken
        self.brandGuid = brandGuid
        
        // Configura URLSession com timeout maior
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
                // 1. Carrega o certificado
                let certificateData = try Data(contentsOf: self.certificateURL)
                print("📜 Certificado carregado: \(certificateData.count) bytes")
                
                // 2. Cria o SPC
                let contentIdentifierData = contentIdentifier.data(using: .utf8)!
                let spcData = try await keyRequest.makeStreamingContentKeyRequestData(
                    forApp: certificateData,
                    contentIdentifier: contentIdentifierData,
                    options: nil
                )
                print("✅ SPC criado: \(spcData.count) bytes")
                
                // 3. Envia para o servidor de licenças
                let responseData = try await self.sendSPCToLicenseServer(spcData: spcData)
                print("✅ CKC recebido: \(responseData.count) bytes")
                
                let ckcData = try self.extractCKCFromResponse(responseData)
                print("✅ CKC extraído: \(ckcData.count) bytes")
                
                // 4. Processa a resposta
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
        
        // ✅ HEADERS ESSENCIAIS PARA DRM
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // 🔑 Autenticação - ADICIONE OS SEUS HEADERS
        if !authToken.isEmpty {
            request.setValue(authToken, forHTTPHeaderField: "nv-authorizations")
        }
        if !brandGuid.isEmpty {
            request.setValue(brandGuid, forHTTPHeaderField: "x-drm-brandGuid")
        }
        
        
        
        print("📡 Enviando SPC para: \(licenseURL)")
        print("📡 Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await urlSession.data(for: request)
        
        // Verifica resposta HTTP
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 Status Code: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Erro desconhecido"
                throw NSError(
                    domain: "FairPlay",
                    code: httpResponse.statusCode,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Servidor retornou erro \(httpResponse.statusCode): \(errorMessage)"
                    ]
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
    
    // ✅ FUNÇÃO ESPECÍFICA PARA EXTRAIR O CKC DO CAMPO "CkcMessage"
    private func extractCKCFromResponse(_ data: Data) throws -> Data {
        // Tenta interpretar como JSON
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            // Se não for JSON, assume que é dados binários
            print("📡 Resposta não é JSON, assumindo dados binários")
            return data
        }
        
        print("📡 Resposta é JSON")
        
        // ✅ PROCURA ESPECIFICAMENTE PELO CAMPO "CkcMessage"
        if let ckcMessage = json["CkcMessage"] as? String {
            print("📡 Encontrado campo 'CkcMessage'")
            
            // Converte Base64 para Data
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
        
        // 🔍 TAMBÉM TENTA OUTROS CAMPOS COMUNS (fallback)
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
        
        // Se não encontrou nenhum campo, retorna o JSON como Data
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
