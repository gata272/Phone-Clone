import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: PhoneStore

    var body: some View {
        TabView {
            FavoritesView()
                .tabItem {
                    Label("お気に入り", systemImage: "star.fill")
                }

            RecentsView()
                .tabItem {
                    Label("履歴", systemImage: "clock.fill")
                }

            ContactsView()
                .tabItem {
                    Label("連絡先", systemImage: "person.crop.circle.fill")
                }

            KeypadView()
                .tabItem {
                    Label("キーパッド", systemImage: "circle.grid.3x3.fill")
                }

            VoicemailView()
                .tabItem {
                    Label("留守番電話", systemImage: "recordingtape")
                }
                .badge(store.unreadVoicemailCount)
        }
        .fullScreenCover(item: $store.activeCall) { call in
            CallScreenView(call: call)
                .environmentObject(store)
        }
    }
}
