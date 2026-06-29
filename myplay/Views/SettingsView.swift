import SwiftUI

struct SettingsView: View {
    // MARK: - Configurações
    @AppStorage("canaisURL") private var canaisURL = "http://myney/canais.json"
    @AppStorage("certificateURL") private var certificateURL = ""
    @AppStorage("licenseURL") private var licenseURL = ""
    @AppStorage("authToken") private var authToken = ""
    @Environment(\.dismiss) private var dismiss
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                // ✅ SECÇÃO: URL dos Canais
                Section("📡 URL dos Canais") {
                    TextField("URL do JSON dos canais", text: $canaisURL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .disableAutocorrection(true)
                    
                    Text("Exemplo: http://meuservidor.com/canais.json")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // ✅ SECÇÃO: Configurações DRM
                Section("🔐 Configurações DRM") {
                    TextField("URL do Certificado", text: $certificateURL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .disableAutocorrection(true)
                    
                    TextField("URL da Licença", text: $licenseURL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .disableAutocorrection(true)
                    
                    SecureField("Token de Autenticação", text: $authToken)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                // ✅ SECÇÃO: Informação
                Section("ℹ️ Informação") {
                    HStack {
                        Text("Versão da App")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("iOS")
                        Spacer()
                        Text(UIDevice.current.systemVersion)
                            .foregroundColor(.secondary)
                    }
                }
                
                // ✅ SECÇÃO: Ações
                Section {
                    Button("Restaurar Padrões") {
                        canaisURL = "http://myney/canais.json"
                        certificateURL = ""
                        licenseURL = ""
                        authToken = ""
                        showAlert = true
                        alertMessage = "Configurações restauradas para os valores padrão"
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("⚙️ Definições")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") {
                        dismiss()
                    }
                }
            }
            .alert("Info", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
}
