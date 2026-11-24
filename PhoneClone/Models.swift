import Foundation

// MARK: - 通話の種類

enum CallKind: String, Codable, CaseIterable, Identifiable {
    case incoming = "着信"
    case outgoing = "発信"
    case missed = "不在着信"

    var id: String { rawValue }
    var isMissed: Bool { self == .missed }
}

// MARK: - 履歴1件

struct CallEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String = ""           // 空なら番号のみの相手
    var number: String = ""
    var label: String = "携帯電話"   // 携帯電話／自宅／勤務先／その他
    var kind: CallKind = .incoming
    var date: Date = Date()
    var durationSec: Int = 0        // 不在着信は0

    var displayName: String {
        name.isEmpty ? PhoneFormat.displayNumber(number) : name
    }
}

// MARK: - お気に入り

struct FavoriteContact: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String = ""
    var number: String = ""
    var label: String = "携帯電話"
}

// MARK: - 留守番電話

struct VoicemailEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String = ""
    var number: String = ""
    var date: Date = Date()
    var durationSec: Int = 60
    var isRead: Bool = false

    var displayName: String {
        name.isEmpty ? PhoneFormat.displayNumber(number) : name
    }
}

// MARK: - 疑似通話

struct ActiveCall: Identifiable {
    let id = UUID()
    var name: String
    var number: String

    var displayName: String {
        name.isEmpty ? PhoneFormat.displayNumber(number) : name
    }
}

// MARK: - 表示フォーマット

enum PhoneFormat {
    /// 番号を見やすい形に整える（数字だけの国内番号のみ自動整形）
    static func displayNumber(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        let digits = trimmed.filter { $0.isNumber }
        // 北米番号（+1）は純正と同じ +1(866) 165-1359 形式で表示
        if trimmed.hasPrefix("+1"), digits.count == 11 {
            let area = digits.dropFirst(1).prefix(3)
            let mid = digits.dropFirst(4).prefix(3)
            let last = digits.dropFirst(7)
            return "+1(\(area)) \(mid)-\(last)"
        }
        // チェコ（+420）・スロバキア（+421）は3桁ずつ区切る
        if (trimmed.hasPrefix("+420") || trimmed.hasPrefix("+421")), digits.count == 12 {
            let cc = digits.prefix(3)
            let a = digits.dropFirst(3).prefix(3)
            let b = digits.dropFirst(6).prefix(3)
            let c = digits.dropFirst(9)
            return "+\(cc) \(a) \(b) \(c)"
        }
        // リヒテンシュタイン（+423）
        if trimmed.hasPrefix("+423"), digits.count == 10 {
            let a = digits.dropFirst(3).prefix(3)
            let b = digits.dropFirst(6).prefix(2)
            let c = digits.dropFirst(8)
            return "+423 \(a) \(b) \(c)"
        }
        guard digits.count == trimmed.count else { return trimmed }
        if digits.count == 11 {
            let a = digits.prefix(3)
            let b = digits.dropFirst(3).prefix(4)
            let c = digits.dropFirst(7)
            return "\(a)-\(b)-\(c)"
        }
        if digits.count == 10 {
            let a = digits.prefix(2)
            let b = digits.dropFirst(2).prefix(4)
            let c = digits.dropFirst(6)
            return "\(a)-\(b)-\(c)"
        }
        return trimmed
    }

    /// 0:00 / 12:34 / 1:02:33 形式
    static func duration(_ sec: Int) -> String {
        let s = max(0, sec)
        let h = s / 3600
        let m = (s % 3600) / 60
        let r = s % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, r)
        }
        return String(format: "%d:%02d", m, r)
    }

    /// 3分25秒 / 45秒 形式
    static func durationText(_ sec: Int) -> String {
        let s = max(0, sec)
        let h = s / 3600
        let m = (s % 3600) / 60
        let r = s % 60
        if h > 0 {
            return "\(h)時間\(m)分\(r)秒"
        }
        if m > 0 {
            return "\(m)分\(r)秒"
        }
        return "\(r)秒"
    }

    /// 履歴一覧の右側に出る、純正風の相対時刻
    static func recentTime(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let f = DateFormatter()
            f.locale = Locale(identifier: "ja_JP")
            f.dateFormat = "H:mm"
            return f.string(from: date)
        }
        if cal.isDateInYesterday(date) {
            return "昨日"
        }
        if let days = cal.dateComponents([.day], from: date, to: Date()).day, days < 7 {
            let f = DateFormatter()
            f.locale = Locale(identifier: "ja_JP")
            f.dateFormat = "EEEE"
            return f.string(from: date)
        }
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy/M/d"
        return f.string(from: date)
    }

    /// 詳細画面用の日時
    static func fullDateTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy/M/d(EEE) H:mm"
        return f.string(from: date)
    }
}
