import SwiftUI

struct VoicemailView: View {
    @EnvironmentObject var store: PhoneStore
    @State private var showingEditor = false
    @State private var playing: VoicemailEntry?

    var body: some View {
        NavigationStack {
            Group {
                if store.voicemails.isEmpty {
                    VStack(spacing: 10) {
                        Text("留守番電話なし")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("右上の＋から追加できます")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List {
                        ForEach(store.voicemails) { vm in
                            Button {
                                store.markVoicemailRead(id: vm.id)
                                playing = vm
                            } label: {
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(vm.isRead ? Color.clear : Color.blue)
                                        .frame(width: 10, height: 10)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(vm.displayName)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                        Text(PhoneFormat.displayNumber(vm.number))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(PhoneFormat.recentTime(vm.date))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        Text(PhoneFormat.duration(vm.durationSec))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { indexSet in
                            for i in indexSet {
                                store.deleteVoicemail(id: store.voicemails[i].id)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("留守番電話")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                VoicemailEditorView()
                    .environmentObject(store)
            }
            .sheet(item: $playing) { vm in
                VoicemailPlayerView(voicemail: vm)
                    .environmentObject(store)
            }
        }
    }
}

/// 留守電の追加フォーム
struct VoicemailEditorView: View {
    @EnvironmentObject var store: PhoneStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var number: String = ""
    @State private var date: Date = Date()
    @State private var minutes: Int = 0
    @State private var seconds: Int = 30

    var body: some View {
        NavigationStack {
            Form {
                Section("相手") {
                    TextField("名前（任意）", text: $name)
                    TextField("電話番号", text: $number)
                        .keyboardType(.phonePad)
                }
                Section("日時") {
                    DatePicker("日時", selection: $date)
                }
                Section("長さ") {
                    Stepper("分：\(minutes)", value: $minutes, in: 0...60)
                    Stepper("秒：\(seconds)", value: $seconds, in: 0...59)
                }
            }
            .navigationTitle("留守番電話を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        store.addVoicemail(VoicemailEntry(
                            name: name.trimmingCharacters(in: .whitespaces),
                            number: number.trimmingCharacters(in: .whitespaces),
                            date: date,
                            durationSec: minutes * 60 + seconds,
                            isRead: false
                        ))
                        dismiss()
                    }
                    .disabled(number.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

/// 再生画面の再現（プログレスバーが進むだけ）
struct VoicemailPlayerView: View {
    @EnvironmentObject var store: PhoneStore
    @Environment(\.dismiss) private var dismiss
    var voicemail: VoicemailEntry

    @State private var isPlaying = false
    @State private var progress: Double = 0

    private let timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 5)
                .padding(.top, 10)

            AvatarView(name: voicemail.name, number: voicemail.number, size: 70)
            Text(voicemail.displayName)
                .font(.title3)
                .fontWeight(.bold)
            Text(PhoneFormat.fullDateTime(voicemail.date))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                ProgressView(value: progress, total: Double(max(1, voicemail.durationSec)))
                HStack {
                    Text(PhoneFormat.duration(Int(progress)))
                    Spacer()
                    Text(PhoneFormat.duration(voicemail.durationSec))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 28)

            Button {
                isPlaying.toggle()
            } label: {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(Color.blue)
            }
            .buttonStyle(.plain)

            Button(role: .destructive) {
                store.deleteVoicemail(id: voicemail.id)
                dismiss()
            } label: {
                Text("削除")
                    .fontWeight(.semibold)
            }
            .padding(.top, 6)

            Spacer()
        }
        .presentationDetents([.medium])
        .onReceive(timer) { _ in
            if isPlaying {
                progress = min(Double(voicemail.durationSec), progress + 0.2)
                if progress >= Double(voicemail.durationSec) {
                    isPlaying = false
                }
            }
        }
    }
}
