import SwiftUI

struct RegisterView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var passwordCheck = ""
    @State private var username = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var isRegistered = false
    @Environment(\.dismiss) var dismiss
    
    
    var body: some View {
        ZStack {
            Color.teal.ignoresSafeArea()
            Circle().scale(1.7).foregroundColor(.white)
            
            VStack(spacing: 16) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left").foregroundColor(.teal).font(.title3).padding(10).background(Color.black.opacity(0.05)).clipShape(Circle())
                    }
                    .padding(.leading)
                    Spacer()
                }
                Text("Register").font(Font.largeTitle.bold()).padding()
                
                TextField("Username", text: $username).padding(10).frame(width: 225, height: 50).background(Color.black.opacity(0.05)).autocapitalization(.none)
                
                TextField("Email", text: $email).padding(10).frame(width: 225, height: 50).background(Color.black.opacity(0.05)).autocapitalization(.none)
                
                SecureField("Password", text: $password).padding(10).frame(width: 225, height: 50).background(Color.black.opacity(0.05))
                                
                SecureField("Confirm password", text: $passwordCheck).padding(10).frame(width: 225, height: 50).background(Color.black.opacity(0.05))
                
                if let error = errorMessage {
                    Text(error).foregroundColor(.red)
                }
                
                Button("Register") {
                    Task { await register() }
                }.foregroundColor(.white).frame(width: 225, height: 50).background(Color.teal).cornerRadius(10)
                NavigationLink(destination: LoginView(), isActive: $isRegistered) {
                    EmptyView()
                }.hidden()

            }
        }.onTapGesture {
            hideKeyboard()
        }
    }
    
    func register() async {
        print("register tapped")
        print("email: \(email), username: \(username), password: \(password)")
        if password != passwordCheck {
            errorMessage = "Passwords don't match."
            print("passwords dont match")
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let response = try await apiRequest.api.register(email: email, password: password, username: username)
            apiRequest.api.saveToken(response.token)
            await MainActor.run {
                dismiss()
            }
            print("registered successfully")
            print("registration successful, dismissing")
        } catch error.emailTaken {
            errorMessage = "This email is already registered."
            print("email taken")
        } catch {
            print("ERROR: \(error)")
            errorMessage = "Something went wrong."
        }
        isLoading = false
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    RegisterView()
}
