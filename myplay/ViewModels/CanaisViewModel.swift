import Foundation
import Combine

class CanaisViewModel: ObservableObject {
    @Published var canais: [Canal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCanal: Canal?
    @Published var isFromCache = false
    
    internal var service: CanaisService
    private var cancellables = Set<AnyCancellable>()
    
    init(canaisURL: String) {
        self.service = CanaisService(canaisURL: canaisURL)
        setupBindings()
    }
    
    func verificarEAtualizarURL(_ novaURL: String) {
        if service.canaisURL != novaURL {
            service.atualizarURL(novaURL)
            service.carregarCanais()
        }
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
        
        service.$isFromCache
            .assign(to: \.isFromCache, on: self)
            .store(in: &cancellables)
    }
    
    func carregarCanais() {
        service.carregarCanais()
    }
    
    func selecionarCanal(_ canal: Canal) {
        selectedCanal = canal
    }
    
    // ✅ LIMPA O CACHE
    func limparCache() {
        service.limparCache()
    }
    
    // ✅ VERIFICA SE HÁ CACHE
    func temCache() -> Bool {
        return service.temCache()
    }
}
