import AppKit
import Carbon.HIToolbox
import SwiftUI

struct PreferencesView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        TabView {
            GeneralPreferencesView(appState: appState)
                .tabItem {
                    Label(AppCopy(language: appState.appLanguage).general, systemImage: "switch.2")
                }

            ShortcutsPreferencesView(appState: appState)
                .tabItem {
                    Label(AppCopy(language: appState.appLanguage).shortcuts, systemImage: "command")
                }

            AboutView(language: appState.appLanguage)
                .tabItem {
                    Label(AppCopy(language: appState.appLanguage).aboutTab, systemImage: "info.circle")
                }
        }
        .frame(width: 620, height: 460)
    }
}

struct AboutView: View {
    let language: AppLanguage

    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                AppIcon()
                    .frame(width: 76, height: 76)

                Text(AppBranding.displayName)
                    .font(.system(size: 25, weight: .medium))

                Text("\(copy.version) \(AppBranding.version) (\(AppBranding.build))")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Divider()
                .padding(.vertical, 24)
                .padding(.horizontal, 52)

            VStack(spacing: 18) {
                Text("\(copy.createdBy) VlV")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                HStack(spacing: 30) {
                    AboutLink(title: copy.developerGitHub, systemImage: "person.crop.circle", url: AppBranding.developerURL)
                    AboutLink(title: copy.projectGitHub, systemImage: "chevron.left.forwardslash.chevron.right", url: AppBranding.projectURL)
                }
            }

            Spacer(minLength: 24)

            VStack(spacing: 7) {
                Text(copy.license)
                    .font(.system(size: 12, weight: .medium))
                Text(copy.copyright)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.top, 34)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct AppIcon: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(red: 0.18, green: 0.58, blue: 0.98), Color(red: 0.27, green: 0.20, blue: 0.79)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Image(systemName: "doc.on.clipboard.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .shadow(color: .black.opacity(0.16), radius: 7, y: 3)
    }
}

private struct AboutLink: View {
    let title: String
    let systemImage: String
    let url: URL

    var body: some View {
        Link(destination: url) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 25, weight: .medium))
                    .frame(width: 52, height: 52)
                    .overlay {
                        Circle()
                            .stroke(Color.accentColor.opacity(0.55), lineWidth: 1)
                    }
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(width: 104)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct GeneralPreferencesView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        let copy = AppCopy(language: appState.appLanguage)
        VStack(alignment: .leading, spacing: 18) {
            SettingsRow(title: copy.languageLabel) {
                Picker("", selection: $appState.appLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text("\(language.flag) \(language.pickerTitle)").tag(language)
                    }
                }
                .labelsHidden()
                .frame(width: 180, alignment: .leading)
            }

            SettingsRow(title: copy.launch) {
                Toggle(copy.launchAtLogin, isOn: $appState.launchAtLoginEnabled)
            }

            SettingsRow(title: copy.integration) {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(copy.enableDirectPaste, isOn: $appState.directPasteEnabled)
                    Toggle(copy.pastePlainText, isOn: $appState.pastePlainTextByDefault)
                }
            }

            SettingsRow(title: copy.other) {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(copy.enableSounds, isOn: $appState.soundEffectsEnabled)
                    Toggle(copy.showMenuBarIcon, isOn: $appState.showMenuBarIcon)
                }
            }

            SettingsRow(title: copy.historyRetention) {
                Picker("", selection: $appState.retentionPolicy) {
                    ForEach(RetentionPolicy.allCases) { policy in
                        Text(copy.retentionTitle(for: policy)).tag(policy)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 360)
            }

            HStack {
                Spacer()
                Button(copy.clearHistory) {
                    appState.clearHistory()
                }
                Spacer()
            }

            SettingsRow(title: copy.jsonBackup) {
                HStack(spacing: 10) {
                    Button(copy.exportGroups) {
                        appState.exportHistoryInteractively()
                    }
                    Button(copy.importGroups) {
                        appState.importHistoryInteractively()
                    }
                }
            }

            Spacer()
        }
        .toggleStyle(.checkbox)
        .padding(.top, 22)
        .padding(.horizontal, 34)
        .padding(.bottom, 18)
    }
}

private struct ShortcutsPreferencesView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        let copy = AppCopy(language: appState.appLanguage)
        VStack(alignment: .leading, spacing: 16) {
            SettingsRow(title: copy.activatePaste) {
                HStack(spacing: 8) {
                    ShortcutRecorder(shortcut: $appState.openShortcut, language: appState.appLanguage)
                        .frame(width: 160, height: 28)

                    Button {
                        appState.openShortcut = .defaultOpen
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.borderless)
                    .frame(width: 28, height: 28)
                }
                .frame(width: 196, alignment: .leading)
            }

            SettingsRow(title: copy.nextPinboard) {
                StaticShortcutField(title: copy.none)
                    .frame(width: 160)
                    .frame(width: 196, alignment: .leading)
            }

            SettingsRow(title: copy.previousPinboard) {
                StaticShortcutField(title: copy.none)
                    .frame(width: 160)
                    .frame(width: 196, alignment: .leading)
            }

            SettingsRow(title: copy.quickPaste) {
                HStack(spacing: 8) {
                    StaticShortcutField(title: copy.command)
                        .frame(width: 126)
                    Text("+ 1..9")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .frame(width: 196, alignment: .leading)
            }

            SettingsRow(title: copy.plainTextMode) {
                StaticShortcutField(title: copy.shift)
                    .frame(width: 126)
                    .frame(width: 196, alignment: .leading)
            }

            Spacer()
        }
        .padding(.top, 26)
        .padding(.horizontal, 54)
        .padding(.bottom, 18)
    }
}

private struct SettingsRow<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: 190, alignment: .trailing)
            content
                .frame(minWidth: 220, alignment: .leading)
        }
    }
}

private struct StaticShortcutField: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.primary)
            .frame(height: 26)
            .frame(maxWidth: .infinity)
            .background(Color(nsColor: .textBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

private struct ShortcutRecorder: NSViewRepresentable {
    @Binding var shortcut: HotKeyShortcut
    let language: AppLanguage

    func makeNSView(context: Context) -> ShortcutCaptureView {
        let view = ShortcutCaptureView()
        view.onShortcut = { shortcut = $0 }
        view.shortcut = shortcut
        view.language = language
        return view
    }

    func updateNSView(_ nsView: ShortcutCaptureView, context: Context) {
        nsView.shortcut = shortcut
        nsView.language = language
    }
}

private final class ShortcutCaptureView: NSView {
    var onShortcut: ((HotKeyShortcut) -> Void)?
    var language: AppLanguage = .english

    var shortcut: HotKeyShortcut = .defaultOpen {
        didSet {
            label.stringValue = shortcut.displayName
        }
    }

    private let label = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        layer?.cornerRadius = 4
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.borderWidth = 1

        label.alignment = .center
        label.font = .systemFont(ofSize: 13)
        label.textColor = .labelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }

    override func becomeFirstResponder() -> Bool {
        layer?.borderColor = NSColor.controlAccentColor.cgColor
        return true
    }

    override func resignFirstResponder() -> Bool {
        layer?.borderColor = NSColor.separatorColor.cgColor
        return true
    }

    override func keyDown(with event: NSEvent) {
        guard event.keyCode != UInt16(kVK_Escape) else {
            window?.makeFirstResponder(nil)
            return
        }

        let modifiers = event.modifierFlags.carbonHotKeyModifiers
        guard modifiers != 0 else { return }

        let keyName = event.displayKeyName(language: language)
        let displayName = event.modifierFlags.shortcutPrefix + keyName
        onShortcut?(
            HotKeyShortcut(
                keyCode: UInt32(event.keyCode),
                modifiers: modifiers,
                displayName: displayName
            )
        )
    }
}

private extension NSEvent.ModifierFlags {
    var carbonHotKeyModifiers: UInt32 {
        var modifiers: UInt32 = 0
        if contains(.command) { modifiers |= UInt32(cmdKey) }
        if contains(.shift) { modifiers |= UInt32(shiftKey) }
        if contains(.option) { modifiers |= UInt32(optionKey) }
        if contains(.control) { modifiers |= UInt32(controlKey) }
        return modifiers
    }

    var shortcutPrefix: String {
        var value = ""
        if contains(.control) { value += "⌃" }
        if contains(.option) { value += "⌥" }
        if contains(.shift) { value += "⇧" }
        if contains(.command) { value += "⌘" }
        return value
    }
}

private extension NSEvent {
    func displayKeyName(language: AppLanguage) -> String {
        if keyCode == UInt16(kVK_ANSI_Semicolon) {
            return modifierFlags.contains(.shift) ? "Ñ" : "ñ"
        }

        if keyCode == UInt16(kVK_Space) {
            return language == .english ? "Space" : "Espacio"
        }

        let value = charactersIgnoringModifiers ?? characters ?? ""
        if value.isEmpty {
            return "Key \(keyCode)"
        }
        return value.uppercased()
    }
}
