import Foundation
import Combine

class CanaisService: ObservableObject {
    @Published var canais: [Canal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // ✅ Agora recebe a URL por parâmetro
    internal var canaisURL: String
    
    init(canaisURL: String) {
        self.canaisURL = canaisURL
    }
    
    // ✅ Método para atualizar a URL
    func atualizarURL(_ novaURL: String) {
        canaisURL = novaURL
    }
    
    func carregarCanais() {
        guard let url = URL(string: canaisURL) else {
            errorMessage = "URL inválida: \(canaisURL)"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        print("📡 A carregar canais de: \(canaisURL)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Erro ao carregar: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "Dados não recebidos"
                    return
                }
                
                // Debug: Mostra o JSON recebido
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📡 JSON recebido: \(jsonString.prefix(200))...")
                }
                
                do {
                    let canais = try JSONDecoder().decode([Canal].self, from: data)
                    self?.canais = canais
                    print("✅ Canais carregados: \(canais.count)")
                } catch {
                    self?.errorMessage = "Erro ao decodificar JSON: \(error.localizedDescription)"
                    print("❌ Erro JSON: \(error)")
                }
            }
        }.resume()
    }
}
