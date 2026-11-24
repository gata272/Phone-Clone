import SwiftUI

/// 名前から色とイニシャルを決める、連絡先アバター風の丸アイコン
struct AvatarView: View {
    var name: String
    var number: String
    var size: CGFloat = 46

    private static let palette: [Color] = [
        Color(red: 0.98, green: 0.45, blue: 0.35),
        Color(red: 0.98, green: 0.65, blue: 0.25),
        Color(red: 0.35, green: 0.78, blue: 0.45),
        Color(red: 0.25, green: 0.65, blue: 0.95),
        Color(red: 0.60, green: 0.45, blue: 0.95),
        Color(red: 0.95, green: 0.45, blue: 0.65),
        Color(red: 0.30, green: 0.75, blue: 0.75),
        Color(red: 0.55, green: 0.55, blue: 0.60),
    ]

    private var initial: String {
        let source = name.isEmpty ? number : name
        return String(source.prefix(1))
    }

    private var color: Color {
        let source = name.isEmpty ? number : name
        let sum = source.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return Self.palette[abs(sum) % Self.palette.count]
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.72)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            Text(initial)
                .font(.system(size: size * 0.44, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

/// 通話画面などで使う丸ボタン
struct RoundButton: View {
    var systemImage: String
    var label: String
    var active: Bool = false

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(active ? Color.white : Color.white.opacity(0.22))
                    .frame(width: 62, height: 62)
                Image(systemName: systemImage)
                    .font(.system(size: 24))
                    .foregroundStyle(active ? Color.black : Color.white)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white)
        }
        .frame(width: 76)
    }
}
