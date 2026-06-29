import Foundation
import Combine

class CanaisViewModel: ObservableObject {
    @Published var canais: [Canal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCanal: Canal?
    
    private let service = CanaisService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Sincroniza com o service
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