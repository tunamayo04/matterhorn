import SwiftUI

@main
struct ReadingAppApp: App {
    @StateObject private var store = BookStore()

    init() {
        //resetAppData()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}

func resetAppData() {
    let fm = FileManager.default

    // UserDefaults
    if let bundleID = Bundle.main.bundleIdentifier {
        UserDefaults.standard.removePersistentDomain(forName: bundleID)
        UserDefaults.standard.synchronize()
    }

    // Files: Documents, Library/Caches, Application Support, tmp
    let dirs: [URL] = [
        fm.urls(for: .documentDirectory, in: .userDomainMask).first,
        fm.urls(for: .cachesDirectory, in: .userDomainMask).first,
        fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first,
        fm.temporaryDirectory
    ].compactMap { $0 }

    for dir in dirs {
        let contents = (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        for item in contents {
            try? fm.removeItem(at: item)
        }
    }
}
