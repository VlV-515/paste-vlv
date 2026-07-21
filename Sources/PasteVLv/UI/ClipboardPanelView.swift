import AppKit
import LinkPresentation
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

private let selectedCardOutline = Color(red: 0.84, green: 0.62, blue: 0.26)
private let clipboardItemDragPrefix = "paste-vlv.clipboard-items:"

struct ClipboardPanelView: View {
    @ObservedObject var appState: AppState
    let onPaste: (ClipboardItem, Bool) -> Void
    let onClose: () -> Void
    let onOpenPreferences: () -> Void

    @FocusState private var isSearchFocused: Bool
    @State private var isAddingPinboard = false
    @State private var editingPinboard: Pinboard?
    @State private var isEditingItemTitle = false
    @State private var newPinboardName = ""
    @State private var newPinboardColor = pinboardPalette[0]
    @State private var pendingDeletion: PendingDeletion?
    @State private var cardFrames: [UUID: CGRect] = [:]
    @State private var selectionDrag: CardSelectionDrag?
    @State private var pinboardFrames: [UUID: CGRect] = [:]
    @State private var draggedPinboardID: UUID?
    @State private var pinboardDropTargetID: UUID?
    @State private var pinboardItemDropTargetID: UUID?

    private var copy: AppCopy {
        AppCopy(language: appState.appLanguage)
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            content
        }
        .frame(minWidth: 980, idealWidth: 1180, minHeight: 360, idealHeight: 392)
        .background(panelBackground)
        .sheet(isPresented: $isAddingPinboard) {
            PinboardEditorView(
                title: copy.newGroup,
                name: $newPinboardName,
                colorHex: $newPinboardColor,
                primaryTitle: copy.create,
                namePrompt: copy.name,
                cancelTitle: copy.cancel,
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
        .alert(item: $pendingDeletion) { request in
            Alert(
                title: Text(request.title(copy)),
                message: Text(request.message(copy)),
                primaryButton: .destructive(Text(copy.delete)) {
                    performDeletion(request)
                },
                secondaryButton: .cancel(Text(copy.cancel))
            )
        }
    }

    private var topBar: some View {
        ZStack {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.white.opacity(0.62))
                    TextField("", text: $appState.searchText, prompt: Text(copy.search).foregroundColor(.white.opacity(0.42)))
                        .textFieldStyle(.plain)
                        .focused($isSearchFocused)
                        .foregroundStyle(.white)
                        .frame(width: 160)
                }

                Spacer()

                Menu {
                    Button(copy.exportGroups) {
                        appState.exportHistoryInteractively()
                    }
                    Button(copy.importGroups) {
                        appState.importHistoryInteractively()
                    }
                    Divider()
                    Button(copy.preferences) {
                        onOpenPreferences()
                    }
                    Divider()
                    Button(appState.isCapturePaused ? copy.resumeCapture : copy.pauseCapture) {
                        appState.isCapturePaused.toggle()
                    }
                    Button(copy.close) {
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
                    title: copy.clipboardHistory,
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
                            .background {
                                GeometryReader { geometry in
                                    Color.clear.preference(
                                        key: PinboardFramePreferenceKey.self,
                                        value: [pinboard.id: geometry.frame(in: .named("pinboard-tabs"))]
                                    )
                                }
                            }
                            .opacity(draggedPinboardID == pinboard.id ? 0.56 : 1)
                            .overlay {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(Color.white.opacity(pinboardDropTargetID == pinboard.id || pinboardItemDropTargetID == pinboard.id ? 0.7 : 0), lineWidth: 1)
                            }
                            .highPriorityGesture(
                                DragGesture(minimumDistance: 5, coordinateSpace: .named("pinboard-tabs"))
                                    .onChanged { value in
                                        updatePinboardDrag(sourceID: pinboard.id, location: value.location)
                                    }
                                    .onEnded { value in
                                        finishPinboardDrag(sourceID: pinboard.id, location: value.location)
                                    }
                            )
                            .contextMenu {
                                Button(copy.rename) {
                                    editingPinboard = pinboard
                                }
                                Button(role: .destructive) {
                                    pendingDeletion = .pinboard(pinboard)
                                } label: {
                                    Text(copy.delete)
                                }
                                Divider()
                                ForEach(pinboardPalette, id: \.self) { colorHex in
                                    Button {
                                        appState.update(pinboardID: pinboard.id, name: pinboard.name, colorHex: colorHex)
                                    } label: {
                                        Label {
                                            Text(copy.colorName(colorHex))
                                        } icon: {
                                            Image(
                                                nsImage: pinboardColorMenuIcon(
                                                    colorHex: colorHex,
                                                    isSelected: pinboard.colorHex == colorHex
                                                )
                                            )
                                        }
                                    }
                                }
                            }
                            .onDrop(
                                of: [UTType.plainText],
                                isTargeted: Binding(
                                    get: { pinboardItemDropTargetID == pinboard.id },
                                    set: { isTargeted in
                                        pinboardItemDropTargetID = isTargeted ? pinboard.id : nil
                                    }
                                )
                            ) { providers in
                                handleItemDrop(providers, on: pinboard.id)
                            }
                        }
                    }
                    .coordinateSpace(name: "pinboard-tabs")
                    .onPreferenceChange(PinboardFramePreferenceKey.self) { pinboardFrames = $0 }
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
                .help(copy.addGroup)
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
                    ZStack(alignment: .topLeading) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(alignment: .top, spacing: 16) {
                                ForEach(Array(appState.items.enumerated()), id: \.element.id) { index, item in
                                    ClipboardCard(
                                        item: item,
                                        index: index,
                                        accentHex: appState.colorHex(for: item),
                                        sourceColorHex: ClipboardSourceAppearance.colorHex(for: item),
                                        pinboardName: appState.pinboardName(for: item),
                                        pinboards: appState.pinboards,
                                        copy: AppCopy(language: appState.appLanguage),
                                        isSelected: appState.selectedItemIDs.contains(item.id),
                                        onSelect: {
                                            if !appState.selectedItemIDs.contains(item.id) {
                                                appState.selectItem(id: item.id)
                                            }
                                        },
                                        dragPayload: {
                                            let itemIDs = appState.selectedItemIDs.contains(item.id) ? appState.selectedItemIDs : [item.id]
                                            return clipboardItemDragPayload(for: itemIDs)
                                        },
                                        onPaste: { onPaste(item, false) },
                                        onPastePlain: { onPaste(item, true) },
                                        onFavorite: { appState.toggleFavorite(itemID: item.id) },
                                        onPin: { appState.togglePinned(itemID: item.id) },
                                        onDelete: { pendingDeletion = .items([item.id]) },
                                        onAssign: { appState.assign(itemID: item.id, to: $0) },
                                        onRename: { appState.updateTitle(itemID: item.id, title: $0) },
                                        onTitleEditingChanged: { isEditingItemTitle = $0 }
                                    )
                                    .id(item.id)
                                    .background {
                                        GeometryReader { geometry in
                                            Color.clear.preference(
                                                key: ClipboardCardFramePreferenceKey.self,
                                                value: [item.id: geometry.frame(in: .named("card-selection"))]
                                            )
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 2)
                            .padding(.bottom, 12)
                        }

                        if let selectionDrag {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(selectedCardOutline.opacity(0.16))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(selectedCardOutline.opacity(0.94), lineWidth: 1.5)
                                }
                                .frame(width: selectionDrag.rect.width, height: selectionDrag.rect.height)
                                .offset(x: selectionDrag.rect.minX, y: selectionDrag.rect.minY)
                                .allowsHitTesting(false)
                        }
                    }
                    .coordinateSpace(name: "card-selection")
                    .onPreferenceChange(ClipboardCardFramePreferenceKey.self) { cardFrames = $0 }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 8, coordinateSpace: .named("card-selection"))
                            .onChanged(updateSelectionDrag)
                            .onEnded(finishSelectionDrag)
                    )
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
            Text(AppCopy(language: appState.appLanguage).emptyHistory)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.82))
            Text(appState.openShortcut.displayName + AppCopy(language: appState.appLanguage).shortcutOpensApp + AppBranding.displayName)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.52))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 36)
    }

    private var panelBackground: some View {
        LinearGradient(
            colors: [
                Color(hex: "#09090A"),
                Color(hex: "#050506"),
                Color(hex: "#111113")
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
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

    private func updateSelectionDrag(_ value: DragGesture.Value) {
        guard canStartSelectionDrag(at: value.startLocation) else {
            selectionDrag = nil
            return
        }

        selectionDrag = CardSelectionDrag(start: value.startLocation, current: value.location)
    }

    private func finishSelectionDrag(_ value: DragGesture.Value) {
        guard canStartSelectionDrag(at: value.startLocation) else {
            selectionDrag = nil
            return
        }

        let drag = CardSelectionDrag(start: value.startLocation, current: value.location)
        selectionDrag = nil

        guard drag.rect.width >= 12 || drag.rect.height >= 12 else { return }
        let selectedItemIDs = Set(cardFrames.compactMap { id, frame in
            frame.intersects(drag.rect) ? id : nil
        })
        appState.selectItems(selectedItemIDs)
    }

    private func canStartSelectionDrag(at location: CGPoint) -> Bool {
        !cardFrames.contains { _, frame in
            frame.contains(location)
        }
    }

    private func handleKeyDown(_ event: NSEvent) -> Bool {
        guard editingPinboard == nil, !isAddingPinboard, !isEditingItemTitle else { return false }
        let modifiers = event.modifierFlags.intersection([.shift, .control, .option, .command])

        switch event.keyCode {
        case 0 where modifiers == [.command]:
            appState.selectAllItems()
            return true
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
        case 117 where modifiers.isEmpty:
            guard appState.selectedItem != nil else { return false }
            let itemIDs = appState.selectedItemIDsForDeletion()
            guard !itemIDs.isEmpty else { return false }
            pendingDeletion = .items(itemIDs)
            return true
        default:
            return false
        }
    }

    private func updatePinboardDrag(sourceID: UUID, location: CGPoint) {
        draggedPinboardID = sourceID
        pinboardDropTargetID = pinboardFrames.first { id, frame in
            id != sourceID && frame.contains(location)
        }?.key
    }

    private func finishPinboardDrag(sourceID: UUID, location: CGPoint) {
        defer {
            draggedPinboardID = nil
            pinboardDropTargetID = nil
        }

        guard let targetPinboardID = pinboardFrames.first(where: { id, frame in
            id != sourceID && frame.contains(location)
        })?.key,
        let sourceIndex = appState.pinboards.firstIndex(where: { $0.id == sourceID }),
        let targetIndex = appState.pinboards.firstIndex(where: { $0.id == targetPinboardID }) else {
            return
        }

        let destinationIndex = sourceIndex < targetIndex ? targetIndex + 1 : targetIndex
        appState.reorder(pinboardID: sourceID, to: destinationIndex)
    }

    private func handleItemDrop(_ providers: [NSItemProvider], on pinboardID: UUID) -> Bool {
        guard let provider = providers.first(where: { $0.canLoadObject(ofClass: NSString.self) }) else {
            return false
        }

        provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let text = object as? String,
                  let itemIDs = clipboardItemIDs(from: text),
                  !itemIDs.isEmpty else {
                return
            }

            DispatchQueue.main.async {
                pinboardItemDropTargetID = nil
                appState.assign(itemIDs: itemIDs, to: pinboardID)
            }
        }
        return true
    }

    private func performDeletion(_ request: PendingDeletion) {
        switch request {
        case .items(let itemIDs):
            appState.delete(itemIDs: itemIDs)
        case .pinboard(let pinboard):
            appState.delete(pinboardID: pinboard.id)
        }
    }
}

private enum PendingDeletion: Identifiable {
    case items(Set<UUID>)
    case pinboard(Pinboard)

    var id: String {
        switch self {
        case .items(let itemIDs):
            return itemIDs.map(\.uuidString).sorted().joined(separator: ",")
        case .pinboard(let pinboard):
            return pinboard.id.uuidString
        }
    }

    func title(_ copy: AppCopy) -> String {
        switch self {
        case .items:
            return copy.deleteConfirmationTitle
        case .pinboard:
            return copy.deleteGroupConfirmationTitle
        }
    }

    func message(_ copy: AppCopy) -> String {
        switch self {
        case .items(let itemIDs):
            return copy.deleteItemsMessage(itemIDs.count)
        case .pinboard(let pinboard):
            return copy.deleteGroupMessage(pinboard.name)
        }
    }
}

private struct CardSelectionDrag {
    let start: CGPoint
    let current: CGPoint

    var rect: CGRect {
        CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
    }
}

private func clipboardItemDragPayload(for itemIDs: Set<UUID>) -> String {
    clipboardItemDragPrefix + itemIDs.map(\.uuidString).sorted().joined(separator: ",")
}

private func clipboardItemIDs(from payload: String) -> Set<UUID>? {
    guard payload.hasPrefix(clipboardItemDragPrefix) else { return nil }

    let rawIDs = payload.dropFirst(clipboardItemDragPrefix.count)
    let itemIDs = rawIDs
        .split(separator: ",")
        .compactMap { UUID(uuidString: String($0)) }

    return Set(itemIDs)
}

private struct ClipboardCardFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]

    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, latest in latest })
    }
}

private struct PinboardFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]

    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, latest in latest })
    }
}

private struct PinboardTab: View {
    let title: String
    let colorHex: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
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
        .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .onTapGesture(perform: onSelect)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct ClipboardCard: View {
    let item: ClipboardItem
    let index: Int
    let accentHex: String
    let sourceColorHex: String
    let pinboardName: String?
    let pinboards: [Pinboard]
    let copy: AppCopy
    let isSelected: Bool
    let onSelect: () -> Void
    let dragPayload: () -> String
    let onPaste: () -> Void
    let onPastePlain: () -> Void
    let onFavorite: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void
    let onAssign: (UUID?) -> Void
    let onRename: (String?) -> Void
    let onTitleEditingChanged: (Bool) -> Void
    @State private var isEditingTitle = false
    @State private var titleDraft = ""
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            previewArea
            footer
        }
        .frame(width: 242, height: 248)
        .background(Color(hex: "#1C1C1E"))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    isSelected ? selectedCardOutline : Color(hex: accentHex).opacity(item.pinboardID == nil ? 0.12 : 0.72),
                    lineWidth: isSelected ? 4 : (item.pinboardID == nil ? 1 : 2)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(isSelected ? Color.black.opacity(0.42) : Color.clear, lineWidth: 1)
                .padding(4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(selectedCardOutline.opacity(isSelected ? 1 : 0))
                .frame(height: 3)
                .padding(.horizontal, 4)
                .padding(.bottom, 4),
            alignment: .bottom
        )
        .shadow(color: isSelected ? selectedCardOutline.opacity(0.18) : .black.opacity(0.34), radius: isSelected ? 10 : 7, y: 3)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .background(CardPointerMonitor(onMouseDown: onSelect, dragPayload: dragPayload))
        .onTapGesture(count: 2, perform: onPaste)
        .contextMenu {
            Button(copy.paste) { onPaste() }
            Button(copy.pastePlainTextAction) { onPastePlain() }
                .disabled(item.kind == .image || item.kind == .file)
            Divider()
            Button(item.isFavorite ? copy.removeFavorite : copy.favorite) { onFavorite() }
            Button(item.isPinned ? copy.unpin : copy.pin) { onPin() }
            Menu(copy.moveToGroup) {
                Button(copy.noGroup) { onAssign(nil) }
                ForEach(pinboards) { pinboard in
                    Button(pinboard.name) { onAssign(pinboard.id) }
                }
            }
            Button(copy.rename) { startTitleEditing() }
            Divider()
            Button(role: .destructive) {
                onDelete()
            } label: {
                Text(copy.delete)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                title
                Text(item.createdAt, style: .relative)
                    .font(.system(size: 12, weight: .medium))
                    .opacity(0.85)
            }
            Spacer()
            sourceIcon
        }
        .foregroundStyle(.white)
        .padding(.leading, 13)
        .padding(.trailing, 8)
        .padding(.top, 8)
        .frame(height: 58)
        .background(
            LinearGradient(
                colors: [Color(hex: sourceColorHex), Color(hex: sourceColorHex).opacity(0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    @ViewBuilder
    private var title: some View {
        if isEditingTitle {
            TextField(copy.clipboardKindTitle(item.kind), text: $titleDraft)
                .font(.system(size: 16, weight: .bold))
                .textFieldStyle(.plain)
                .focused($isTitleFocused)
                .onSubmit(saveTitle)
                .onAppear {
                    DispatchQueue.main.async {
                        isTitleFocused = true
                    }
                }
        } else {
            Text(item.customTitle ?? defaultTitle)
                .font(.system(size: 16, weight: .bold))
                .lineLimit(1)
                .highPriorityGesture(TapGesture().onEnded(handleTitleTap))
        }
    }

    private func handleTitleTap() {
        if isSelected {
            startTitleEditing()
        } else {
            onSelect()
        }
    }

    private func startTitleEditing() {
        titleDraft = item.customTitle ?? ""
        isEditingTitle = true
        onTitleEditingChanged(true)
    }

    private func saveTitle() {
        onRename(titleDraft)
        isEditingTitle = false
        onTitleEditingChanged(false)
    }

    @ViewBuilder
    private var sourceIcon: some View {
        if let sourceIcon = ClipboardSourceAppearance.icon(for: item) {
            Image(nsImage: sourceIcon)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 40, height: 40)
                .shadow(color: .black.opacity(0.26), radius: 2, y: 1)
        } else {
            Image(systemName: item.kind.iconName)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))
        }
    }

    private var previewArea: some View {
        ZStack(alignment: .topLeading) {
            Color(hex: "#1C1C1E")
            switch item.kind {
            case .image:
                imagePreview
            case .file:
                filePreview
            case .link:
                linkPreview
            case .text:
                Text(item.preview)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(6)
                    .padding(13)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var imagePreview: some View {
        if let attachmentPath = item.attachmentPath,
           let image = NSImage(contentsOfFile: attachmentPath) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(2)
        } else {
            Image(systemName: "photo")
                .font(.system(size: 58))
                .foregroundStyle(.white.opacity(0.42))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var filePreview: some View {
        Group {
            if filePaths.count == 1,
               let image = NSImage(contentsOfFile: filePaths[0]) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(10)
            } else {
                Image(systemName: filePaths.count > 1 ? "doc.on.doc.fill" : "doc.fill")
                    .font(.system(size: 78, weight: .light))
                    .foregroundStyle(.white.opacity(0.92))
                    .shadow(color: .black.opacity(0.32), radius: 5, y: 3)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var linkPreview: some View {
        LinkCardPreview(urlString: item.urlString ?? item.text ?? item.preview)
    }

    private var footer: some View {
        HStack {
            Text("#\(index + 1)")
            Spacer()
            Text(footerDetail)
                .lineLimit(1)
            Spacer()
            Label("\(index + 1)", systemImage: "line.3.horizontal")
                .labelStyle(.titleAndIcon)
        }
        .font(.caption2)
        .foregroundStyle(.white.opacity(0.5))
        .padding(.horizontal, 12)
        .frame(height: 26)
        .background(Color(hex: "#1C1C1E"))
    }

    private var footerDetail: String {
        if let pinboardName {
            return pinboardName
        }
        switch item.kind {
        case .text, .link:
            return copy.characters(item.preview.count)
        case .image:
            return copy.itemKindDetail(.image)
        case .file:
            return filePaths.count == 1 ? filePaths[0] : copy.multipleFiles
        }
    }

    private var defaultTitle: String {
        item.kind == .file ? copy.files(filePaths.count) : copy.clipboardKindTitle(item.kind)
    }

    private var filePaths: [String] {
        let paths = (item.filePath ?? "")
            .split(separator: "\n")
            .map(String.init)
        return paths.isEmpty ? [item.preview] : paths
    }
}

private struct LinkCardPreview: View {
    let urlString: String
    @State private var title = ""
    @State private var thumbnail: NSImage?

    private var url: URL? {
        URL(string: urlString)
    }

    private var host: String {
        url?.host(percentEncoded: false) ?? urlString
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                LinearGradient(
                    colors: [Color(hex: "#2A2A2D"), Color(hex: "#121214")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "link")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(.white.opacity(0.52))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.82)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(title.isEmpty ? host : title)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(2)
                Text(host)
                    .font(.system(size: 10.5))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .padding(10)
        }
        .task(id: urlString) {
            await loadMetadata()
        }
    }

    private func loadMetadata() async {
        guard let url else { return }

        let provider = LPMetadataProvider()
        provider.timeout = 8

        do {
            let metadata = try await provider.startFetchingMetadata(for: url)
            await MainActor.run {
                title = metadata.title ?? host
            }
            metadata.imageProvider?.loadObject(ofClass: NSImage.self) { object, _ in
                guard let image = object as? NSImage else { return }
                Task { @MainActor in
                    thumbnail = image
                }
            }
        } catch {
            await MainActor.run {
                title = host
            }
        }
    }
}

private enum ClipboardSourceAppearance {
    static func colorHex(for item: ClipboardItem) -> String {
        let bundleID = item.sourceAppBundleID?.lowercased() ?? ""

        if bundleID == "com.apple.finder" { return "#5AA5EE" }
        if bundleID == "dev.vlv.pastevlv" { return "#F4B942" }
        if bundleID == "com.microsoft.vscode" { return "#0E639C" }
        if bundleID.contains("brave") { return "#F24D1C" }
        if bundleID.contains("openai") { return "#8A8A8A" }

        let palette = ["#5AA5EE", "#1F7AC0", "#22C55E", "#F59E0B", "#D946EF", "#64748B"]
        let value = (item.sourceAppBundleID ?? item.sourceAppName ?? item.kind.rawValue)
            .unicodeScalars
            .reduce(0) { ($0 &* 31) &+ Int($1.value) }
        return palette[abs(value) % palette.count]
    }

    static func icon(for item: ClipboardItem) -> NSImage? {
        guard let bundleID = item.sourceAppBundleID,
              let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: url.path)
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
            title: AppCopy(language: appState.appLanguage).editGroup,
            name: $name,
            colorHex: $colorHex,
            primaryTitle: AppCopy(language: appState.appLanguage).save,
            namePrompt: AppCopy(language: appState.appLanguage).name,
            cancelTitle: AppCopy(language: appState.appLanguage).cancel,
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
    let namePrompt: String
    let cancelTitle: String
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)

            TextField(namePrompt, text: $name)
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
                Button(cancelTitle, action: onCancel)
                Button(primaryTitle, action: onSave)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding(22)
        .frame(width: 320)
    }
}

private func pinboardColorMenuIcon(colorHex: String, isSelected: Bool) -> NSImage {
    let size = NSSize(width: 12, height: 12)
    let image = NSImage(size: size)

    image.lockFocus()

    let rect = NSRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1)
    let circle = NSBezierPath(ovalIn: rect)
    let fillColor = NSColor(hex: colorHex)
    let borderColor = NSColor.white.withAlphaComponent(colorHex == "#FACC15" ? 0.45 : 0.18)

    fillColor.setFill()
    circle.fill()

    borderColor.setStroke()
    circle.lineWidth = 0.75
    circle.stroke()

    if isSelected {
        let check = NSBezierPath()
        check.move(to: NSPoint(x: 3.2, y: 6.2))
        check.line(to: NSPoint(x: 5.2, y: 4.1))
        check.line(to: NSPoint(x: 8.6, y: 8.0))
        check.lineCapStyle = .round
        check.lineJoinStyle = .round
        check.lineWidth = 1.3

        let checkColor: NSColor = colorHex == "#FACC15" || colorHex == "#94A3B8"
            ? NSColor.black.withAlphaComponent(0.78)
            : NSColor.white
        checkColor.setStroke()
        check.stroke()
    }

    image.unlockFocus()
    image.isTemplate = false
    return image
}

private extension ClipboardKind {
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

private extension NSColor {
    convenience init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&value)

        let red = CGFloat((value >> 16) & 0xFF) / 255
        let green = CGFloat((value >> 8) & 0xFF) / 255
        let blue = CGFloat(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
}

private struct CardPointerMonitor: NSViewRepresentable {
    let onMouseDown: () -> Void
    let dragPayload: () -> String

    func makeCoordinator() -> Coordinator {
        Coordinator(onMouseDown: onMouseDown, dragPayload: dragPayload)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.hostView = view
        context.coordinator.installMonitorIfNeeded()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.onMouseDown = onMouseDown
        context.coordinator.dragPayload = dragPayload
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.removeMonitor()
    }

    final class Coordinator: NSObject, NSDraggingSource {
        weak var hostView: NSView?
        var onMouseDown: () -> Void
        var dragPayload: () -> String
        private var monitor: Any?
        private var mouseDownEvent: NSEvent?
        private var mouseDownLocation: CGPoint?
        private var hasStartedDrag = false

        init(onMouseDown: @escaping () -> Void, dragPayload: @escaping () -> String) {
            self.onMouseDown = onMouseDown
            self.dragPayload = dragPayload
        }

        func installMonitorIfNeeded() {
            guard monitor == nil else { return }

            monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp]) { [weak self] event in
                guard let self,
                      let hostView,
                      event.window === hostView.window else {
                    return event
                }

                let location = hostView.convert(event.locationInWindow, from: nil)

                switch event.type {
                case .leftMouseDown where hostView.bounds.contains(location):
                    mouseDownEvent = event
                    mouseDownLocation = location
                    hasStartedDrag = false
                    onMouseDown()
                case .leftMouseDragged:
                    guard let mouseDownEvent,
                          let mouseDownLocation,
                          !hasStartedDrag,
                          dragDistance(from: mouseDownLocation, to: location) >= 5 else {
                        return event
                    }

                    hasStartedDrag = true
                    beginDrag(from: mouseDownEvent, in: hostView)
                    return nil
                case .leftMouseUp:
                    mouseDownEvent = nil
                    mouseDownLocation = nil
                    hasStartedDrag = false
                default:
                    break
                }

                return event
            }
        }

        func removeMonitor() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
        }

        func draggingSession(
            _ session: NSDraggingSession,
            sourceOperationMaskFor context: NSDraggingContext
        ) -> NSDragOperation {
            .copy
        }

        private func beginDrag(from event: NSEvent, in hostView: NSView) {
            let pasteboardItem = NSPasteboardItem()
            pasteboardItem.setString(dragPayload(), forType: .string)

            let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
            let image = dragImage()
            let frame = NSRect(
                x: max((hostView.bounds.width - image.size.width) / 2, 0),
                y: max((hostView.bounds.height - image.size.height) / 2, 0),
                width: image.size.width,
                height: image.size.height
            )
            draggingItem.setDraggingFrame(frame, contents: image)
            hostView.beginDraggingSession(with: [draggingItem], event: event, source: self)
        }

        private func dragDistance(from start: CGPoint, to current: CGPoint) -> CGFloat {
            hypot(current.x - start.x, current.y - start.y)
        }

        private func dragImage() -> NSImage {
            let size = NSSize(width: 172, height: 46)
            let image = NSImage(size: size)
            image.lockFocus()

            let rect = NSRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1)
            let path = NSBezierPath(roundedRect: rect, xRadius: 11, yRadius: 11)
            NSColor(calibratedWhite: 0.12, alpha: 0.94).setFill()
            path.fill()
            NSColor(calibratedWhite: 1, alpha: 0.24).setStroke()
            path.lineWidth = 1
            path.stroke()

            let title = NSString(string: "PasteVLv")
            title.draw(
                in: NSRect(x: 16, y: 14, width: size.width - 32, height: 18),
                withAttributes: [
                    .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
                    .foregroundColor: NSColor.white.withAlphaComponent(0.86)
                ]
            )

            image.unlockFocus()
            image.isTemplate = false
            return image
        }
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
