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
        let mother = "09046821357"
        let brother = "08059273841"
        let grandma = "0358214963"
        entries = [
            // 今日の夜：+420の同一番号からの迷惑電話（19:50〜20:57、全て不在着信）
            CallEntry(name: "", number: "+420274913556", label: "チェコ", kind: .missed, date: at(0, 20, 57), durationSec: 0),
            CallEntry(name: "", number: "+420274913556", label: "チェコ", kind: .missed, date: at(0, 20, 51), durationSec: 0),
            CallEntry(name: "", number: "+420274913556", label: "チェコ", kind: .missed, date: at(0, 20, 44), durationSec: 0),
            CallEntry(name: "", number: "+420274913556", label: "チェコ", kind: .missed, date: at(0, 20, 38), durationSec: 0),
            CallEntry(name: "", number: "+420274913556", label: "チェコ", kind: .missed, date: at(0, 20, 31), durationSec: 0),
            CallEntry(name: "", number: "+420274913556", label: "チェコ", kind: .missed, date: at(0, 20, 24), durationSec: 0),
            CallEntry(name: "", number: "+420274913556", label: "チェコ", kind: .missed, date: at(0, 20, 19), durationSec: 0),
            CallEntry(name: "", number: "+420274913556", label: "チェコ", kind: .missed, date: at(0, 20, 15), durationSec: 0),
            CallEntry(name: "", number: "+420274913556", label: "チェコ", kind: .missed, date: at(0, 20, 11), durationSec: 0),
            CallEntry(name: "", number: "+420274913556", label: "チェコ", kind: .missed, date: at(0, 20, 7), durationSec: 0),
            CallEntry(name: "", number: "+420274913556", label: "チェコ", kind: .missed, date: at(0, 20, 4), durationSec: 0),
            CallEntry(name: "", number: "+420274913556", label: "チェコ", kind: .missed, date: at(0, 20, 1), durationSec: 0),
            CallEntry(name: "", number: "+420274913556", label: "チェコ", kind: .missed, date: at(0, 19, 58), durationSec: 0),
            CallEntry(name: "", number: "+420274913556", label: "チェコ", kind: .missed, date: at(0, 19, 55), durationSec: 0),
            CallEntry(name: "", number: "+420274913556", label: "チェコ", kind: .missed, date: at(0, 19, 52), durationSec: 0),
            CallEntry(name: "", number: "+420274913556", label: "チェコ", kind: .missed, date: at(0, 19, 50), durationSec: 0),
            // 今日
            CallEntry(name: "", number: "+18005550176", label: "アメリカ合衆国", kind: .missed, date: at(0, 6, 12), durationSec: 0),
            CallEntry(name: "母", number: mother, label: "携帯電話", kind: .outgoing, date: at(0, 9, 5), durationSec: 382),
            // 昨日
            CallEntry(name: "", number: "+12025550147", label: "アメリカ合衆国", kind: .missed, date: at(1, 3, 41), durationSec: 0),
            CallEntry(name: "", number: "+12025550147", label: "アメリカ合衆国", kind: .missed, date: at(1, 14, 22), durationSec: 0),
            CallEntry(name: "", number: "+16465550189", label: "アメリカ合衆国", kind: .incoming, date: at(1, 16, 3), durationSec: 5),
            CallEntry(name: "母", number: mother, label: "携帯電話", kind: .incoming, date: at(1, 20, 18), durationSec: 1181),
            CallEntry(name: "祖母", number: grandma, label: "自宅", kind: .outgoing, date: at(1, 11, 30), durationSec: 271),
            // 2日前
            CallEntry(name: "", number: "+14155550132", label: "アメリカ合衆国", kind: .missed, date: at(2, 10, 54), durationSec: 0),
            CallEntry(name: "", number: "+12425550165", label: "バハマ", kind: .missed, date: at(2, 23, 17), durationSec: 0),
            CallEntry(name: "兄", number: brother, label: "携帯電話", kind: .incoming, date: at(2, 22, 8), durationSec: 679),
            // 3日前
            CallEntry(name: "母", number: mother, label: "携帯電話", kind: .missed, date: at(3, 18, 44), durationSec: 0),
            CallEntry(name: "母", number: mother, label: "携帯電話", kind: .outgoing, date: at(3, 19, 2), durationSec: 1334),
            CallEntry(name: "佐藤 健", number: "08098765432", label: "携帯電話", kind: .missed, date: at(3, 13, 29), durationSec: 0),
            // 4日前
            CallEntry(name: "", number: "+18885550143", label: "アメリカ合衆国", kind: .incoming, date: at(4, 9, 31), durationSec: 12),
            CallEntry(name: "祖母", number: grandma, label: "自宅", kind: .incoming, date: at(4, 14, 5), durationSec: 832),
            // 5日前
            CallEntry(name: "母", number: mother, label: "携帯電話", kind: .incoming, date: at(5, 19, 52), durationSec: 898),
            CallEntry(name: "ヤマト運輸", number: "08034912765", label: "携帯電話", kind: .missed, date: at(5, 12, 20), durationSec: 0),
            CallEntry(name: "ヤマト運輸", number: "08034912765", label: "携帯電話", kind: .incoming, date: at(5, 18, 3), durationSec: 38),
            // 6日前
            CallEntry(name: "", number: "+18765550128", label: "ジャマイカ", kind: .missed, date: at(6, 2, 15), durationSec: 0),
            CallEntry(name: "", number: "+12025550147", label: "アメリカ合衆国", kind: .missed, date: at(6, 15, 47), durationSec: 0),
            CallEntry(name: "田中 美咲", number: "09012345678", label: "携帯電話", kind: .outgoing, date: at(6, 21, 36), durationSec: 97),
            // 7日前
            CallEntry(name: "兄", number: brother, label: "携帯電話", kind: .outgoing, date: at(7, 8, 14), durationSec: 43),
            // 8日前
            CallEntry(name: "母", number: mother, label: "携帯電話", kind: .outgoing, date: at(8, 20, 41), durationSec: 347),
            // 9日前
            CallEntry(name: "", number: "+16465550189", label: "アメリカ合衆国", kind: .missed, date: at(9, 11, 8), durationSec: 0),
            CallEntry(name: "", number: "+16465550189", label: "アメリカ合衆国", kind: .missed, date: at(9, 11, 26), durationSec: 0),
            CallEntry(name: "佐藤 健", number: "08098765432", label: "携帯電話", kind: .incoming, date: at(9, 17, 55), durationSec: 321),
            // 10日前
            CallEntry(name: "祖母", number: grandma, label: "自宅", kind: .incoming, date: at(10, 13, 19), durationSec: 1263),
            // 11日前
            CallEntry(name: "母", number: mother, label: "携帯電話", kind: .incoming, date: at(11, 19, 27), durationSec: 1886),
            // 12日前
            CallEntry(name: "兄", number: brother, label: "携帯電話", kind: .incoming, date: at(12, 23, 4), durationSec: 468),
            CallEntry(name: "駅前歯科", number: "0364298710", label: "その他", kind: .incoming, date: at(12, 10, 12), durationSec: 72),
            // 13日前
            CallEntry(name: "", number: "+12025550147", label: "アメリカ合衆国", kind: .missed, date: at(13, 4, 52), durationSec: 0),
            CallEntry(name: "", number: "+18005550176", label: "アメリカ合衆国", kind: .incoming, date: at(13, 15, 21), durationSec: 7),
            // 14日前
            CallEntry(name: "兄", number: brother, label: "携帯電話", kind: .missed, date: at(14, 21, 33), durationSec: 0),
            // 15日前
            CallEntry(name: "母", number: mother, label: "携帯電話", kind: .outgoing, date: at(15, 12, 48), durationSec: 513),
            // 16日前
            CallEntry(name: "田中 美咲", number: "09012345678", label: "携帯電話", kind: .incoming, date: at(16, 18, 9), durationSec: 524),
            // 17日前
            CallEntry(name: "母", number: mother, label: "携帯電話", kind: .missed, date: at(17, 16, 25), durationSec: 0),
            // 18日前
            CallEntry(name: "祖母", number: grandma, label: "自宅", kind: .outgoing, date: at(18, 10, 37), durationSec: 564),
            // 19日前
            CallEntry(name: "", number: "+14155550132", label: "アメリカ合衆国", kind: .missed, date: at(19, 13, 58), durationSec: 0),
            // 20日前
            CallEntry(name: "兄", number: brother, label: "携帯電話", kind: .outgoing, date: at(20, 19, 44), durationSec: 65),
            // 21日前
            CallEntry(name: "母", number: mother, label: "携帯電話", kind: .incoming, date: at(21, 20, 15), durationSec: 1510),
            // 22日前
            CallEntry(name: "佐藤 健", number: "08098765432", label: "携帯電話", kind: .outgoing, date: at(22, 22, 31), durationSec: 178),
            // 24日前
            CallEntry(name: "母", number: mother, label: "携帯電話", kind: .outgoing, date: at(24, 9, 26), durationSec: 725),
            // 25日前
            CallEntry(name: "祖母", number: grandma, label: "自宅", kind: .incoming, date: at(25, 15, 42), durationSec: 997),
            // 26日前
            CallEntry(name: "", number: "+12025550147", label: "アメリカ合衆国", kind: .missed, date: at(26, 12, 6), durationSec: 0),
            // 27日前
            CallEntry(name: "兄", number: brother, label: "携帯電話", kind: .incoming, date: at(27, 20, 51), durationSec: 192),
            // 28日前
            CallEntry(name: "母", number: mother, label: "携帯電話", kind: .incoming, date: at(28, 19, 13), durationSec: 1124),
        ]
        favorites = [
            FavoriteContact(name: "母", number: mother, label: "携帯電話"),
            FavoriteContact(name: "兄", number: brother, label: "携帯電話"),
            FavoriteContact(name: "祖母", number: grandma, label: "自宅"),
        ]
        voicemails = [
            VoicemailEntry(name: "母", number: mother, date: at(1, 20, 19), durationSec: 42, isRead: false),
            VoicemailEntry(name: "", number: "+12025550147", date: at(2, 3, 15), durationSec: 18, isRead: false),
            VoicemailEntry(name: "佐藤 健", number: "08098765432", date: at(9, 17, 56), durationSec: 24, isRead: true),
        ]
    }
}
