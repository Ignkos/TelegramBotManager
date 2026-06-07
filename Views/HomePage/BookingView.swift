import SwiftUI

struct BookingView: View {
    var bot: Bot
    @State private var bookings: [Booking] = []
    @State private var isLoading = false
    
    var body: some View {
        List {
            ForEach(bookings) { booking in
                HStack {
                    VStack(alignment: .leading) {
                        Text(booking.name).font(.headline)
                        Text(booking.selection).font(.caption).foregroundColor(.gray)
                        Text(booking.type == "scheduling" ? "Appointment" : "Order").font(.caption2).foregroundColor(.teal)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle").foregroundColor(.gray).font(.title2).onTapGesture {
                            Task {
                                do {
                                    try await apiRequest.api.deleteBooking(bookingId: booking.id)
                                    await MainActor.run {
                                        bookings.removeAll { $0.id == booking.id }
                                    }
                                } catch {
                                    print("ERROR: \(error)")
                                }
                            }
                        }
                }.padding(.vertical, 4)
            }
        }.navigationTitle("Bookings").onAppear {
            Task { await loadBookings() }
        }.overlay {
            if isLoading {
                ProgressView()
            } else if bookings.isEmpty {
                Text("No bookings yet").foregroundColor(.gray)
            }
        }
    }
    
    func loadBookings() async {
        isLoading = true
        do {
            bookings = try await apiRequest.api.getBookings(botId: bot.id)
        } catch {
            print("ERROR: \(error)")
        }
        isLoading = false
    }
}

#Preview {
    BookingView(bot: Bot(id: "1", bot_name: "Test Bot", telegram_token: "test_token", user_id: "1"))
}
