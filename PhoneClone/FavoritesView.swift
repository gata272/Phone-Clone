import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var store: PhoneStore
    @State private var showingEditor = false
    @State private var editingFavorite: FavoriteContact?

    var body: some View {
        NavigationStack {
            Group {
                if store.favorites.isEmpty {
                    VStack(spacing: 10) {
                        Text("お気に入りなし")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("右上の＋から追加できます")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List {
                        ForEach(store.favorites) { fav in
                            HStack(spacing: 12) {
                                Button {
                                    store.startCall(name: fav.name, number: fav.number)
                                } label: {
                                    HStack(spacing: 12) {
                                        AvatarView(name: fav.name, number: fav.number, size: 44)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(fav.name.isEmpty ? PhoneFormat.displayNumber(fav.number) : fav.name)
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                                .lineLimit(1)
                                            HStack(spacing: 4) {
                                                Image(systemName: "phone.fill")
                                                    .font(.system(size: 10))
                                                Text(fav.label)
                                                    .font(.subheadline)
                                            }
                                            .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                Button {
                                    editingFavorite = fav
                                } label: {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 20))
                                        .foregroundStyle(Color.blue)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 2)
                        }
                        .onDelete { indexSet in
                            for i in indexSet {
                                store.deleteFavorite(id: store.favorites[i].id)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("よく使う項目")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
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
            .sheet(item: $editingFavorite) { fav in
                FavoriteEditorView(favorite: fav)
                    .environmentObject(store)
            }
        }
    }
}

/// お気に入りの追加・編集フォーム
struct FavoriteEditorView: View {
    @EnvironmentObject var store: PhoneStore
    @Environment(\.dismiss) private var dismiss

    var favorite: FavoriteContact?

    @State private var name: String = ""
    @State private var number: String = ""
    @State private var label: String = "携帯電話"

    private let labels = ["携帯電話", "自宅", "勤務先", "その他"]

    var body: some View {
        NavigationStack {
            Form {
                TextField("名前", text: $name)
                TextField("電話番号", text: $number)
                    .keyboardType(.phonePad)
                Picker("ラベル", selection: $label) {
                    ForEach(labels, id: \.self) { l in
                        Text(l).tag(l)
                    }
                }
            }
            .navigationTitle(favorite == nil ? "お気に入りを追加" : "お気に入りを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(number.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let f = favorite {
                    name = f.name
                    number = f.number
                    label = f.label
                }
            }
        }
    }

    private func save() {
        if var f = favorite {
            f.name = name.trimmingCharacters(in: .whitespaces)
            f.number = number.trimmingCharacters(in: .whitespaces)
            f.label = label
            store.updateFavorite(f)
        } else {
            store.addFavorite(FavoriteContact(
                name: name.trimmingCharacters(in: .whitespaces),
                number: number.trimmingCharacters(in: .whitespaces),
                label: label
            ))
        }
        dismiss()
    }
}
