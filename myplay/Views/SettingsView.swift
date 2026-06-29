import SwiftUI

struct SettingsView: View {
    @AppStorage("certificateURL") private var certificateURL = ""
    @AppStorage("licenseURL") private var licenseURL = ""
    @AppStorage("authToken") private var authToken = ""
    @Environment(\.dismiss) private var dismiss
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Configurações DRM") {
                    TextField("URL do Certificado", text: $certificateURL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                    
                    TextField("URL da Licença", text: $licenseURL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                    
                    SecureField("Token de Autenticação", text: $authToken)
                        .autocapitalization(.none)
                }
                
                Section("Informação") {
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
                
                Section {
                    Button("Restaurar Padrões") {
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