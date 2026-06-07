import SwiftUI

struct SchedulingSettings: View {
    var block: Block
    @State private var slots: [String] = []
    @State private var newSlot = ""
    @Environment(\.dismiss) var dismiss
    var storageKey: String { "slots_\(block.id)" }
    
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("e.g. 9:00 AM", text: $newSlot)
                        .padding(10)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(8)
                    
                    Button(action: addSlot) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.teal)
                            .font(.title2)
                    }
                }.padding()
                List {
                    ForEach(slots, id: \.self) { slot in
                        Text(slot)
                    }
                    .onDelete { indexSet in
                        slots.remove(atOffsets: indexSet)
                        Task { await saveSlots() }
                    }
                }
            }
        }.onAppear { Task { await loadSlots() } }
    }
    
    func loadSlots() async {
            if let data = block.config.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let existing = json["slots"] as? [String] {
                slots = existing
            }
        }
        
        func addSlot() {
            let trimmed = newSlot.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { return }
            if slots.contains(trimmed) { return }
            slots.append(trimmed)
            newSlot = ""
            Task { await saveSlots() }
        }
        
        func saveSlots() async {
            let config = "{\"slots\": \(slots)}"
            do {
                _ = try await apiRequest.api.updateBlock(blockId: block.id, config: config)
                print("saved slots: \(slots)")
            } catch {
                print("ERROR saving: \(error)")
            }
        }
}

#Preview {
    SchedulingSettings(block: Block(id: "1", type: "scheduling", config: "{}", bot_id: "1"))
}
