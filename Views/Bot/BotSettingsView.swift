import SwiftUI

struct BotSettingsView: View {
    var bot: Bot
    @State private var blocks: [Block] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            Color.teal.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text(bot.bot_name).font(.largeTitle).bold().foregroundColor(.white)
                Divider().background(Color.white)
                Text("Building Blocks").font(.title).bold().foregroundColor(.white)
                HStack(spacing: 12) {
                    Button(action: { Task { await addBlock(type: "scheduling") } }) {
                        
                        VStack(spacing: 8) {
                            Image(systemName: "calendar").font(.title2).foregroundColor(.teal)
                            Text("Scheduling").font(.caption).foregroundColor(.primary)
                        }.frame(maxWidth: .infinity).padding().background(Color.white).cornerRadius(12).shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                    }
                    Button(action: { Task { await addBlock(type: "ordering") } }) {
                        VStack(spacing: 8) {
                            Image(systemName: "cart").font(.title2).foregroundColor(.teal)
                            Text("Ordering").font(.caption).foregroundColor(.primary)
                        }.frame(maxWidth: .infinity).padding().background(Color.white).cornerRadius(12).shadow(color: .gray, radius: 5, x: 0, y: 2)
                    }
                }
                Button("Start Bot") {
                    Task { await startBot() }
                }.foregroundColor(.white).frame(maxWidth: .infinity).padding().background(Color.green.opacity(0.7)).cornerRadius(10).padding(.horizontal)
                NavigationLink(destination: BookingView(bot: bot)) {
                    Text("View Bookings").foregroundColor(.white).frame(maxWidth: .infinity).padding().background(Color.white.opacity(0.2)).cornerRadius(10)
                }.padding(.horizontal)
                if isLoading {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if blocks.isEmpty {
                    Text("No blocks added yet").foregroundColor(.white)
                } else {
                    List {
                        ForEach(blocks) { block in
                            NavigationLink(destination: block.type == "scheduling" ?
                                AnyView(SchedulingSettings(block: block)) :
                                AnyView(OrderingSettings(block: block))
                            ) {
                                HStack {
                                    Image(systemName: block.type == "scheduling" ? "calendar" : "cart")
                                        .foregroundColor(.teal)
                                    Text(block.type.capitalized).font(.headline)
                                    Spacer()
                                }
                            }
                        }.onDelete { indexSet in
                            Task { await deleteBlock(at: indexSet) }
                        }
                    }.listStyle(.insetGrouped)
                }
                if let error = errorMessage {
                    Text(error).foregroundColor(.red)
                }
                Spacer()
            }.padding()
        }.navigationTitle(bot.bot_name).navigationBarTitleDisplayMode(.inline).onAppear {
            Task { await loadBlocks() }
        }
    }
    func loadBlocks() async {
        isLoading = true
        do {
            blocks = try await apiRequest.api.getBlocks(botId: bot.id)
        } catch {
            errorMessage = "Failed to load blocks."
            print("ERROR: \(error)")
        }
        isLoading = false
    }
    
    func addBlock(type: String) async {
        if blocks.contains(where: { $0.type == type }) {
            errorMessage = "\(type.capitalized) block already added."
            return
        }
        do {
            let block = try await apiRequest.api.addBlock(botId: bot.id, blockType: type)
            await MainActor.run { blocks.append(block) }
        } catch {
            errorMessage = "Failed to add block."
            print("ERROR: \(error)")
        }
    }
    
    func deleteBlock(at indexSet: IndexSet) async {
        for index in indexSet {
            let block = blocks[index]
            do {
                try await apiRequest.api.deleteBlock(blockId: block.id)
                await MainActor.run { blocks.remove(at: index) }
            } catch {
                errorMessage = "Failed to delete block."
                print("ERROR: \(error)")
            }
        }
    }
    func startBot() async {
        do {
            _ = try await apiRequest.api.startBot(botId: bot.id)
            print("bot started")
        } catch {
            print("ERROR: \(error)")
        }
    }
}

#Preview {
    BotSettingsView(bot: Bot(id: "1", bot_name: "Test Bot", telegram_token: "test_token", user_id: "1"))
}
