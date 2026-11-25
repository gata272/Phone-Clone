import SwiftUI

/// 連続する同じ相手の履歴をまとめた表示用グループ（純正電話アプリの挙動）
struct CallGroup: Identifiable {
    var entry: CallEntry
    var count: Int
    var ids: [UUID]

    var id: UUID { entry.id }
}

struct RecentsView: View {
    @EnvironmentObject var store: PhoneStore
    @State private var filterMissed = false
    @State private var showingEditor = false
    @State private var searchText = ""
    @State private var showingDeleteAllConfirm = false

    private var groups: [CallGroup] {
        var sorted = store.entries
            .filter { !filterMissed || $0.kind.isMissed }
            .sorted { $0.date > $1.date }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            sorted = sorted.filter {
                $0.name.lowercased().contains(q) || $0.number.contains(q)
            }
        }
        var result: [CallGroup] = []
        for entry in sorted {
            if var last = result.last,
               last.entry.number == entry.number,
               last.entry.name == entry.name,
               last.entry.kind.isMissed == entry.kind.isMissed {
                last.count += 1
                last.ids.append(entry.id)
                result[result.count - 1] = last
            } else {
                result.append(CallGroup(entry: entry, count: 1, ids: [entry.id]))
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            Group {
                if groups.isEmpty {
                    VStack(spacing: 10) {
                        Spacer()
                        Text("履歴なし")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    List {
                        ForEach(groups) { group in
                            RecentRow(group: group)
                        }
                        .onDelete { indexSet in
                            let ids = indexSet.flatMap { groups[$0].ids }
                            store.deleteEntries(ids: ids)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("履歴")
            .searchable(text: $searchText, prompt: "検索")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .principal) {
                    Picker("表示", selection: $filterMissed) {
                        Text("すべて").tag(false)
                        Text("不在着信").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 230)
                    // 裏コマンド：この切り替えを長押しすると履歴の追加画面が開く
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 1.2).onEnded { _ in
                            showingEditor = true
                        }
                    )
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            showingDeleteAllConfirm = true
                        } label: {
                            Label("履歴をすべて削除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                }
            }
            .confirmationDialog("履歴をすべて削除しますか？", isPresented: $showingDeleteAllConfirm, titleVisibility: .visible) {
                Button("すべて削除", role: .destructive) {
                    store.deleteAllRecents()
                }
                Button("キャンセル", role: .cancel) {}
            }
            .sheet(isPresented: $showingEditor) {
                EntryEditorView(entry: nil, prefillNumber: "")
                    .environmentObject(store)
            }
        }
    }
}

/// 履歴の1行（純正風レイアウト：アバター＋名前＋矢印と通話種別）
struct RecentRow: View {
    @EnvironmentObject var store: PhoneStore
    var group: CallGroup

    private var entry: CallEntry { group.entry }

    /// 純正の2行目表記：海外番号は「不明」、国内は「電話」
    private var sourceText: String {
        entry.number.hasPrefix("+") ? "不明" : "電話"
    }

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(name: entry.name, number: entry.number, size: 52)

            Button {
                store.startCall(name: entry.name, number: entry.number)
            } label: {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Text(entry.displayName)
                                .font(.headline)
                                .foregroundStyle(entry.kind.isMissed ? Color.red : Color.primary)
                                .lineLimit(1)
                            if group.count > 1 {
                                Text("(\(group.count))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        HStack(spacing: 3) {
                            Image(systemName: entry.kind == .outgoing ? "arrow.up.right" : "arrow.down.left")
                                .font(.system(size: 10, weight: .semibold))
                            Text(sourceText)
                                .font(.subheadline)
                        }
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(PhoneFormat.recentTime(entry.date))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            NavigationLink {
                CallDetailView(number: entry.number)
                    .environmentObject(store)
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 44, height: 44)
                    Image(systemName: "info")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.blue)
                }
            }
            .buttonStyle(.plain)
            .frame(width: 44)
        }
        .padding(.vertical, 3)
    }
}
