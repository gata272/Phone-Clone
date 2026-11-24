import SwiftUI

@main
struct PhoneCloneApp: App {
    @StateObject private var store = PhoneStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
