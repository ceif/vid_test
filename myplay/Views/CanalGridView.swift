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
            // Título
            HStack {
                Text("📺 Canais")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal)
            
            if let error = viewModel.errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Tentar Novamente") {
                        viewModel.carregarCanais()
                    }
                    .buttonStyle(.bordered)
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