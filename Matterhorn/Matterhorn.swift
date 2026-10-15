import SwiftUI

@main
struct ReadingAppApp: App {
    @StateObject private var store = BookStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
