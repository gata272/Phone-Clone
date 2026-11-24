import Foundation

struct PhoneState: Codable {
    var entries: [CallEntry] = []
    var favorites: [FavoriteContact] = []
    var voicemails: [VoicemailEntry] = []
}

/// 履歴・お気に入り・留守電の状態管理と保存（Documents内のJSON）
@MainActor
final class PhoneStore: ObservableObject {
    @Published private(set) var entries: [CallEntry] = []
    @Published private(set) var favorites: [FavoriteContact] = []
    @Published private(set) var voicemails: [VoicemailEntry] = []
    @Published var activeCall: ActiveCall?

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("phoneclone-state.json")
    }

    init() {
        if let data = try? Data(contentsOf: fileURL),
           let state = try? JSONDecoder().decode(PhoneState.self, from: data) {
            entries = state.entries
            favorites = state.favorites
            voicemails = state.voicemails
        } else {
            seed()
            save()
        }
    }

    private func save() {
        let state = PhoneState(entries: entries, favorites: favorites, voicemails: voicemails)
        if let data = try? JSONEncoder().encode(state) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    // MARK: - 履歴

    func addEntry(_ entry: CallEntry) {
        entries.append(entry)
        entries.sort { $0.date > $1.date }
        save()
    }

    func updateEntry(_ entry: CallEntry) {
        if let i = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[i] = entry
            entries.sort { $0.date > $1.date }
            save()
        }
    }

    func deleteEntry(id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    func deleteEntries(ids: [UUID]) {
        entries.removeAll { ids.contains($0.id) }
        save()
    }

    func deleteAllEntries(number: String) {
        entries.removeAll { $0.number == number }
        save()
    }

    func entries(forNumber number: String) -> [CallEntry] {
        entries.filter { $0.number == number }.sorted { $0.date > $1.date }
    }

    /// 番号から登録名を引く（履歴→お気に入りの順）
    func name(forNumber number: String) -> String {
        if let e = entries.first(where: { $0.number == number && !$0.name.isEmpty }) {
            return e.name
        }
        if let f = favorites.first(where: { $0.number == number }) {
            return f.name
        }
        return ""
    }

    // MARK: - お気に入り

    func addFavorite(_ fav: FavoriteContact) {
        favorites.append(fav)
        save()
    }

    func updateFavorite(_ fav: FavoriteContact) {
        if let i = favorites.firstIndex(where: { $0.id == fav.id }) {
            favorites[i] = fav
            save()
        }
    }

    func deleteFavorite(id: UUID) {
        favorites.removeAll { $0.id == id }
        save()
    }

    func isFavorite(number: String) -> Bool {
        favorites.contains { $0.number == number }
    }

    func toggleFavorite(name: String, number: String, label: String) {
        if let f = favorites.first(where: { $0.number == number }) {
            deleteFavorite(id: f.id)
        } else {
            addFavorite(FavoriteContact(name: name, number: number, label: label))
        }
    }

    // MARK: - 留守番電話

    func addVoicemail(_ vm: VoicemailEntry) {
        voicemails.append(vm)
        voicemails.sort { $0.date > $1.date }
        save()
    }

    func deleteVoicemail(id: UUID) {
        voicemails.removeAll { $0.id == id }
        save()
    }

    func markVoicemailRead(id: UUID) {
        if let i = voicemails.firstIndex(where: { $0.id == id }) {
            voicemails[i].isRead = true
            save()
        }
    }

    var unreadVoicemailCount: Int {
        voicemails.filter { !$0.isRead }.count
    }

    // MARK: - 疑似通話

    func startCall(name: String, number: String) {
        let resolvedName = name.isEmpty ? self.name(forNumber: number) : name
        activeCall = ActiveCall(name: resolvedName, number: number)
    }

    /// 通話終了時に発信履歴として記録する
    func finishCall(_ call: ActiveCall, durationSec: Int) {
        addEntry(CallEntry(
            name: call.name,
            number: call.number,
            label: "携帯電話",
            kind: .outgoing,
            date: Date(),
            durationSec: durationSec
        ))
        activeCall = nil
    }

    // MARK: - 初回サンプルデータ

    private func seed() {
        let cal = Calendar.current
        func at(_ daysAgo: Int, _ h: Int, _ m: Int) -> Date {
            let base = cal.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            return cal.date(bySettingHour: h, minute: m, second: 0, of: base) ?? base
        }
        entries = [
            CallEntry(name: "田中 美咲", number: "09012345678", label: "携帯電話", kind: .incoming, date: at(0, 10, 24), durationSec: 192),
            CallEntry(name: "佐藤 健", number: "08098765432", label: "携帯電話", kind: .missed, date: at(0, 8, 3), durationSec: 0),
            CallEntry(name: "母", number: "09055550123", label: "携帯電話", kind: .outgoing, date: at(1, 21, 47), durationSec: 725),
            CallEntry(name: "", number: "07033334444", label: "携帯電話", kind: .missed, date: at(1, 13, 15), durationSec: 0),
            CallEntry(name: "株式会社サンプル", number: "0312345678", label: "勤務先", kind: .incoming, date: at(2, 15, 30), durationSec: 64),
            CallEntry(name: "田中 美咲", number: "09012345678", label: "携帯電話", kind: .outgoing, date: at(3, 19, 2), durationSec: 41),
            CallEntry(name: "鈴木 翔太", number: "09077778888", label: "携帯電話", kind: .incoming, date: at(4, 12, 40), durationSec: 358),
        ]
        favorites = [
            FavoriteContact(name: "母", number: "09055550123", label: "携帯電話"),
            FavoriteContact(name: "田中 美咲", number: "09012345678", label: "携帯電話"),
        ]
        voicemails = [
            VoicemailEntry(name: "佐藤 健", number: "08098765432", date: at(0, 8, 3), durationSec: 24, isRead: false),
        ]
    }
}
