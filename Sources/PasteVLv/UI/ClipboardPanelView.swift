import SwiftUI
import UniformTypeIdentifiers

struct ClipboardPanelView: View {
    @ObservedObject var appState: AppState
    let onPaste: (ClipboardItem, Bool) -> Void
    let onClose: () -> Void

    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()

            HStack(spacing: 0) {
                pinboardSidebar
                Divider()
                timeline
            }
        }
        .frame(minWidth: 920, idealWidth: 1080, minHeight: 420, idealHeight: 520)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            isSearchFocused = true
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 18, weight: .semibold))

            TextField("Search copied text, links, images, files, or apps", text: $appState.searchText)
                .textFieldStyle(.roundedBorder)
                .focused($isSearchFocused)

            Picker("", selection: $appState.retentionPolicy) {
                ForEach(RetentionPolicy.allCases) { policy in
                    Text(policy.title).tag(policy)
                }
            }
            .labelsHidden()
            .frame(width: 130)

            Button {
                appState.isCapturePaused.toggle()
            } label: {
                Label(appState.isCapturePaused ? "Resume" : "Pause", systemImage: appState.isCapturePaused ? "play.fill" : "pause.fill")
            }

            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
            }
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(14)
    }

    private var pinboardSidebar: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                appState.select(pinboardID: nil)
            } label: {
                SidebarRow(
                    title: "History",
                    systemImage: "clock.arrow.circlepath",
                    colorHex: "#475569",
                    isSelected: appState.selectedPinboardID == nil
                )
            }
            .buttonStyle(.plain)

            Text("Pinboards")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            ForEach(appState.pinboards) { pinboard in
                Button {
                    appState.select(pinboardID: pinboard.id)
                } label: {
                    SidebarRow(
                        title: pinboard.name,
                        systemImage: "tray.full",
                        colorHex: pinboard.colorHex,
                        isSelected: appState.selectedPinboardID == pinboard.id
                    )
                }
                .buttonStyle(.plain)
                .onDrop(of: [UTType.text], isTargeted: nil) { providers in
                    guard let provider = providers.first else { return false }
                    provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
                        let value = item as? Data
                        let idString = value.flatMap { String(data: $0, encoding: .utf8) } ?? item as? String
                        guard let idString, let id = UUID(uuidString: idString) else { return }
                        Task { @MainActor in
                            appState.assign(itemID: id, to: pinboard.id)
                        }
                    }
                    return true
                }
            }

            HStack {
                TextField("New group", text: $appState.newPinboardName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        appState.createPinboard()
                    }

                Button {
                    appState.createPinboard()
                } label: {
                    Image(systemName: "plus")
                }
            }
            .padding(.top, 6)

            Spacer()

            Button {
                appState.toggleCurrentAppExclusion()
            } label: {
                Label("Toggle current app privacy", systemImage: "eye.slash")
            }
            .font(.caption)

            Text(appState.isCapturePaused ? "Capture paused" : "Capturing from clipboard")
                .font(.caption)
                .foregroundStyle(appState.isCapturePaused ? .orange : .secondary)
        }
        .padding(14)
        .frame(width: 230)
    }

    private var timeline: some View {
        VStack(spacing: 0) {
            if appState.items.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(appState.items.enumerated()), id: \.element.id) { index, item in
                            ClipboardItemRow(
                                item: item,
                                index: index,
                                onPaste: { onPaste(item, false) },
                                onPastePlain: { onPaste(item, true) },
                                onFavorite: { appState.toggleFavorite(itemID: item.id) },
                                onPin: { appState.togglePinned(itemID: item.id) },
                                onDelete: { appState.delete(itemID: item.id) }
                            )
                            .onDrag {
                                NSItemProvider(object: item.id.uuidString as NSString)
                            }
                            .quickPasteShortcut(index: index)
                        }
                    }
                    .padding(14)
                }
            }

            Divider()
            footer
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clipboard")
                .font(.system(size: 42))
                .foregroundStyle(.secondary)
            Text("Copy something to start building history")
                .font(.headline)
            Text("Text, links, files, and images appear here automatically.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack {
            Text("Shift-Cmd-V opens PasteVLv")
            Spacer()
            Text("Return pastes, Shift-Return pastes plain text, Cmd-1...9 quick pastes")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

private struct SidebarRow: View {
    let title: String
    let systemImage: String
    let colorHex: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(Color(hex: colorHex))
                .frame(width: 18)
            Text(title)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.14) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ClipboardItemRow: View {
    let item: ClipboardItem
    let index: Int
    let onPaste: () -> Void
    let onPastePlain: () -> Void
    let onFavorite: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            kindBadge

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(item.preview)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(2)
                    Spacer()
                    Text(item.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    if let source = item.sourceAppName {
                        Label(source, systemImage: "app")
                    }

                    if let pinboardID = item.pinboardID {
                        Label(String(pinboardID.uuidString.prefix(8)), systemImage: "tray.full")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                Button(action: onFavorite) {
                    Image(systemName: item.isFavorite ? "star.fill" : "star")
                }
                Button(action: onPin) {
                    Image(systemName: item.isPinned ? "pin.fill" : "pin")
                }
                Button(action: onPastePlain) {
                    Image(systemName: "textformat")
                }
                .disabled(item.kind == .image || item.kind == .file)
                Button(action: onPaste) {
                    Image(systemName: "arrow.turn.down.left")
                }
                .keyboardShortcut(.return, modifiers: [])
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
            }
            .buttonStyle(.borderless)
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var kindBadge: some View {
        VStack(spacing: 4) {
            Text(index < 9 ? "\(index + 1)" : "")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(kindColor)
        }
        .frame(width: 44)
    }

    private var iconName: String {
        switch item.kind {
        case .text: return "text.alignleft"
        case .link: return "link"
        case .image: return "photo"
        case .file: return "doc"
        }
    }

    private var kindColor: Color {
        switch item.kind {
        case .text: return .blue
        case .link: return .green
        case .image: return .orange
        case .file: return .purple
        }
    }
}

private extension Color {
    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&value)

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}

private struct QuickPasteShortcut: ViewModifier {
    let index: Int

    @ViewBuilder
    func body(content: Content) -> some View {
        if index < 9 {
            content.keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
        } else {
            content
        }
    }
}

private extension View {
    func quickPasteShortcut(index: Int) -> some View {
        modifier(QuickPasteShortcut(index: index))
    }
}
