import SwiftUI

@main
struct AI智慧記帳App: App {
    @StateObject private var manager = CategoryManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(manager)
        }
    }
}
