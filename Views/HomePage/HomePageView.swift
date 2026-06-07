import SwiftUI

struct HomePageView: View {
    @State private var bots: [Bot] = []
    @State private var isLoading = false
    @State private var showCreateBot = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            Color.teal.ignoresSafeArea()
            VStack {
                ZStack{
                    Text("My Bots").font(.largeTitle).bold().foregroundColor(.white).padding()
                    HStack {
                        Spacer()
                        Button(action: { showCreateBot = true }) {
                            Image(systemName: "plus.circle.fill").foregroundColor(.white).font(.title).padding()
                        }
                    }
                }
                
                if isLoading {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                
                if let error = errorMessage {
                    Text(error).foregroundColor(.red).padding()
                }
                
                if bots.isEmpty && !isLoading {
                    Text("No bots yet").foregroundColor(.white)
                    Text("Tap + to create your first bot").foregroundColor(.white).font(.caption)
                    Spacer()
                } else {
                    List {
                        ForEach(bots) { bot in
                            NavigationLink(destination: BotSettingsView(bot: bot)) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(bot.bot_name).font(.headline)
                                    }
                                    Spacer()
                                }.padding(.vertical, 4)
                            }
                        }.onDelete
                        { indexSet in
                            Task {
                                await deleteBot(at: indexSet)
                            }
                        }
                    }.listStyle(.insetGrouped)
                }
            }
        }.navigationBarBackButtonHidden(true).sheet(isPresented: $showCreateBot, onDismiss: {
            Task { await loadBots() }
        })
        {
            BotCreateView()
        }.onAppear {
            Task { await loadBots() }
        }
    }
    
    func loadBots() async {
        isLoading = true
        errorMessage = nil
        do {
            bots = try await apiRequest.api.getBots()
        } catch {
            errorMessage = "Failed to load bots."
            print("ERROR LOADING BOTS: \(error)")
        }
        isLoading = false
    }
    
    func deleteBot(at indexSet: IndexSet) async {
        for index in indexSet {
            let bot = bots[index]
            do {
                try await apiRequest.api.deleteBot(botId: bot.id)
                await MainActor.run {
                    bots.remove(at: index)
                }
            } catch {
                errorMessage = "Failed to delete bot."
                print("ERROR: \(error)")
            }
        }
    }
}

#Preview {
    HomePageView()
}
