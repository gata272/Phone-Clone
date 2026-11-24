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

    private var groups: [CallGroup] {
        let sorted = store.entries
            .filter { !filterMissed || $0.kind.isMissed }
            .sorted { $0.date > $1.date }
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
            VStack(spacing: 0) {
                Picker("表示", selection: $filterMissed) {
                    Text("すべて").tag(false)
                    Text("不在着信").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                // 裏コマンド：この切り替えを長押しすると履歴の追加画面が開く
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 1.2).onEnded { _ in
                        showingEditor = true
                    }
                )

                if groups.isEmpty {
                    Spacer()
                    Text("履歴なし")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Spacer()
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingEditor) {
                EntryEditorView(entry: nil, prefillNumber: "")
                    .environmentObject(store)
            }
        }
    }
}

/// 履歴の1行（純正風レイアウト）
struct RecentRow: View {
    @EnvironmentObject var store: PhoneStore
    var group: CallGroup

    private var entry: CallEntry { group.entry }

    var body: some View {
        HStack(spacing: 8) {
            // 発信マーク（幅をそろえるため発信時だけ表示）
            Group {
                if entry.kind == .outgoing {
                    Image(systemName: "phone.arrow.up.right")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                } else {
                    Color.clear
                }
            }
            .frame(width: 18)

            Button {
                store.startCall(name: entry.name, number: entry.number)
            } label: {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
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
                        Text(entry.name.isEmpty ? entry.label : "\(entry.label) \(PhoneFormat.displayNumber(entry.number))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
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
                Image(systemName: "info.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.blue)
            }
            .buttonStyle(.plain)
            .frame(width: 30)
        }
        .padding(.vertical, 2)
    }
}
