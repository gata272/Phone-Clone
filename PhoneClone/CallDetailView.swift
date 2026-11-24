import SwiftUI

/// 「i」ボタンから開く、相手ごとの履歴詳細（純正風）
struct CallDetailView: View {
    @EnvironmentObject var store: PhoneStore
    var number: String

    @State private var editingEntry: CallEntry?
    @State private var showingActionNote = false

    private var entries: [CallEntry] {
        store.entries(forNumber: number)
    }

    private var name: String {
        entries.first(where: { !$0.name.isEmpty })?.name ?? store.name(forNumber: number)
    }

    private var label: String {
        entries.first?.label ?? "携帯電話"
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 10) {
                    AvatarView(name: name, number: number, size: 76)
                    Text(name.isEmpty ? PhoneFormat.displayNumber(number) : name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    if !name.isEmpty {
                        Text(PhoneFormat.displayNumber(number))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 22) {
                        detailActionButton(image: "message.fill", text: "メッセージ") {
                            showingActionNote = true
                        }
                        detailActionButton(image: "phone.fill", text: "発信") {
                            store.startCall(name: name, number: number)
                        }
                        detailActionButton(image: "video.fill", text: "ビデオ") {
                            showingActionNote = true
                        }
                        detailActionButton(image: "envelope.fill", text: "メール") {
                            showingActionNote = true
                        }
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }

            Section {
                Button {
                    store.toggleFavorite(name: name, number: number, label: label)
                } label: {
                    HStack {
                        Text(store.isFavorite(number: number) ? "お気に入りから削除" : "お気に入りに追加")
                        Spacer()
                        Image(systemName: store.isFavorite(number: number) ? "star.fill" : "star")
                            .foregroundStyle(Color.orange)
                    }
                }
            }

            Section("履歴") {
                if entries.isEmpty {
                    Text("履歴なし")
                        .foregroundStyle(.secondary)
                }
                ForEach(entries) { entry in
                    // 裏コマンド：長押しで編集画面が開く（タップでは開かない）
                    Group {
                        HStack(spacing: 10) {
                            Image(systemName: entry.kind == .outgoing ? "phone.arrow.up.right" : (entry.kind.isMissed ? "phone.down.fill" : "phone.fill"))
                                .font(.system(size: 13))
                                .foregroundStyle(entry.kind.isMissed ? Color.red : Color.secondary)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(PhoneFormat.fullDateTime(entry.date))
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                Text(entry.kind.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(entry.kind.isMissed ? Color.red : Color.secondary)
                            }
                            Spacer()
                            if entry.kind != .missed {
                                Text(PhoneFormat.duration(entry.durationSec))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 1.2).onEnded { _ in
                            editingEntry = entry
                        }
                    )
                }
                .onDelete { indexSet in
                    for i in indexSet {
                        store.deleteEntry(id: entries[i].id)
                    }
                }
            }

            if !entries.isEmpty {
                Section {
                    Button(role: .destructive) {
                        store.deleteAllEntries(number: number)
                    } label: {
                        Text("この番号の履歴をすべて削除")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(name.isEmpty ? PhoneFormat.displayNumber(number) : name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("再現アプリです", isPresented: $showingActionNote) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("このアプリは電話アプリの再現用なので、実際の送信は行われません。")
        }
        .sheet(item: $editingEntry) { entry in
            EntryEditorView(entry: entry, prefillNumber: "")
                .environmentObject(store)
        }
    }

    private func detailActionButton(image: String, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(Color(.secondarySystemGroupedBackground))
                        .frame(width: 50, height: 50)
                    Image(systemName: image)
                        .font(.system(size: 19))
                        .foregroundStyle(Color.blue)
                }
                Text(text)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
