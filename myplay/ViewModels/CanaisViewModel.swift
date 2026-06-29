import Foundation
import Combine

class CanaisViewModel: ObservableObject {
    @Published var canais: [Canal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCanal: Canal?
    
    // ✅ Mude de 'private' para 'internal' ou 'public'
    internal var service: CanaisService  // ← AGORA É ACESSÍVEL
    private var cancellables = Set<AnyCancellable>()
    
    init(canaisURL: String) {
        self.service = CanaisService(canaisURL: canaisURL)
        setupBindings()
    }
    
    func atualizarURL(_ novaURL: String) {
        service.atualizarURL(novaURL)
        service.carregarCanais()
    }
    
    private func setupBindings() {
        service.$canais
            .assign(to: \.canais, on: self)
            .store(in: &cancellables)
        
        service.$isLoading
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        service.$errorMessage
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
    }
    
    func carregarCanais() {
        service.carregarCanais()
    }
    
    func selecionarCanal(_ canal: Canal) {
        selectedCanal = canal
    }
}
