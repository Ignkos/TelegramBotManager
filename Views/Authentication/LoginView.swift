import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String? = nil
    @State private var isLoading = false
    @State private var isLoggedIn = false
    @State private var showRegister = false
    
    
    var body: some View {
        ZStack{
            Color.teal.ignoresSafeArea()
            Circle().scale(1.7).foregroundColor(.white)
            VStack{
                Text("Login").font(Font.largeTitle.bold()).padding()
                TextField("Username", text: $email).padding().frame(width: 300,height: 50).background(Color.black.opacity(0.05)).autocapitalization(.none).cornerRadius(8)
                
                SecureField("Password", text: $password).padding().frame(width: 300,height: 50).background(Color.black.opacity(0.05)).autocapitalization(.none).cornerRadius(8)
                
                
                Button("Login"){
                    Task{
                        await authentication()
                    }
                }.foregroundColor(Color.white).frame(width: 300,height: 50).background(Color.teal).cornerRadius(10)
                
                Button("Don't have an account? \nSign up") {
                    showRegister = true
                }
                .fullScreenCover(isPresented: $showRegister) {
                    RegisterView()
                }
                
                if let error = errorMessage{
                    Text(error).foregroundColor(.red).padding()
                }
                NavigationLink(destination: HomePageView(), isActive: $isLoggedIn) {
                        EmptyView()
                }.hidden()
            }
        }
    }
    func authentication() async{
        print("login called with email: \(email)")
        isLoading = true
        errorMessage = nil
        do {
            print("sending request...")
            let response = try await apiRequest.api.login(email: email, password:password)
            apiRequest.api.saveToken(response.token)
            await MainActor.run {
                print("setting isLoggedIn to true")
                isLoggedIn = true
                print("isLoggedIn is now: \(isLoggedIn)")
            }
        } catch error.invalidCredentials {
            errorMessage = "Invalid email or password."
        } catch {
            print("ERROR: \(error)")
            errorMessage = "Something went wrong."
        }
        isLoading = false
    }
}




#Preview {
    LoginView()
}
