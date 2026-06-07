import SwiftUI

struct BotCreateView: View {
    @State private var botName = ""
    @State private var telegramToken = ""
    @State private var errorMessage: String? = nil
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextField("Bot name", text: $botName).padding(10).frame(width: 300, height: 50).background(Color.black.opacity(0.05)).cornerRadius(8)
                
                TextField("Telegram token", text: $telegramToken).padding(10).frame(width: 300, height: 50).background(Color.black.opacity(0.05)).cornerRadius(8).autocapitalization(.none)
                if let error = errorMessage {
                    Text(error).foregroundColor(.red)
                }
                Button("Create Bot") {
                    Task { await createBot() }
                }.foregroundColor(.white).frame(width: 300, height: 50).background(isLoading ? Color.gray : Color.teal).cornerRadius(10).disabled(isLoading)
                if isLoading {
                    ProgressView()
                }
            }.navigationTitle("Create Bot").navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    func createBot() async {
        if botName.isEmpty {
            errorMessage = "Please enter a bot name."
            return
        }
        if telegramToken.isEmpty {
            errorMessage = "Please enter a Telegram token."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            _ = try await apiRequest.api.createBot(botName: botName, telegramToken: telegramToken)
            await MainActor.run {
                dismiss()
            }
        } catch {
            errorMessage = "Failed to create bot."
            print("ERROR: \(error)")
        }
        isLoading = false
    }
}

#Preview {
    BotCreateView()
}
