import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var safetyEngine: SafetyEngine
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            ConversationView()
                .tabItem {
                    Label("对话", systemImage: "message")
                }
            
            ResourcesView()
                .tabItem {
                    Label("资源", systemImage: "heart")
                }
            
            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthenticationManager())
            .environmentObject(SafetyEngine())
    }
}