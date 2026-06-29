import Foundation
import Combine

class CanaisService: ObservableObject {
    @Published var canais: [Canal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let canaisURL = "http://myney/canais.json"
    
    func carregarCanais() {
        guard let url = URL(string: canaisURL) else {
            errorMessage = "URL inválida"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
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
