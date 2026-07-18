import AppKit
import Carbon.HIToolbox
import SwiftUI

struct PreferencesView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        TabView {
            GeneralPreferencesView(appState: appState)
                .tabItem {
                    Label("General", systemImage: "switch.2")
                }

            ShortcutsPreferencesView(appState: appState)
                .tabItem {
                    Label("Atajos", systemImage: "command")
                }
        }
        .frame(width: 620, height: 350)
    }
}

private struct GeneralPreferencesView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingsRow(title: "Arranque:") {
                Toggle("Ejecutar PasteVLv al arranque del sistema", isOn: $appState.launchAtLoginEnabled)
            }

            SettingsRow(title: "Integración:") {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Activar Direct Paste", isOn: $appState.directPasteEnabled)
                    Toggle("Pegar siempre como texto plano", isOn: $appState.pastePlainTextByDefault)
                }
            }

            SettingsRow(title: "Otros:") {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Activar efectos de sonido", isOn: $appState.soundEffectsEnabled)
                    Toggle("Mostrar icono de PasteVLv en barra de menú", isOn: $appState.showMenuBarIcon)
                }
            }

            SettingsRow(title: "Capacidad historial:") {
                Picker("", selection: $appState.retentionPolicy) {
                    ForEach(RetentionPolicy.allCases) { policy in
                        Text(policy.shortTitle).tag(policy)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 360)
            }

            HStack {
                Spacer()
                Button("Limpiar historial del portapapeles") {
                    appState.clearHistory()
                }
                Spacer()
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
        VStack(alignment: .leading, spacing: 16) {
            SettingsRow(title: "Activar Paste:") {
                HStack(spacing: 8) {
                    ShortcutRecorder(shortcut: $appState.openShortcut)
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

            SettingsRow(title: "Mostrar siguiente Pinboard:") {
                StaticShortcutField(title: "None")
                    .frame(width: 160)
                    .frame(width: 196, alignment: .leading)
            }

            SettingsRow(title: "Mostrar Pinboard anterior:") {
                StaticShortcutField(title: "None")
                    .frame(width: 160)
                    .frame(width: 196, alignment: .leading)
            }

            SettingsRow(title: "Pegado rápido:") {
                HStack(spacing: 8) {
                    StaticShortcutField(title: "⌘ Command")
                        .frame(width: 126)
                    Text("+ 1..9")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .frame(width: 196, alignment: .leading)
            }

            SettingsRow(title: "Modo texto plano:") {
                StaticShortcutField(title: "⇧ Shift")
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

    func makeNSView(context: Context) -> ShortcutCaptureView {
        let view = ShortcutCaptureView()
        view.onShortcut = { shortcut = $0 }
        view.shortcut = shortcut
        return view
    }

    func updateNSView(_ nsView: ShortcutCaptureView, context: Context) {
        nsView.shortcut = shortcut
    }
}

private final class ShortcutCaptureView: NSView {
    var onShortcut: ((HotKeyShortcut) -> Void)?

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

        let keyName = event.displayKeyName
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

private extension RetentionPolicy {
    var shortTitle: String {
        switch self {
        case .oneDay: return "Día"
        case .oneWeek: return "Semana"
        case .oneMonth: return "Mes"
        case .oneYear: return "Año"
        case .forever: return "Sin límite"
        }
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
    var displayKeyName: String {
        if keyCode == UInt16(kVK_ANSI_Semicolon) {
            return modifierFlags.contains(.shift) ? "Ñ" : "ñ"
        }

        if keyCode == UInt16(kVK_Space) {
            return "Space"
        }

        let value = charactersIgnoringModifiers ?? characters ?? ""
        if value.isEmpty {
            return "Key \(keyCode)"
        }
        return value.uppercased()
    }
}
