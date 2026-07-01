import SwiftUI

struct CanalGridView: View {
    @ObservedObject var viewModel: CanaisViewModel
    let onCanalSelected: (Canal) -> Void
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ✅ TÍTULO COM INDICADOR DE CACHE
            HStack {
                Text("📺 Canais")
                    .font(.headline)
                    .fontWeight(.bold)
                
                // ✅ INDICADOR DE CACHE
                if viewModel.isFromCache {
                    Image(systemName: "icloud.slash")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .help("A usar dados em cache")
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                
                Spacer()
                
                // ✅ BOTÃO PARA RECARREGAR
                Button(action: {
                    viewModel.carregarCanais()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // ✅ MENSAGEM DE ERRO/CACHE
            if let error = viewModel.errorMessage {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: viewModel.isFromCache ? "icloud.slash" : "exclamationmark.triangle")
                            .foregroundColor(viewModel.isFromCache ? .orange : .red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(viewModel.isFromCache ? .orange : .secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    if viewModel.isFromCache {
                        Text("Os canais estão a ser carregados da memória local")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Tentar Novamente") {
                        viewModel.carregarCanais()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if viewModel.canais.isEmpty && !viewModel.isLoading {
                VStack(spacing: 8) {
                    Image(systemName: "tv.slash")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("Nenhum canal disponível")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.canais) { canal in
                            CanalTileView(
                                canal: canal,
                                isSelected: viewModel.selectedCanal?.id == canal.id,
                                onTap: {
                                    onCanalSelected(canal)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 300)
            }
        }
    }
}
