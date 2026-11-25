import SwiftUI

/// 純正風の連絡先アバター（ダークグレーの丸に頭文字、未登録は人物シルエット）
struct AvatarView: View {
    var name: String
    var number: String
    var size: CGFloat = 46

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.40, green: 0.41, blue: 0.47),
                                 Color(red: 0.23, green: 0.24, blue: 0.29)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            if name.isEmpty {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.52))
                    .foregroundStyle(.white)
            } else {
                Text(String(name.prefix(1)))
                    .font(.system(size: size * 0.44, weight: .semibold))
                    .foregroundStyle(.white)
            }
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
