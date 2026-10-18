import SwiftUI

struct SettingsView: View {
    @State private var selectedTheme: Int = 0
    @State private var selectedViewMode: ViewMode = .continuous
    @State private var selectedFontFamilyGroup1: String = "Klee One"
    @State private var selectedFontFamilyGroup2: String = "Noto Sans JP"
    @State private var selectedFontSize: Double = 26.0

    enum ViewMode: String, CaseIterable, Identifiable {
        case continuous, paginated
        var id: Self { self }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section{
                    HStack(alignment: .center) {
                        ThemeButton(index: 0, isSelected: selectedTheme == 0, bg: .readerBgLight, fg: .black) { selectedTheme = 0 }
                        Spacer()
                        ThemeButton(index: 1, isSelected: selectedTheme == 1, bg: .readerBgWarm, fg: .black) { selectedTheme = 1 }
                        Spacer()
                        ThemeButton(index: 2, isSelected: selectedTheme == 2, bg: .readerBgCold, fg: .black) { selectedTheme = 2 }
                        Spacer()
                        ThemeButton(index: 3, isSelected: selectedTheme == 3, bg: .readerBgDark, fg: .white) { selectedTheme = 3 }
                        Spacer()
                        ThemeButton(index: 4, isSelected: selectedTheme == 4, bg: .readerBgVeryDark, fg: .white) { selectedTheme = 4 }
                        Spacer()
                        ThemeButton(index: 5, isSelected: selectedTheme == 5, bg: .readerBgBlack, fg: .white) { selectedTheme = 5 }
                    }
                } header: {
                    Text("Theme")
                }
                
                Section {
                    Picker("ViewMode", selection: $selectedViewMode) {
                        ForEach(ViewMode.allCases) {
                            viewMode in Text(viewMode.rawValue.capitalized)
                        }
                    }.pickerStyle(.segmented)
                } header: {
                    Text("View Mode")
                }
                
                Section {
                    NavigationLink(destination: Text("Font Family (Group 1) Selection")) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Font Family (Group 1)")
                                    .font(.body)
                                Text(selectedFontFamilyGroup1)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    NavigationLink(destination: Text("Font Family (Group 2) Selection")) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Font Family (Group 2)")
                                    .font(.body)
                                Text(selectedFontFamilyGroup2)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Typography")
                }
                
                Section {
                    HStack(spacing: 36) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Font Size")
                                .font(.body)
                            Text(String(format: "%.0f", selectedFontSize))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $selectedFontSize, in: 14...36, step: 1) {
                            Text("test")
                        } minimumValueLabel: {
                            Text("A").font(.system(size: 16))
                        } maximumValueLabel: {
                            Text("A").font(.system(size: 24))
                        }
                    }
                } header: {
                    Text("Display")
                }
            }
        }
    }
}

struct ThemeButton: View {
    let index: Int
    let isSelected: Bool
    let bg: Color
    let fg: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("ぁあ")
                .frame(width: 44, height: 44)
                .background(bg)
                .foregroundColor(fg)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.65), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
}
