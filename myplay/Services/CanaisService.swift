import Foundation
import Combine

class CanaisService: ObservableObject {
    @Published var canais: [Canal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isFromCache = false
    
    private(set) var canaisURL: String
    private let cacheKey = "cached_canais"
    private let cacheTimestampKey = "cached_canais_timestamp"
    
    init(canaisURL: String) {
        self.canaisURL = canaisURL
        // ✅ Tenta carregar do cache imediatamente
        carregarDoCache()
    }
    
    func atualizarURL(_ novaURL: String) {
        canaisURL = novaURL
    }
    
    func carregarCanais() {
        guard let url = URL(string: canaisURL) else {
            errorMessage = "URL inválida: \(canaisURL)"
            // ✅ Em caso de URL inválida, tenta usar cache
            carregarDoCache()
            return
        }
        
        isLoading = true
        errorMessage = nil
        isFromCache = false
        
        print("📡 A carregar canais de: \(canaisURL)")
        
        // ✅ Adiciona timeout para não ficar eternamente a carregar
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Erro ao carregar: \(error.localizedDescription)"
                    print("❌ Erro de rede: \(error)")
                    // ✅ Em caso de erro, usa cache
                    self?.carregarDoCache()
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "Dados não recebidos"
                    // ✅ Em caso de dados vazios, usa cache
                    self?.carregarDoCache()
                    return
                }
                
                // ✅ Verifica se os dados são JSON válido
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📡 JSON recebido: \(jsonString.prefix(200))...")
                }
                
                do {
                    let canais = try JSONDecoder().decode([Canal].self, from: data)
                    self?.canais = canais
                    self?.isFromCache = false
                    self?.errorMessage = nil
                    
                    // ✅ GUARDA NO CACHE
                    self?.guardarCache(canais: canais)
                    
                    print("✅ Canais carregados: \(canais.count)")
                } catch {
                    self?.errorMessage = "Erro ao decodificar JSON: \(error.localizedDescription)"
                    print("❌ Erro JSON: \(error)")
                    // ✅ Em caso de erro de decodificação, usa cache
                    self?.carregarDoCache()
                }
            }
        }
        task.resume()
    }
    
    // ✅ GUARDA OS CANAIS NO CACHE (UserDefaults)
    private func guardarCache(canais: [Canal]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(canais)
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: cacheTimestampKey)
            print("✅ Cache guardado com \(canais.count) canais")
        } catch {
            print("❌ Erro ao guardar cache: \(error)")
        }
    }
    
    // ✅ CARREGA OS CANAIS DO CACHE
    private func carregarDoCache() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            print("📡 Sem cache disponível")
            // ✅ Se não houver cache, mantém a lista vazia
            if canais.isEmpty {
                errorMessage = "Sem dados disponíveis. Verifique a ligação à internet."
            }
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let canais = try decoder.decode([Canal].self, from: data)
            self.canais = canais
            self.isFromCache = true
            
            // ✅ Mostra quando o cache foi guardado
            if let timestamp = UserDefaults.standard.object(forKey: cacheTimestampKey) as? Date {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                print("📡 Cache carregado de: \(formatter.string(from: timestamp))")
            }
            
            // ✅ Mensagem informativa (não é erro)
            if errorMessage == nil || errorMessage?.contains("Sem dados") == true {
                errorMessage = "📡 A usar dados em cache (servidor indisponível)"
            }
            
            print("✅ Cache carregado com \(canais.count) canais")
        } catch {
            print("❌ Erro ao carregar cache: \(error)")
            // ✅ Remove cache corrompido
            UserDefaults.standard.removeObject(forKey: cacheKey)
            UserDefaults.standard.removeObject(forKey: cacheTimestampKey)
        }
    }
    
    // ✅ LIMPA O CACHE
    func limparCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheTimestampKey)
        print("🗑️ Cache limpo")
    }
    
    // ✅ VERIFICA SE HÁ CACHE DISPONÍVEL
    func temCache() -> Bool {
        return UserDefaults.standard.data(forKey: cacheKey) != nil
    }
}
