import SwiftUI

/// 「i」ボタンから開く、相手ごとの詳細（純正電話アプリの詳細画面を再現）
struct CallDetailView: View {
    @EnvironmentObject var store: PhoneStore
    @Environment(\.dismiss) private var dismiss
    var number: String

    @State private var editingEntry: CallEntry?
    @State private var showingActionNote = false
    @State private var showingNameSheet = false
    @State private var historyExpanded = true

    private var entries: [CallEntry] {
        store.entries(forNumber: number)
    }

    private var name: String {
        entries.first(where: { !$0.name.isEmpty })?.name ?? store.name(forNumber: number)
    }

    private var label: String {
        entries.first?.label ?? "携帯電話"
    }

    private var isForeign: Bool { number.hasPrefix("+") }

    private var subtitle: String {
        if name.isEmpty && isForeign { return "不明" }
        return ""
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy/MM/dd"
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private func detailDate(_ date: Date) -> String {
        "\(Self.dayFormatter.string(from: date)) · \(Self.timeFormatter.string(from: date))"
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.38, green: 0.36, blue: 0.50),
                         Color(red: 0.16, green: 0.13, blue: 0.28)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            List {
                // ヘッダー：大きなアバター＋名前（番号）＋アクションボタン
                Section {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.16))
                                .frame(width: 190, height: 190)
                                .overlay(
                                    Circle().stroke(Color.white.opacity(0.25), lineWidth: 1)
                                )
                            if name.isEmpty {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 105))
                                    .foregroundStyle(.white)
                            } else {
                                Text(String(name.prefix(1)))
                                    .font(.system(size: 84, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(.top, 10)

                        Text(name.isEmpty ? PhoneFormat.displayNumber(number) : name)
                            .font(.system(size: 29, weight: .bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        if !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.system(size: 16))
                                .foregroundStyle(.white.opacity(0.85))
                                .padding(.top, -6)
                        }

                        HStack(spacing: 18) {
                            glassActionButton(image: "message.fill", dimmed: false) {
                                showingActionNote = true
                            }
                            glassActionButton(image: "phone.fill", dimmed: false) {
                                store.startCall(name: name, number: number)
                            }
                            glassActionButton(image: "video.fill", dimmed: false) {
                                showingActionNote = true
                            }
                            glassActionButton(image: "envelope.fill", dimmed: true) {
                                showingActionNote = true
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 6)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                // 通話履歴カード
                Section {
                    Button {
                        withAnimation { historyExpanded.toggle() }
                    } label: {
                        HStack {
                            Text("通話履歴")
                                .foregroundStyle(.white)
                            Spacer()
                            Image(systemName: historyExpanded ? "chevron.down" : "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    if historyExpanded {
                        if entries.isEmpty {
                            Text("履歴なし")
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        ForEach(entries) { entry in
                            // 裏コマンド：長押しで編集画面が開く（タップでは開かない）
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.kind.rawValue)
                                        .foregroundStyle(.white)
                                    if entry.kind != .missed && entry.durationSec > 0 {
                                        Text(PhoneFormat.duration(entry.durationSec))
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.6))
                                    }
                                }
                                Spacer()
                                Text(detailDate(entry.date))
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                            .contentShape(Rectangle())
                            .simultaneousGesture(
                                LongPressGesture(minimumDuration: 1.2).onEnded { _ in
                                    editingEntry = entry
                                }
                            )
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.deleteEntry(id: entry.id)
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listRowBackground(Color.white.opacity(0.10))

                // 名前を追加（未登録の番号のみ、純正と同じカード）
                if name.isEmpty {
                    Section {
                        Button {
                            showingNameSheet = true
                        } label: {
                            HStack {
                                Text("名前を追加")
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.10))
                }

                // 番号カード
                Section {
                    Button {
                        store.startCall(name: name, number: number)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(isForeign ? "電話" : label)
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                    Text("最近使った項目")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.white.opacity(0.25), in: Capsule())
                                }
                                Text(PhoneFormat.displayNumber(number))
                                    .foregroundStyle(.white)
                            }
                            Spacer()
                            Image(systemName: "phone.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
                .listRowBackground(Color.white.opacity(0.10))

                Section {
                    Button {
                        store.toggleFavorite(name: name, number: number, label: label)
                    } label: {
                        HStack {
                            Text(store.isFavorite(number: number) ? "よく使う項目から削除" : "よく使う項目に追加")
                                .foregroundStyle(.white)
                            Spacer()
                            Image(systemName: store.isFavorite(number: number) ? "star.fill" : "star")
                                .foregroundStyle(Color.orange)
                        }
                    }
                }
                .listRowBackground(Color.white.opacity(0.10))

                if !entries.isEmpty {
                    Section {
                        Button(role: .destructive) {
                            store.deleteAllEntries(number: number)
                        } label: {
                            Text("この番号の履歴をすべて削除")
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.10))
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .preferredColorScheme(.dark)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white.opacity(0.15)))
                }
            }
        }
        .alert("再現アプリです", isPresented: $showingActionNote) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("このアプリは電話アプリの再現用なので、実際の送信は行われません。")
        }
        .sheet(item: $editingEntry) { entry in
            EntryEditorView(entry: entry, prefillNumber: "")
                .environmentObject(store)
        }
        .sheet(isPresented: $showingNameSheet) {
            NameEntrySheet(number: number)
                .environmentObject(store)
        }
    }

    private func glassActionButton(image: String, dimmed: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.16))
                    .frame(width: 62, height: 62)
                Image(systemName: image)
                    .font(.system(size: 23))
                    .foregroundStyle(.white.opacity(dimmed ? 0.4 : 1.0))
            }
        }
        .buttonStyle(.plain)
    }
}

/// 未登録番号に名前を付けるシート（その番号の履歴すべてに反映）
struct NameEntrySheet: View {
    @EnvironmentObject var store: PhoneStore
    @Environment(\.dismiss) private var dismiss
    var number: String
    @State private var nameText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("名前", text: $nameText)
                } footer: {
                    Text("\(PhoneFormat.displayNumber(number)) の履歴すべてに、この名前が付きます。")
                }
            }
            .navigationTitle("名前を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        store.setName(forNumber: number, name: nameText.trimmingCharacters(in: .whitespaces))
                        dismiss()
                    }
                    .disabled(nameText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
