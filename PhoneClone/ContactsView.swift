import SwiftUI

/// 履歴とお気に入りから自動で集めた連絡先一覧
struct ContactsView: View {
    @EnvironmentObject var store: PhoneStore
    @State private var searchText = ""
    @State private var showingEditor = false

    private struct ContactRowData: Identifiable {
        var number: String
        var name: String
        var id: String { number }
    }

    private var contacts: [ContactRowData] {
        var byNumber: [String: String] = [:]
        for e in store.entries where !e.name.isEmpty {
            if byNumber[e.number] == nil {
                byNumber[e.number] = e.name
            }
        }
        for f in store.favorites where !f.name.isEmpty {
            byNumber[f.number] = f.name
        }
        var list = byNumber.map { ContactRowData(number: $0.key, name: $0.value) }
        list.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        if !searchText.isEmpty {
            list = list.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) || $0.number.contains(searchText)
            }
        }
        return list
    }

    var body: some View {
        NavigationStack {
            Group {
                if contacts.isEmpty {
                    VStack(spacing: 10) {
                        Text("連絡先なし")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("履歴に名前付きの相手がいるか、\n右上の＋から追加すると表示されます")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    List(contacts) { contact in
                        NavigationLink {
                            CallDetailView(number: contact.number)
                                .environmentObject(store)
                        } label: {
                            HStack(spacing: 12) {
                                AvatarView(name: contact.name, number: contact.number, size: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(contact.name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    Text(PhoneFormat.displayNumber(contact.number))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("連絡先")
            .searchable(text: $searchText, prompt: "検索")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                FavoriteEditorView(favorite: nil)
                    .environmentObject(store)
            }
        }
    }
}
