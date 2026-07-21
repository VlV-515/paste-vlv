import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english
    case spanish

    var id: String { rawValue }

    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .spanish: return "🇲🇽"
        }
    }

    var pickerTitle: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        }
    }
}

struct AppCopy {
    let language: AppLanguage

    private func choose(_ english: String, _ spanish: String) -> String {
        language == .english ? english : spanish
    }

    var showApp: String { choose("Show \(AppBranding.displayName)", "Mostrar \(AppBranding.displayName)") }
    var preferences: String { choose("Preferences...", "Preferencias...") }
    var about: String { choose("About \(AppBranding.displayName)", "Acerca de \(AppBranding.displayName)") }
    var exportGroups: String { choose("Export groups...", "Exportar grupos...") }
    var importGroups: String { choose("Import groups...", "Importar grupos...") }
    var pauseCapture: String { choose("Pause Capture", "Pausar captura") }
    var resumeCapture: String { choose("Resume Capture", "Reanudar captura") }
    var close: String { choose("Close", "Cerrar") }
    var quit: String { choose("Quit", "Salir") }

    var general: String { choose("General", "General") }
    var shortcuts: String { choose("Shortcuts", "Atajos") }
    var aboutTab: String { choose("About", "Acerca de") }
    var version: String { choose("Version", "Versión") }
    var createdBy: String { choose("Created by", "Creado por") }
    var license: String { choose("MIT License", "Licencia MIT") }
    var developerGitHub: String { choose("Developer GitHub", "GitHub del desarrollador") }
    var projectGitHub: String { choose("Project GitHub", "GitHub del proyecto") }
    var copyright: String { choose("© 2026 VlV. All rights reserved.", "© 2026 VlV. Todos los derechos reservados.") }
    var languageLabel: String { choose("Language:", "Idioma:") }
    var launch: String { choose("Launch:", "Arranque:") }
    var integration: String { choose("Integration:", "Integración:") }
    var other: String { choose("Other:", "Otros:") }
    var historyRetention: String { choose("History retention:", "Capacidad historial:") }
    var jsonBackup: String { choose("JSON backup:", "Respaldo JSON:") }
    var launchAtLogin: String { choose("Launch \(AppBranding.displayName) at login", "Ejecutar \(AppBranding.displayName) al arranque del sistema") }
    var enableDirectPaste: String { choose("Enable Direct Paste", "Activar Direct Paste") }
    var pastePlainText: String { choose("Always paste as plain text", "Pegar siempre como texto plano") }
    var enableSounds: String { choose("Enable sound effects", "Activar efectos de sonido") }
    var showMenuBarIcon: String { choose("Show \(AppBranding.displayName) in menu bar", "Mostrar icono de \(AppBranding.displayName) en barra de menú") }
    var clearHistory: String { choose("Clear clipboard history", "Limpiar historial del portapapeles") }

    var activatePaste: String { choose("Activate Paste:", "Activar Paste:") }
    var nextPinboard: String { choose("Show next pinboard:", "Mostrar siguiente Pinboard:") }
    var previousPinboard: String { choose("Show previous pinboard:", "Mostrar Pinboard anterior:") }
    var quickPaste: String { choose("Quick paste:", "Pegado rápido:") }
    var plainTextMode: String { choose("Plain-text mode:", "Modo texto plano:") }
    var none: String { choose("None", "Ninguno") }
    var command: String { choose("⌘ Command", "⌘ Comando") }
    var shift: String { choose("⇧ Shift", "⇧ Mayús") }

    var search: String { choose("Search", "Buscar") }
    var clipboardHistory: String { choose("Clipboard History", "Historial del portapapeles") }
    var newGroup: String { choose("New group", "Nuevo grupo") }
    var editGroup: String { choose("Edit group", "Editar grupo") }
    var create: String { choose("Create", "Crear") }
    var save: String { choose("Save", "Guardar") }
    var cancel: String { choose("Cancel", "Cancelar") }
    var name: String { choose("Name", "Nombre") }
    var rename: String { choose("Rename", "Renombrar") }
    var delete: String { choose("Delete", "Eliminar") }
    var addGroup: String { choose("Add group", "Agregar grupo") }
    var emptyHistory: String { choose("Copy something to start your history", "Copia algo para iniciar el historial") }
    var shortcutOpensApp: String { choose(" opens ", " abre ") }
    var paste: String { choose("Paste", "Pegar") }
    var pastePlainTextAction: String { choose("Paste as plain text", "Pegar como texto plano") }
    var favorite: String { choose("Favorite", "Favorito") }
    var removeFavorite: String { choose("Remove favorite", "Quitar favorito") }
    var pin: String { choose("Pin", "Fijar") }
    var unpin: String { choose("Unpin", "Desfijar") }
    var moveToGroup: String { choose("Move to group", "Mover a grupo") }
    var noGroup: String { choose("No group", "Sin grupo") }

    var exportTitle: String { choose("Export groups", "Exportar grupos") }
    var exportMessage: String { choose("Save groups and grouped text in a JSON backup. General history and images are left out.", "Guardar grupos y textos agrupados en un respaldo JSON. Historial general e imágenes quedan fuera.") }
    var exportComplete: String { choose("Export complete", "Exportación completada") }
    var exportFailed: String { choose("Could not export", "No se pudo exportar") }
    var importTitle: String { choose("Import groups", "Importar grupos") }
    var importMessage: String { choose("Select a JSON backup of grouped text exported from Paste-vlv.", "Selecciona un respaldo JSON de grupos con textos agrupados exportado desde Paste-vlv.") }
    var importComplete: String { choose("Import complete", "Importación completada") }
    var importFailed: String { choose("Could not import", "No se pudo importar") }
    var file: String { choose("File", "Archivo") }

    func retentionTitle(for policy: RetentionPolicy) -> String {
        switch (language, policy) {
        case (.english, .oneDay): return "Day"
        case (.english, .oneWeek): return "Week"
        case (.english, .oneMonth): return "Month"
        case (.english, .oneYear): return "Year"
        case (.english, .forever): return "Forever"
        case (.spanish, .oneDay): return "Día"
        case (.spanish, .oneWeek): return "Semana"
        case (.spanish, .oneMonth): return "Mes"
        case (.spanish, .oneYear): return "Año"
        case (.spanish, .forever): return "Sin límite"
        }
    }

    func clipboardKindTitle(_ kind: ClipboardKind) -> String {
        switch (language, kind) {
        case (.english, .text): return "Text"
        case (.english, .link): return "Link"
        case (.english, .image): return "Image"
        case (.english, .file): return "File"
        case (.spanish, .text): return "Texto"
        case (.spanish, .link): return "Enlace"
        case (.spanish, .image): return "Imagen"
        case (.spanish, .file): return "Archivo"
        }
    }

    func colorName(_ hex: String) -> String {
        switch hex {
        case "#F85B5B": return choose("Red", "Rojo")
        case "#F59E0B": return choose("Orange", "Naranja")
        case "#FACC15": return choose("Yellow", "Amarillo")
        case "#63D957": return choose("Green", "Verde")
        case "#38BDF8": return choose("Blue", "Azul")
        case "#C084FC": return choose("Purple", "Morado")
        default: return choose("Gray", "Gris")
        }
    }

    func characters(_ count: Int) -> String {
        choose("\(count) characters", "\(count) caracteres")
    }

    func itemKindDetail(_ kind: ClipboardKind) -> String {
        switch kind {
        case .image: return choose("image", "imagen")
        case .file: return choose("file", "archivo")
        case .text, .link: return ""
        }
    }
}
