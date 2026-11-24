import SwiftUI

/// 履歴1件の追加・編集フォーム
struct EntryEditorView: View {
    @EnvironmentObject var store: PhoneStore
    @Environment(\.dismiss) private var dismiss

    var entry: CallEntry?
    var prefillNumber: String = ""

    @State private var name: String = ""
    @State private var number: String = ""
    @State private var label: String = "携帯電話"
    @State private var kind: CallKind = .incoming
    @State private var date: Date = Date()
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0

    private var labels: [String] {
        var base = ["携帯電話", "自宅", "勤務先", "その他"]
        if !base.contains(label) {
            base.append(label)
        }
        return base
    }

    var body: some View {
        NavigationStack {
            Form {
                if !store.favorites.isEmpty {
                    Section("お気に入りから選ぶ") {
                        ForEach(store.favorites) { fav in
                            Button {
                                name = fav.name
                                number = fav.number
                                label = fav.label
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(fav.name.isEmpty ? PhoneFormat.displayNumber(fav.number) : fav.name)
                                            .foregroundStyle(.primary)
                                        Text("\(fav.label) \(PhoneFormat.displayNumber(fav.number))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if number == fav.number {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.blue)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Section("相手") {
                    TextField("名前（任意）", text: $name)
                    TextField("電話番号", text: $number)
                        .keyboardType(.phonePad)
                    Picker("ラベル", selection: $label) {
                        ForEach(labels, id: \.self) { l in
                            Text(l).tag(l)
                        }
                    }
                }
                Section("種類") {
                    Picker("種類", selection: $kind) {
                        ForEach(CallKind.allCases) { k in
                            Text(k.rawValue).tag(k)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("日時") {
                    DatePicker("日時", selection: $date)
                }
                if kind != .missed {
                    Section("通話時間") {
                        Stepper("分：\(minutes)", value: $minutes, in: 0...600)
                        Stepper("秒：\(seconds)", value: $seconds, in: 0...59)
                    }
                }
            }
            .navigationTitle(entry == nil ? "履歴を追加" : "履歴を編集")
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
                if let e = entry {
                    name = e.name
                    number = e.number
                    label = e.label
                    kind = e.kind
                    date = e.date
                    minutes = e.durationSec / 60
                    seconds = e.durationSec % 60
                } else if !prefillNumber.isEmpty {
                    number = prefillNumber
                }
            }
        }
    }

    private func save() {
        let duration = kind == .missed ? 0 : minutes * 60 + seconds
        if var e = entry {
            e.name = name.trimmingCharacters(in: .whitespaces)
            e.number = number.trimmingCharacters(in: .whitespaces)
            e.label = label
            e.kind = kind
            e.date = date
            e.durationSec = duration
            store.updateEntry(e)
        } else {
            store.addEntry(CallEntry(
                name: name.trimmingCharacters(in: .whitespaces),
                number: number.trimmingCharacters(in: .whitespaces),
                label: label,
                kind: kind,
                date: date,
                durationSec: duration
            ))
        }
        dismiss()
    }
}
