import Foundation
import Combine

class CanaisViewModel: ObservableObject {
    @Published var canais: [Canal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCanal: Canal?
    
    private var service: CanaisService
    private var cancellables = Set<AnyCancellable>()
    
    // ✅ Recebe a URL do JSON
    init(canaisURL: String) {
        self.service = CanaisService(canaisURL: canaisURL)
        setupBindings()
    }
    
    // ✅ Método para atualizar a URL e recarregar
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
