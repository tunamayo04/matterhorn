import SwiftUI

struct ContentView: View {
    @State private var selection = 2;

    var body: some View {
        TabView(selection: $selection) {
            CurrentlyReadingView()
                .tabItem {
                    Label("Currently Reading", systemImage: "book")
                }
                .tag(1)

            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
}
