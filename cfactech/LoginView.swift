//
//  LoginView.swift
//  cfactech
//
//  Created by Yeurys Lora on 2/10/25.
//




import SwiftUI
import Combine
import Foundation
struct LoginView: View {
    @EnvironmentObject var loginManager: LoginManager
    
    // State variables for login inputs and feedback
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // App logo or placeholder
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(.top, 50)
                
                // Username input
                CustomTextField("Username", text: $username)
                    .accessibility(label: Text("Username input field"))
                
                // Password input
                CustomSecureField("Password", text: $password)
                    .accessibility(label: Text("Password input field"))
                
                // Login button
                Button(action: login) {
                    if isLoading {
                        ProgressView()
                            .accessibility(label: Text("Logging in..."))
                    } else {
                        Text("Login")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(8)
                            .accessibility(label: Text("Login button"))
                    }
                }
                .disabled(isLoading)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Login Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onTapGesture {
                // Dismiss the keyboard when tapping outside
                hideKeyboard()
            }
        }
    }
    
    private func login() {
        guard !username.isEmpty, !password.isEmpty else {
            alertMessage = "Please enter both username and password."
            showAlert = true
            return
        }
        
        isLoading = true
        loginManager.login(username: username, password: password) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success:
                    print("Login successful!")
                case .failure(let error):
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
}

// MARK: - Custom TextField
struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    
    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .autocapitalization(.none)
            .disableAutocorrection(true)
    }
}

// MARK: - Custom SecureField
struct CustomSecureField: View {
    var placeholder: String
    @Binding var text: String
    
    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }
    
    var body: some View {
        SecureField(placeholder, text: $text)
            .padding()
            .textFieldStyle(RoundedBorderTextFieldStyle())
    }
}

// MARK: - Keyboard Dismissal Extension
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        let mockLoginManager = LoginManager() // Create an instance of LoginManager
        LoginView()
            .environmentObject(mockLoginManager) // Inject the environment object
    }
}
