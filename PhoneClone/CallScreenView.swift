import SwiftUI

/// 疑似通話画面（終了すると発信履歴に記録される）
struct CallScreenView: View {
    @EnvironmentObject var store: PhoneStore
    var call: ActiveCall

    @State private var startedAt = Date()
    @State private var elapsed: Int = 0
    @State private var muted = false
    @State private var speaker = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var connected: Bool { elapsed >= 2 }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.16, green: 0.17, blue: 0.20), Color(red: 0.05, green: 0.05, blue: 0.07)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 54)

                AvatarView(name: call.name, number: call.number, size: 96)

                Text(call.displayName)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
                    .padding(.horizontal, 24)

                Text(connected ? PhoneFormat.duration(elapsed - 2) : "発信中…")
                    .font(.system(size: 17))
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.top, 6)

                Spacer()

                VStack(spacing: 18) {
                    HStack(spacing: 18) {
                        Button { muted.toggle() } label: {
                            RoundButton(systemImage: "mic.slash.fill", label: "消音", active: muted)
                        }
                        .buttonStyle(.plain)
                        RoundButton(systemImage: "circle.grid.3x3.fill", label: "キーパッド")
                        Button { speaker.toggle() } label: {
                            RoundButton(systemImage: "speaker.wave.3.fill", label: "スピーカー", active: speaker)
                        }
                        .buttonStyle(.plain)
                    }
                    HStack(spacing: 18) {
                        RoundButton(systemImage: "plus", label: "通話を追加")
                        RoundButton(systemImage: "video.fill", label: "FaceTime")
                        RoundButton(systemImage: "person.crop.circle", label: "連絡先")
                    }
                }
                .padding(.bottom, 34)

                Button {
                    store.finishCall(call, durationSec: connected ? elapsed - 2 : 0)
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.96, green: 0.26, blue: 0.21))
                            .frame(width: 70, height: 70)
                        Image(systemName: "phone.down.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .padding(.bottom, 46)
            }
        }
        .onReceive(timer) { _ in
            elapsed = Int(Date().timeIntervalSince(startedAt))
        }
    }
}
