import SwiftUI

@main
struct AiMindSupportApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var safetyEngine = SafetyEngine()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(safetyEngine)
        }
    }
}