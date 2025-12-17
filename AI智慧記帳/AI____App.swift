import SwiftUI

@main
struct AI智慧記帳App: App {
    @StateObject private var manager = CategoryManager()
    @StateObject private var networkMonitor = NetworkMonitor()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(manager)
                .environmentObject(networkMonitor)
        }
    }
}
