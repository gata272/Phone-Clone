import SwiftUI

struct KeypadView: View {
    @EnvironmentObject var store: PhoneStore
    @State private var input: String = ""
    @State private var showingEditor = false

    private let keys: [[(String, String)]] = [
        [("1", ""), ("2", "ABC"), ("3", "DEF")],
        [("4", "GHI"), ("5", "JKL"), ("6", "MNO")],
        [("7", "PQRS"), ("8", "TUV"), ("9", "WXYZ")],
        [("*", ""), ("0", "+"), ("#", "")],
    ]

    private var matchedName: String {
        guard !input.isEmpty else { return "" }
        return store.name(forNumber: input)
    }

    var body: some View {
        VStack(spacing: 6) {
            Spacer()

            VStack(spacing: 2) {
                Text(input.isEmpty ? " " : PhoneFormat.displayNumber(input))
                    .font(.system(size: 36, weight: .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if !matchedName.isEmpty {
                    Text(matchedName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(" ")
                        .font(.subheadline)
                }
            }
            .frame(height: 64)

            if !input.isEmpty {
                Button("履歴に追加") {
                    showingEditor = true
                }
                .font(.subheadline)
            } else {
                Text(" ")
                    .font(.subheadline)
            }

            VStack(spacing: 14) {
                ForEach(keys.indices, id: \.self) { rowIndex in
                    HStack(spacing: 22) {
                        ForEach(keys[rowIndex].indices, id: \.self) { keyIndex in
                            let key = keys[rowIndex][keyIndex]
                            Button {
                                input += key.0
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(.secondarySystemBackground))
                                        .frame(width: 74, height: 74)
                                    VStack(spacing: -2) {
                                        Text(key.0)
                                            .font(.system(size: 32, weight: .regular))
                                            .foregroundStyle(.primary)
                                        Text(key.1.isEmpty ? " " : key.1)
                                            .font(.system(size: 9, weight: .semibold))
                                            .foregroundStyle(.secondary)
                                            .tracking(1.5)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .onLongPressGesture {
                                if key.0 == "0", input.hasSuffix("0") {
                                    input = String(input.dropLast()) + "+"
                                }
                            }
                        }
                    }
                }
            }
            .padding(.top, 8)

            HStack(spacing: 22) {
                Color.clear.frame(width: 74, height: 74)
                Button {
                    guard !input.isEmpty else { return }
                    store.startCall(name: matchedName, number: input)
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.20, green: 0.78, blue: 0.35))
                            .frame(width: 74, height: 74)
                        Image(systemName: "phone.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                if !input.isEmpty {
                    Button {
                        input = String(input.dropLast())
                    } label: {
                        Image(systemName: "delete.left")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                            .frame(width: 74, height: 74)
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear.frame(width: 74, height: 74)
                }
            }
            .padding(.top, 4)

            Spacer()
        }
        .padding(.horizontal, 30)
        .sheet(isPresented: $showingEditor) {
            EntryEditorView(entry: nil, prefillNumber: input)
                .environmentObject(store)
        }
    }
}
