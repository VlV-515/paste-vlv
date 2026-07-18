import AppKit
import SwiftUI
import UniformTypeIdentifiers

private let pinboardPalette = [
    "#F85B5B",
    "#F59E0B",
    "#FACC15",
    "#63D957",
    "#38BDF8",
    "#C084FC",
    "#94A3B8"
]

struct ClipboardPanelView: View {
    @ObservedObject var appState: AppState
    let onPaste: (ClipboardItem, Bool) -> Void
    let onClose: () -> Void
    let onOpenPreferences: () -> Void

    @FocusState private var isSearchFocused: Bool
    @State private var isAddingPinboard = false
    @State private var editingPinboard: Pinboard?
    @State private var newPinboardName = ""
    @State private var newPinboardColor = pinboardPalette[0]

    var body: some View {
        VStack(spacing: 0) {
            topBar
            content
        }
        .frame(minWidth: 980, idealWidth: 1180, minHeight: 330, idealHeight: 360)
        .background(panelBackground)
        .sheet(isPresented: $isAddingPinboard) {
            PinboardEditorView(
                title: "Nuevo grupo",
                name: $newPinboardName,
                colorHex: $newPinboardColor,
                primaryTitle: "Crear",
                onCancel: resetNewPinboard,
                onSave: {
                    appState.createPinboard(name: newPinboardName, colorHex: newPinboardColor)
                    resetNewPinboard()
                }
            )
        }
        .sheet(item: $editingPinboard) { pinboard in
            PinboardEditSheet(pinboard: pinboard, appState: appState)
        }
        .onAppear {
            focusSearchField()
        }
        .onChange(of: appState.panelPresentationID) { _ in
            focusSearchField()
        }
        .background(
            KeyDownMonitor { event in
                handleKeyDown(event)
            }
        )
    }

    private var topBar: some View {
        ZStack {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.white.opacity(0.62))
                    TextField("", text: $appState.searchText, prompt: Text("Buscar").foregroundColor(.white.opacity(0.42)))
                        .textFieldStyle(.plain)
                        .focused($isSearchFocused)
                        .foregroundStyle(.white)
                        .frame(width: 160)
                }

                Spacer()

                Menu {
                    Button("Preferencias...") {
                        onOpenPreferences()
                    }
                    Divider()
                    Button(appState.isCapturePaused ? "Reanudar captura" : "Pausar captura") {
                        appState.isCapturePaused.toggle()
                    }
                    Button("Cerrar") {
                        onClose()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.78))
                }
                .menuStyle(.borderlessButton)
            }

            HStack(spacing: 18) {
                PinboardTab(
                    title: "Clipboard History",
                    colorHex: "#C7CDD8",
                    isSelected: appState.selectedPinboardID == nil,
                    onSelect: { appState.select(pinboardID: nil) }
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 18) {
                        ForEach(appState.pinboards) { pinboard in
                            PinboardTab(
                                title: pinboard.name,
                                colorHex: pinboard.colorHex,
                                isSelected: appState.selectedPinboardID == pinboard.id,
                                onSelect: { appState.select(pinboardID: pinboard.id) }
                            )
                            .contextMenu {
                                Button("Renombrar") {
                                    editingPinboard = pinboard
                                }
                                Button(role: .destructive) {
                                    appState.delete(pinboardID: pinboard.id)
                                } label: {
                                    Text("Eliminar")
                                }
                                Divider()
                                ForEach(pinboardPalette, id: \.self) { colorHex in
                                    Button {
                                        appState.update(pinboardID: pinboard.id, name: pinboard.name, colorHex: colorHex)
                                    } label: {
                                        Label(colorName(colorHex), systemImage: pinboard.colorHex == colorHex ? "checkmark.circle.fill" : "circle.fill")
                                    }
                                }
                            }
                            .onDrop(of: [UTType.text], isTargeted: nil) { providers in
                                assignDroppedItem(providers: providers, to: pinboard.id)
                            }
                        }
                    }
                }
                .frame(maxWidth: 520)

                Button {
                    isAddingPinboard = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.68))
                .help("Agregar grupo")
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 18)
    }

    private var content: some View {
        Group {
            if appState.items.isEmpty {
                emptyState
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .top, spacing: 20) {
                            ForEach(Array(appState.items.enumerated()), id: \.element.id) { index, item in
                                ClipboardCard(
                                    item: item,
                                    index: index,
                                    accentHex: appState.colorHex(for: item),
                                    pinboardName: appState.pinboardName(for: item),
                                    pinboards: appState.pinboards,
                                    isSelected: appState.selectedItemID == item.id,
                                    onSelect: { appState.selectItem(id: item.id) },
                                    onPaste: { onPaste(item, false) },
                                    onPastePlain: { onPaste(item, true) },
                                    onFavorite: { appState.toggleFavorite(itemID: item.id) },
                                    onPin: { appState.togglePinned(itemID: item.id) },
                                    onDelete: { appState.delete(itemID: item.id) },
                                    onAssign: { appState.assign(itemID: item.id, to: $0) }
                                )
                                .id(item.id)
                                .onDrag {
                                    NSItemProvider(object: item.id.uuidString as NSString)
                                }
                                .quickPasteShortcut(index: index)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 18)
                    }
                    .onAppear {
                        scrollSelection(into: proxy)
                    }
                    .onChange(of: appState.selectedItemID) { _ in
                        scrollSelection(into: proxy)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "clipboard")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.46))
            Text("Copia algo para iniciar el historial")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.82))
            Text(appState.openShortcut.displayName + " abre " + AppBranding.displayName)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.52))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 36)
    }

    private var panelBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.12, green: 0.16, blue: 0.23),
                Color(red: 0.10, green: 0.14, blue: 0.20),
                Color(red: 0.18, green: 0.25, blue: 0.42)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func assignDroppedItem(providers: [NSItemProvider], to pinboardID: UUID) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
            let value = item as? Data
            let idString = value.flatMap { String(data: $0, encoding: .utf8) } ?? item as? String
            guard let idString, let id = UUID(uuidString: idString) else { return }
            Task { @MainActor in
                appState.assign(itemID: id, to: pinboardID)
            }
        }
        return true
    }

    private func resetNewPinboard() {
        newPinboardName = ""
        newPinboardColor = pinboardPalette[0]
        isAddingPinboard = false
    }

    private func focusSearchField() {
        DispatchQueue.main.async {
            isSearchFocused = true
        }
    }

    private func scrollSelection(into proxy: ScrollViewProxy) {
        guard let selectedItemID = appState.selectedItemID else { return }
        withAnimation(.easeInOut(duration: 0.14)) {
            proxy.scrollTo(selectedItemID, anchor: .center)
        }
    }

    private func handleKeyDown(_ event: NSEvent) -> Bool {
        guard editingPinboard == nil, !isAddingPinboard else { return false }
        let modifiers = event.modifierFlags.intersection([.shift, .control, .option, .command])

        switch event.keyCode {
        case 123 where modifiers.isEmpty:
            appState.moveSelection(offset: -1)
            return true
        case 124 where modifiers.isEmpty:
            appState.moveSelection(offset: 1)
            return true
        case 36, 76:
            guard modifiers.isEmpty || modifiers == [.shift],
                  let selectedItem = appState.selectedItem else {
                return false
            }
            onPaste(selectedItem, modifiers == [.shift])
            return true
        default:
            return false
        }
    }
}

private struct PinboardTab: View {
    let title: String
    let colorHex: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 7) {
                Circle()
                    .fill(Color(hex: colorHex))
                    .frame(width: 12, height: 12)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? Color(red: 0.17, green: 0.18, blue: 0.21) : .white.opacity(0.9))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? Color.white.opacity(0.78) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct ClipboardCard: View {
    let item: ClipboardItem
    let index: Int
    let accentHex: String
    let pinboardName: String?
    let pinboards: [Pinboard]
    let isSelected: Bool
    let onSelect: () -> Void
    let onPaste: () -> Void
    let onPastePlain: () -> Void
    let onFavorite: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void
    let onAssign: (UUID?) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            previewArea
            footer
        }
        .frame(width: 280, height: 286)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(
                    isSelected ? Color.white.opacity(0.96) : Color(hex: accentHex).opacity(item.pinboardID == nil ? 0.16 : 0.9),
                    lineWidth: isSelected ? 4 : (item.pinboardID == nil ? 1 : 3)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(Color(hex: accentHex).opacity(isSelected ? 0.94 : 0), lineWidth: 2)
                .padding(3)
        )
        .shadow(color: isSelected ? Color.white.opacity(0.16) : .black.opacity(0.22), radius: isSelected ? 14 : 8, y: 3)
        .scaleEffect(isSelected ? 1.018 : 1)
        .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .onTapGesture {
            onSelect()
        }
        .onTapGesture(count: 2, perform: onPaste)
        .contextMenu {
            Button("Pegar") { onPaste() }
            Button("Pegar como texto plano") { onPastePlain() }
                .disabled(item.kind == .image || item.kind == .file)
            Divider()
            Button(item.isFavorite ? "Quitar favorito" : "Favorito") { onFavorite() }
            Button(item.isPinned ? "Desfijar" : "Fijar") { onPin() }
            Menu("Mover a grupo") {
                Button("Sin grupo") { onAssign(nil) }
                ForEach(pinboards) { pinboard in
                    Button(pinboard.name) { onAssign(pinboard.id) }
                }
            }
            Divider()
            Button(role: .destructive) {
                onDelete()
            } label: {
                Text("Eliminar")
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.kind.displayTitle)
                    .font(.system(size: 21, weight: .medium))
                    .lineLimit(1)
                Text(item.createdAt, style: .relative)
                    .font(.system(size: 12, weight: .medium))
                    .opacity(0.85)
            }
            Spacer()
            sourceIcon
        }
        .foregroundStyle(.white)
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .padding(.top, 10)
        .frame(height: 62)
        .background(Color(hex: accentHex))
    }

    @ViewBuilder
    private var sourceIcon: some View {
        if item.kind == .file {
            Image(systemName: "folder.fill")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.62))
                .offset(y: 8)
        } else if item.sourceAppName?.lowercased().contains("visual studio") == true {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white.opacity(0.74))
        } else {
            Image(systemName: item.kind.iconName)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))
        }
    }

    private var previewArea: some View {
        ZStack(alignment: .topLeading) {
            linedPaper

            switch item.kind {
            case .image:
                imagePreview
            case .file:
                filePreview
            case .text, .link:
                Text(item.preview)
                    .font(.system(size: 12.5))
                    .foregroundStyle(.black)
                    .lineLimit(5)
                    .padding(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var linedPaper: some View {
        VStack(spacing: 0) {
            ForEach(0..<10, id: \.self) { _ in
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 16)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(Color.black.opacity(0.08))
                            .frame(height: 1)
                    }
            }
            Spacer(minLength: 0)
        }
        .background(Color.white)
    }

    @ViewBuilder
    private var imagePreview: some View {
        if let attachmentPath = item.attachmentPath,
           let image = NSImage(contentsOfFile: attachmentPath) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(4)
        } else {
            Image(systemName: "photo")
                .font(.system(size: 58))
                .foregroundStyle(Color(hex: accentHex).opacity(0.72))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var filePreview: some View {
        VStack(spacing: 10) {
            Image(systemName: "folder.fill")
                .font(.system(size: 84))
                .foregroundStyle(Color(hex: accentHex).opacity(0.85))
            Text(item.preview)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack {
            Text(index < 9 ? "⌘\(index + 1)" : "")
            Spacer()
            Text(footerDetail)
                .lineLimit(1)
            Spacer()
            Text("⇧↩")
        }
        .font(.caption2)
        .foregroundStyle(Color.black.opacity(0.34))
        .padding(.horizontal, 14)
        .frame(height: 28)
    }

    private var footerDetail: String {
        if let pinboardName {
            return pinboardName
        }
        switch item.kind {
        case .text, .link:
            return "\(item.preview.count) caracteres"
        case .image:
            return "imagen"
        case .file:
            return "archivo"
        }
    }
}

private struct PinboardEditSheet: View {
    let pinboard: Pinboard
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var colorHex: String

    init(pinboard: Pinboard, appState: AppState) {
        self.pinboard = pinboard
        self.appState = appState
        _name = State(initialValue: pinboard.name)
        _colorHex = State(initialValue: pinboard.colorHex)
    }

    var body: some View {
        PinboardEditorView(
            title: "Editar grupo",
            name: $name,
            colorHex: $colorHex,
            primaryTitle: "Guardar",
            onCancel: { dismiss() },
            onSave: {
                appState.update(pinboardID: pinboard.id, name: name, colorHex: colorHex)
                dismiss()
            }
        )
    }
}

private struct PinboardEditorView: View {
    let title: String
    @Binding var name: String
    @Binding var colorHex: String
    let primaryTitle: String
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)

            TextField("Nombre", text: $name)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 10) {
                ForEach(pinboardPalette, id: \.self) { swatch in
                    Button {
                        colorHex = swatch
                    } label: {
                        Circle()
                            .fill(Color(hex: swatch))
                            .frame(width: 22, height: 22)
                            .overlay {
                                Circle()
                                    .stroke(Color.primary.opacity(colorHex == swatch ? 0.7 : 0.15), lineWidth: colorHex == swatch ? 2 : 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                Spacer()
                Button("Cancelar", action: onCancel)
                Button(primaryTitle, action: onSave)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding(22)
        .frame(width: 320)
    }
}

private func colorName(_ hex: String) -> String {
    switch hex {
    case "#F85B5B": return "Rojo"
    case "#F59E0B": return "Naranja"
    case "#FACC15": return "Amarillo"
    case "#63D957": return "Verde"
    case "#38BDF8": return "Azul"
    case "#C084FC": return "Morado"
    default: return "Gris"
    }
}

private extension ClipboardKind {
    var displayTitle: String {
        switch self {
        case .text: return "Texto"
        case .link: return "Enlace"
        case .image: return "Imagen"
        case .file: return "Archivo"
        }
    }

    var iconName: String {
        switch self {
        case .text: return "text.alignleft"
        case .link: return "link"
        case .image: return "photo"
        case .file: return "doc"
        }
    }
}

extension Color {
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

private struct KeyDownMonitor: NSViewRepresentable {
    let onKeyDown: (NSEvent) -> Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(onKeyDown: onKeyDown)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.hostView = view
        context.coordinator.installMonitorIfNeeded()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.hostView = nsView
        context.coordinator.onKeyDown = onKeyDown
        context.coordinator.installMonitorIfNeeded()
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.removeMonitor()
    }

    final class Coordinator {
        weak var hostView: NSView?
        var onKeyDown: (NSEvent) -> Bool
        private var monitor: Any?

        init(onKeyDown: @escaping (NSEvent) -> Bool) {
            self.onKeyDown = onKeyDown
        }

        func installMonitorIfNeeded() {
            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self,
                      let hostWindow = self.hostView?.window,
                      event.window === hostWindow else {
                    return event
                }

                return self.onKeyDown(event) ? nil : event
            }
        }

        func removeMonitor() {
            guard let monitor else { return }
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
