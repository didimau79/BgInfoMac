import Foundation

enum AppLanguage: String, CaseIterable, Codable {
    case system
    case en
    case es
    case it
    case de
    case fr

    var nativeName: String {
        switch self {
        case .system: return "Automático / Automatic"
        case .en: return "English"
        case .es: return "Español"
        case .it: return "Italiano"
        case .de: return "Deutsch"
        case .fr: return "Français"
        }
    }
}

enum LKey: String {
    case aboutMenuItem, showOverlay, refreshEvery
    case intervalNever, interval5s, interval30s, interval1m, interval5m
    case refreshNow, preferencesMenuItem, quitMenuItem, helpMenuItem

    case helpWindowTitle, helpSearchPlaceholder, helpNoSelection

    case prefsWindowTitle, tabFields, tabAppearance

    case sectionSystem, sectionHardware, sectionStorage, sectionNetwork, sectionMessage

    case fieldHostName, fieldUserName, fieldOSVersion, fieldDateTime, fieldSerialNumber, fieldOSBuild
    case fieldMacModel, fieldChipName, fieldUptime, fieldRAM, fieldBattery, fieldCPUCores, fieldGPU
    case fieldWifiSSID, fieldInterfaces, fieldPublicIP, fieldGateway, fieldDNSServers
    case fieldVPNProvider, fieldVPNTunnelIP, fieldISPProvider

    case coresUnit, batteryHealthLabel, batteryCyclesLabel
    case batteryTimeRemainingLabel, batteryTimeToFullLabel

    /// Formato con un "%d": cantidad de servidores DNS adicionales no mostrados.
    case dnsMoreSuffix

    case showTitleToggle, storageHint, messagePlaceholder

    case positionCornerLabel, cornerTopLeft, cornerTopRight, cornerBottomLeft, cornerBottomRight
    case marginHorizontal, marginVertical

    case languageLabel
    case appearanceLabel, appearanceSystem, appearanceLight, appearanceDark

    case textColorLabel, backgroundColorLabel, backgroundOpacityLabel, fontSizeLabel

    case aboutWindowTitle, aboutTagline, versionLabel, developedByLabel, donateButtonLabel
    case githubLinkTitle
    case donationPromptText, donationPromptDisableHint

    case launchAtLogin
    case exportSettingsButton, importSettingsButton
    case exportSettingsSuccessTitle, exportSettingsSuccessMessage
    case importSettingsSuccessTitle, importSettingsSuccessMessage
    case importSettingsErrorTitle, importSettingsErrorMessage
    case displayTargetLabel, allDisplaysOption

    case targetDesktop, targetMenuBar

    case interfaceWifiIP, interfaceEthernet

    case includeExternalVolumes, includeNetworkVolumes

    case wifiPermissionWarningShort, wifiPermissionPrefsMessage, openSystemSettingsButton

    case noNetworkConnection

    case speedTestButtonLabel, speedTestRunningLabel, speedTestFailedLabel
    /// Formato con dos "%.0f": Mbps de bajada y de subida.
    case speedTestResultFormat

    /// Formato con dos "%@": espacio usado y espacio libre.
    case storageUsedFreeTooltip
}

private let translations: [AppLanguage: [LKey: String]] = [
    .en: [
        .aboutMenuItem: "About BGInfoMac",
        .showOverlay: "Show Desktop Overlay",
        .refreshEvery: "Refresh Every",
        .intervalNever: "Never",
        .interval5s: "5 Seconds",
        .interval30s: "30 Seconds",
        .interval1m: "1 Minute",
        .interval5m: "5 Minutes",
        .refreshNow: "Refresh Info",
        .preferencesMenuItem: "Preferences…",
        .quitMenuItem: "Quit",
        .helpMenuItem: "Help",
        .helpWindowTitle: "BGInfoMac Help",
        .helpSearchPlaceholder: "Search…",
        .helpNoSelection: "Select a topic",

        .prefsWindowTitle: "BGInfoMac Preferences",
        .tabFields: "Fields",
        .tabAppearance: "Appearance",

        .sectionSystem: "System",
        .sectionHardware: "Hardware",
        .sectionStorage: "Storage",
        .sectionNetwork: "Network",
        .sectionMessage: "Message",

        .fieldHostName: "Computer",
        .fieldUserName: "User",
        .fieldOSVersion: "OS",
        .fieldDateTime: "Date",
        .fieldSerialNumber: "Serial Number",
        .fieldOSBuild: "Build",
        .fieldMacModel: "Model",
        .fieldChipName: "Chip",
        .fieldUptime: "Uptime",
        .fieldRAM: "RAM",
        .fieldBattery: "Battery",
        .fieldCPUCores: "CPU Cores",
        .fieldGPU: "GPU",
        .fieldWifiSSID: "Wi-Fi",
        .fieldInterfaces: "Network Interfaces",
        .fieldPublicIP: "Public IP",
        .fieldGateway: "Gateway",
        .fieldDNSServers: "DNS",
        .fieldVPNProvider: "VPN",
        .fieldVPNTunnelIP: "Tunnel IP",
        .fieldISPProvider: "Provider",

        .coresUnit: "cores",
        .batteryHealthLabel: "health",
        .batteryCyclesLabel: "cycles",
        .batteryTimeRemainingLabel: "remaining",
        .batteryTimeToFullLabel: "until full",

        .showTitleToggle: "Show Title",
        .storageHint: "All mounted volumes are shown automatically.",
        .messagePlaceholder: "Custom message…",

        .positionCornerLabel: "Corner",
        .cornerTopLeft: "Top Left",
        .cornerTopRight: "Top Right",
        .cornerBottomLeft: "Bottom Left",
        .cornerBottomRight: "Bottom Right",
        .marginHorizontal: "Horizontal Margin",
        .marginVertical: "Vertical Margin",

        .languageLabel: "Language",
        .appearanceLabel: "App Appearance",
        .appearanceSystem: "System",
        .appearanceLight: "Light",
        .appearanceDark: "Dark",

        .textColorLabel: "Text Color",
        .backgroundColorLabel: "Background Color",
        .backgroundOpacityLabel: "Background Opacity",
        .fontSizeLabel: "Font Size",

        .aboutWindowTitle: "About BGInfoMac",
        .aboutTagline: "A BGInfo alternative for macOS.",
        .developedByLabel: "Developed by AMS",
        .donateButtonLabel: "Donate via PayPal",
        .githubLinkTitle: "Go to the project on GitHub",
        .donationPromptText: "Enjoying BGInfoMac? Consider donating.",
        .donationPromptDisableHint: "⌘⇧D to stop asking",
        .versionLabel: "Version",

        .launchAtLogin: "Launch at Login",
        .exportSettingsButton: "Export Settings...",
        .importSettingsButton: "Import Settings...",
        .exportSettingsSuccessTitle: "Settings Exported",
        .exportSettingsSuccessMessage: "Your settings were saved successfully.",
        .importSettingsSuccessTitle: "Settings Imported",
        .importSettingsSuccessMessage: "Your settings were applied successfully.",
        .importSettingsErrorTitle: "Import Failed",
        .importSettingsErrorMessage: "The selected file isn't a valid BGInfoMac settings file.",
        .displayTargetLabel: "Show On",
        .allDisplaysOption: "All Displays",

        .targetDesktop: "Desktop",
        .targetMenuBar: "Menu Bar",

        .interfaceWifiIP: "Wi-Fi IP",
        .interfaceEthernet: "Ethernet",

        .includeExternalVolumes: "Include external drives",
        .includeNetworkVolumes: "Include network drives",

        .wifiPermissionWarningShort: "Wi-Fi name unavailable — Location permission needed",
        .wifiPermissionPrefsMessage: "To show the Wi-Fi network name, BGInfoMac needs Location permission. Enable it in System Settings → Privacy & Security → Location Services.",
        .openSystemSettingsButton: "Open System Settings",
        .noNetworkConnection: "Not connected to any network",
        .speedTestButtonLabel: "Speedtest",
        .speedTestRunningLabel: "Measuring…",
        .speedTestFailedLabel: "Couldn't measure",
        .speedTestResultFormat: "%.0f↓ / %.0f↑ Mbps",

        .storageUsedFreeTooltip: "%@ used / %@ free",
        .dnsMoreSuffix: "+%d more"
    ],
    .es: [
        .aboutMenuItem: "Acerca de BGInfoMac",
        .showOverlay: "Mostrar overlay de escritorio",
        .refreshEvery: "Actualizar cada",
        .intervalNever: "Nunca",
        .interval5s: "5 segundos",
        .interval30s: "30 segundos",
        .interval1m: "1 minuto",
        .interval5m: "5 minutos",
        .refreshNow: "Refrescar información",
        .preferencesMenuItem: "Preferencias…",
        .quitMenuItem: "Salir",
        .helpMenuItem: "Ayuda",
        .helpWindowTitle: "Ayuda de BGInfoMac",
        .helpSearchPlaceholder: "Buscar…",
        .helpNoSelection: "Seleccioná un tema",

        .prefsWindowTitle: "Preferencias de BGInfoMac",
        .tabFields: "Campos",
        .tabAppearance: "Apariencia",

        .sectionSystem: "Sistema",
        .sectionHardware: "Hardware",
        .sectionStorage: "Almacenamiento",
        .sectionNetwork: "Red",
        .sectionMessage: "Mensaje",

        .fieldHostName: "Equipo",
        .fieldUserName: "Usuario",
        .fieldOSVersion: "SO",
        .fieldDateTime: "Fecha",
        .fieldSerialNumber: "Número de Serie",
        .fieldOSBuild: "Build",
        .fieldMacModel: "Modelo",
        .fieldChipName: "Chip",
        .fieldUptime: "Uptime",
        .fieldRAM: "RAM",
        .fieldBattery: "Batería",
        .fieldCPUCores: "Núcleos CPU",
        .fieldGPU: "GPU",
        .fieldWifiSSID: "Wi-Fi",
        .fieldInterfaces: "Interfaces de red",
        .fieldPublicIP: "IP Pública",
        .fieldGateway: "Gateway",
        .fieldDNSServers: "DNS",
        .fieldVPNProvider: "VPN",
        .fieldVPNTunnelIP: "IP del Túnel",
        .fieldISPProvider: "Proveedor",

        .coresUnit: "núcleos",
        .batteryHealthLabel: "salud",
        .batteryCyclesLabel: "ciclos",
        .batteryTimeRemainingLabel: "restante",
        .batteryTimeToFullLabel: "hasta carga completa",

        .showTitleToggle: "Mostrar título",
        .storageHint: "Se muestran automáticamente todos los volúmenes montados.",
        .messagePlaceholder: "Mensaje personalizado…",

        .positionCornerLabel: "Esquina",
        .cornerTopLeft: "Arriba Izquierda",
        .cornerTopRight: "Arriba Derecha",
        .cornerBottomLeft: "Abajo Izquierda",
        .cornerBottomRight: "Abajo Derecha",
        .marginHorizontal: "Margen horizontal",
        .marginVertical: "Margen vertical",

        .languageLabel: "Idioma",
        .appearanceLabel: "Apariencia de la app",
        .appearanceSystem: "Sistema",
        .appearanceLight: "Claro",
        .appearanceDark: "Oscuro",

        .textColorLabel: "Color de texto",
        .backgroundColorLabel: "Color de fondo",
        .backgroundOpacityLabel: "Opacidad de fondo",
        .fontSizeLabel: "Tamaño de fuente",

        .aboutWindowTitle: "Acerca de BGInfoMac",
        .aboutTagline: "Una alternativa a BGInfo para macOS.",
        .developedByLabel: "Desarrollado por AMS",
        .donateButtonLabel: "Donar con PayPal",
        .githubLinkTitle: "Accede al proyecto en GitHub",
        .donationPromptText: "¿Te gusta BGInfoMac? Considerá donar.",
        .donationPromptDisableHint: "⌘⇧D para no volver a preguntar",
        .versionLabel: "Versión",

        .launchAtLogin: "Ejecutar al inicio",
        .exportSettingsButton: "Exportar configuración...",
        .importSettingsButton: "Importar configuración...",
        .exportSettingsSuccessTitle: "Configuración exportada",
        .exportSettingsSuccessMessage: "La configuración se guardó correctamente.",
        .importSettingsSuccessTitle: "Configuración importada",
        .importSettingsSuccessMessage: "La configuración se aplicó correctamente.",
        .importSettingsErrorTitle: "Error al importar",
        .importSettingsErrorMessage: "El archivo seleccionado no es un archivo de configuración válido de BGInfoMac.",
        .displayTargetLabel: "Mostrar en",
        .allDisplaysOption: "Todas las pantallas",

        .targetDesktop: "Escritorio",
        .targetMenuBar: "Menú",

        .interfaceWifiIP: "IP Wi-Fi",
        .interfaceEthernet: "Ethernet",

        .includeExternalVolumes: "Incluir discos externos",
        .includeNetworkVolumes: "Incluir unidades de red",

        .wifiPermissionWarningShort: "Nombre de Wi-Fi no disponible — falta permiso de Localización",
        .wifiPermissionPrefsMessage: "Para mostrar el nombre de la red Wi-Fi, BGInfoMac necesita permiso de Localización. Activalo en Ajustes del Sistema → Privacidad y Seguridad → Localización.",
        .openSystemSettingsButton: "Abrir Ajustes del Sistema",
        .noNetworkConnection: "Sin conexión a la red",
        .speedTestButtonLabel: "Speedtest",
        .speedTestRunningLabel: "Midiendo…",
        .speedTestFailedLabel: "No se pudo medir",
        .speedTestResultFormat: "%.0f↓ / %.0f↑ Mbps",

        .storageUsedFreeTooltip: "%@ usados / %@ libres",
        .dnsMoreSuffix: "+%d más"
    ],
    .it: [
        .aboutMenuItem: "Informazioni su BGInfoMac",
        .showOverlay: "Mostra overlay desktop",
        .refreshEvery: "Aggiorna ogni",
        .intervalNever: "Mai",
        .interval5s: "5 secondi",
        .interval30s: "30 secondi",
        .interval1m: "1 minuto",
        .interval5m: "5 minuti",
        .refreshNow: "Aggiorna informazioni",
        .preferencesMenuItem: "Preferenze…",
        .quitMenuItem: "Esci",
        .helpMenuItem: "Aiuto",
        .helpWindowTitle: "Guida di BGInfoMac",
        .helpSearchPlaceholder: "Cerca…",
        .helpNoSelection: "Seleziona un argomento",

        .prefsWindowTitle: "Preferenze di BGInfoMac",
        .tabFields: "Campi",
        .tabAppearance: "Aspetto",

        .sectionSystem: "Sistema",
        .sectionHardware: "Hardware",
        .sectionStorage: "Archiviazione",
        .sectionNetwork: "Rete",
        .sectionMessage: "Messaggio",

        .fieldHostName: "Computer",
        .fieldUserName: "Utente",
        .fieldOSVersion: "SO",
        .fieldDateTime: "Data",
        .fieldSerialNumber: "Numero di Serie",
        .fieldOSBuild: "Build",
        .fieldMacModel: "Modello",
        .fieldChipName: "Chip",
        .fieldUptime: "Uptime",
        .fieldRAM: "RAM",
        .fieldBattery: "Batteria",
        .fieldCPUCores: "Core CPU",
        .fieldGPU: "GPU",
        .fieldWifiSSID: "Wi-Fi",
        .fieldInterfaces: "Interfacce di rete",
        .fieldPublicIP: "IP pubblico",
        .fieldGateway: "Gateway",
        .fieldDNSServers: "DNS",
        .fieldVPNProvider: "VPN",
        .fieldVPNTunnelIP: "IP del Tunnel",
        .fieldISPProvider: "Provider",

        .coresUnit: "core",
        .batteryHealthLabel: "salute",
        .batteryCyclesLabel: "cicli",
        .batteryTimeRemainingLabel: "rimanenti",
        .batteryTimeToFullLabel: "alla carica completa",

        .showTitleToggle: "Mostra titolo",
        .storageHint: "Tutti i volumi montati vengono mostrati automaticamente.",
        .messagePlaceholder: "Messaggio personalizzato…",

        .positionCornerLabel: "Angolo",
        .cornerTopLeft: "Alto a sinistra",
        .cornerTopRight: "Alto a destra",
        .cornerBottomLeft: "Basso a sinistra",
        .cornerBottomRight: "Basso a destra",
        .marginHorizontal: "Margine orizzontale",
        .marginVertical: "Margine verticale",

        .languageLabel: "Lingua",
        .appearanceLabel: "Aspetto dell'app",
        .appearanceSystem: "Sistema",
        .appearanceLight: "Chiaro",
        .appearanceDark: "Scuro",

        .textColorLabel: "Colore testo",
        .backgroundColorLabel: "Colore sfondo",
        .backgroundOpacityLabel: "Opacità sfondo",
        .fontSizeLabel: "Dimensione carattere",

        .aboutWindowTitle: "Informazioni su BGInfoMac",
        .aboutTagline: "Un'alternativa a BGInfo per macOS.",
        .developedByLabel: "Sviluppato da AMS",
        .donateButtonLabel: "Dona con PayPal",
        .githubLinkTitle: "Vai al progetto su GitHub",
        .donationPromptText: "Ti piace BGInfoMac? Considera di donare.",
        .donationPromptDisableHint: "⌘⇧D per non chiedere più",
        .versionLabel: "Versione",

        .launchAtLogin: "Avvia all'accesso",
        .exportSettingsButton: "Esporta impostazioni...",
        .importSettingsButton: "Importa impostazioni...",
        .exportSettingsSuccessTitle: "Impostazioni esportate",
        .exportSettingsSuccessMessage: "Le impostazioni sono state salvate correttamente.",
        .importSettingsSuccessTitle: "Impostazioni importate",
        .importSettingsSuccessMessage: "Le impostazioni sono state applicate correttamente.",
        .importSettingsErrorTitle: "Importazione non riuscita",
        .importSettingsErrorMessage: "Il file selezionato non è un file di configurazione BGInfoMac valido.",
        .displayTargetLabel: "Mostra su",
        .allDisplaysOption: "Tutti i display",

        .targetDesktop: "Scrivania",
        .targetMenuBar: "Barra dei menu",

        .interfaceWifiIP: "IP Wi-Fi",
        .interfaceEthernet: "Ethernet",

        .includeExternalVolumes: "Includi dischi esterni",
        .includeNetworkVolumes: "Includi unità di rete",

        .wifiPermissionWarningShort: "Nome Wi-Fi non disponibile — serve il permesso di Localizzazione",
        .wifiPermissionPrefsMessage: "Per mostrare il nome della rete Wi-Fi, BGInfoMac ha bisogno del permesso di Localizzazione. Attivalo in Impostazioni di Sistema → Privacy e Sicurezza → Localizzazione.",
        .openSystemSettingsButton: "Apri Impostazioni di Sistema",
        .noNetworkConnection: "Nessuna connessione di rete",
        .speedTestButtonLabel: "Speedtest",
        .speedTestRunningLabel: "Misurazione…",
        .speedTestFailedLabel: "Misurazione non riuscita",
        .speedTestResultFormat: "%.0f↓ / %.0f↑ Mbps",

        .storageUsedFreeTooltip: "%@ utilizzati / %@ liberi",
        .dnsMoreSuffix: "+%d altri"
    ],
    .de: [
        .aboutMenuItem: "Über BGInfoMac",
        .showOverlay: "Desktop-Overlay anzeigen",
        .refreshEvery: "Aktualisieren alle",
        .intervalNever: "Nie",
        .interval5s: "5 Sekunden",
        .interval30s: "30 Sekunden",
        .interval1m: "1 Minute",
        .interval5m: "5 Minuten",
        .refreshNow: "Informationen aktualisieren",
        .preferencesMenuItem: "Einstellungen…",
        .quitMenuItem: "Beenden",
        .helpMenuItem: "Hilfe",
        .helpWindowTitle: "BGInfoMac-Hilfe",
        .helpSearchPlaceholder: "Suchen…",
        .helpNoSelection: "Wähle ein Thema aus",

        .prefsWindowTitle: "BGInfoMac-Einstellungen",
        .tabFields: "Felder",
        .tabAppearance: "Erscheinungsbild",

        .sectionSystem: "System",
        .sectionHardware: "Hardware",
        .sectionStorage: "Speicher",
        .sectionNetwork: "Netzwerk",
        .sectionMessage: "Nachricht",

        .fieldHostName: "Computer",
        .fieldUserName: "Benutzer",
        .fieldOSVersion: "Betriebssystem",
        .fieldDateTime: "Datum",
        .fieldSerialNumber: "Seriennummer",
        .fieldOSBuild: "Build",
        .fieldMacModel: "Modell",
        .fieldChipName: "Chip",
        .fieldUptime: "Laufzeit",
        .fieldRAM: "RAM",
        .fieldBattery: "Akku",
        .fieldCPUCores: "CPU-Kerne",
        .fieldGPU: "GPU",
        .fieldWifiSSID: "Wi-Fi",
        .fieldInterfaces: "Netzwerkschnittstellen",
        .fieldPublicIP: "Öffentliche IP",
        .fieldGateway: "Gateway",
        .fieldDNSServers: "DNS",
        .fieldVPNProvider: "VPN",
        .fieldVPNTunnelIP: "Tunnel-IP",
        .fieldISPProvider: "Anbieter",

        .coresUnit: "Kerne",
        .batteryHealthLabel: "Zustand",
        .batteryCyclesLabel: "Zyklen",
        .batteryTimeRemainingLabel: "verbleibend",
        .batteryTimeToFullLabel: "bis vollständig geladen",

        .showTitleToggle: "Titel anzeigen",
        .storageHint: "Alle eingebundenen Volumes werden automatisch angezeigt.",
        .messagePlaceholder: "Benutzerdefinierte Nachricht…",

        .positionCornerLabel: "Ecke",
        .cornerTopLeft: "Oben links",
        .cornerTopRight: "Oben rechts",
        .cornerBottomLeft: "Unten links",
        .cornerBottomRight: "Unten rechts",
        .marginHorizontal: "Horizontaler Rand",
        .marginVertical: "Vertikaler Rand",

        .languageLabel: "Sprache",
        .appearanceLabel: "App-Erscheinungsbild",
        .appearanceSystem: "System",
        .appearanceLight: "Hell",
        .appearanceDark: "Dunkel",

        .textColorLabel: "Textfarbe",
        .backgroundColorLabel: "Hintergrundfarbe",
        .backgroundOpacityLabel: "Hintergrundtransparenz",
        .fontSizeLabel: "Schriftgröße",

        .aboutWindowTitle: "Über BGInfoMac",
        .aboutTagline: "Eine BGInfo-Alternative für macOS.",
        .developedByLabel: "Entwickelt von AMS",
        .donateButtonLabel: "Über PayPal spenden",
        .githubLinkTitle: "Zum Projekt auf GitHub",
        .donationPromptText: "Gefällt dir BGInfoMac? Erwäge eine Spende.",
        .donationPromptDisableHint: "⌘⇧D, um dies nicht mehr zu fragen",
        .versionLabel: "Version",

        .launchAtLogin: "Bei Anmeldung starten",
        .exportSettingsButton: "Einstellungen exportieren...",
        .importSettingsButton: "Einstellungen importieren...",
        .exportSettingsSuccessTitle: "Einstellungen exportiert",
        .exportSettingsSuccessMessage: "Die Einstellungen wurden erfolgreich gespeichert.",
        .importSettingsSuccessTitle: "Einstellungen importiert",
        .importSettingsSuccessMessage: "Die Einstellungen wurden erfolgreich angewendet.",
        .importSettingsErrorTitle: "Import fehlgeschlagen",
        .importSettingsErrorMessage: "Die ausgewählte Datei ist keine gültige BGInfoMac-Konfigurationsdatei.",
        .displayTargetLabel: "Anzeigen auf",
        .allDisplaysOption: "Alle Bildschirme",

        .targetDesktop: "Schreibtisch",
        .targetMenuBar: "Menüleiste",

        .interfaceWifiIP: "Wi-Fi-IP",
        .interfaceEthernet: "Ethernet",

        .includeExternalVolumes: "Externe Laufwerke einbeziehen",
        .includeNetworkVolumes: "Netzlaufwerke einbeziehen",

        .wifiPermissionWarningShort: "Wi-Fi-Name nicht verfügbar — Standortzugriff erforderlich",
        .wifiPermissionPrefsMessage: "Um den Namen des Wi-Fi-Netzwerks anzuzeigen, benötigt BGInfoMac die Berechtigung für den Standort. Aktiviere sie in den Systemeinstellungen → Datenschutz & Sicherheit → Ortungsdienste.",
        .openSystemSettingsButton: "Systemeinstellungen öffnen",
        .noNetworkConnection: "Keine Netzwerkverbindung",
        .speedTestButtonLabel: "Speedtest",
        .speedTestRunningLabel: "Wird gemessen…",
        .speedTestFailedLabel: "Messung fehlgeschlagen",
        .speedTestResultFormat: "%.0f↓ / %.0f↑ Mbps",

        .storageUsedFreeTooltip: "%@ belegt / %@ frei",
        .dnsMoreSuffix: "+%d weitere"
    ],
    .fr: [
        .aboutMenuItem: "À propos de BGInfoMac",
        .showOverlay: "Afficher l'incrustation bureau",
        .refreshEvery: "Actualiser toutes les",
        .intervalNever: "Jamais",
        .interval5s: "5 secondes",
        .interval30s: "30 secondes",
        .interval1m: "1 minute",
        .interval5m: "5 minutes",
        .refreshNow: "Actualiser les infos",
        .preferencesMenuItem: "Préférences…",
        .quitMenuItem: "Quitter",
        .helpMenuItem: "Aide",
        .helpWindowTitle: "Aide de BGInfoMac",
        .helpSearchPlaceholder: "Rechercher…",
        .helpNoSelection: "Sélectionnez un sujet",

        .prefsWindowTitle: "Préférences de BGInfoMac",
        .tabFields: "Champs",
        .tabAppearance: "Apparence",

        .sectionSystem: "Système",
        .sectionHardware: "Matériel",
        .sectionStorage: "Stockage",
        .sectionNetwork: "Réseau",
        .sectionMessage: "Message",

        .fieldHostName: "Ordinateur",
        .fieldUserName: "Utilisateur",
        .fieldOSVersion: "SE",
        .fieldDateTime: "Date",
        .fieldSerialNumber: "Numéro de Série",
        .fieldOSBuild: "Build",
        .fieldMacModel: "Modèle",
        .fieldChipName: "Puce",
        .fieldUptime: "Disponibilité",
        .fieldRAM: "RAM",
        .fieldBattery: "Batterie",
        .fieldCPUCores: "Cœurs CPU",
        .fieldGPU: "GPU",
        .fieldWifiSSID: "Wi-Fi",
        .fieldInterfaces: "Interfaces réseau",
        .fieldPublicIP: "IP publique",
        .fieldGateway: "Passerelle",
        .fieldDNSServers: "DNS",
        .fieldVPNProvider: "VPN",
        .fieldVPNTunnelIP: "IP du Tunnel",
        .fieldISPProvider: "Fournisseur",

        .coresUnit: "cœurs",
        .batteryHealthLabel: "santé",
        .batteryCyclesLabel: "cycles",
        .batteryTimeRemainingLabel: "restant",
        .batteryTimeToFullLabel: "jusqu'à charge complète",

        .showTitleToggle: "Afficher le titre",
        .storageHint: "Tous les volumes montés s'affichent automatiquement.",
        .messagePlaceholder: "Message personnalisé…",

        .positionCornerLabel: "Coin",
        .cornerTopLeft: "Haut gauche",
        .cornerTopRight: "Haut droite",
        .cornerBottomLeft: "Bas gauche",
        .cornerBottomRight: "Bas droite",
        .marginHorizontal: "Marge horizontale",
        .marginVertical: "Marge verticale",

        .languageLabel: "Langue",
        .appearanceLabel: "Apparence de l'app",
        .appearanceSystem: "Système",
        .appearanceLight: "Clair",
        .appearanceDark: "Sombre",

        .textColorLabel: "Couleur du texte",
        .backgroundColorLabel: "Couleur de fond",
        .backgroundOpacityLabel: "Opacité de l'arrière-plan",
        .fontSizeLabel: "Taille de police",

        .aboutWindowTitle: "À propos de BGInfoMac",
        .aboutTagline: "Une alternative à BGInfo pour macOS.",
        .developedByLabel: "Développé par AMS",
        .donateButtonLabel: "Faire un don via PayPal",
        .githubLinkTitle: "Accéder au projet sur GitHub",
        .donationPromptText: "Vous aimez BGInfoMac ? Pensez à faire un don.",
        .donationPromptDisableHint: "⌘⇧D pour ne plus demander",
        .versionLabel: "Version",

        .launchAtLogin: "Lancer à la connexion",
        .exportSettingsButton: "Exporter les réglages...",
        .importSettingsButton: "Importer les réglages...",
        .exportSettingsSuccessTitle: "Réglages exportés",
        .exportSettingsSuccessMessage: "Les réglages ont été enregistrés avec succès.",
        .importSettingsSuccessTitle: "Réglages importés",
        .importSettingsSuccessMessage: "Les réglages ont été appliqués avec succès.",
        .importSettingsErrorTitle: "Échec de l'importation",
        .importSettingsErrorMessage: "Le fichier sélectionné n'est pas un fichier de configuration BGInfoMac valide.",
        .displayTargetLabel: "Afficher sur",
        .allDisplaysOption: "Tous les écrans",

        .targetDesktop: "Bureau",
        .targetMenuBar: "Barre de menus",

        .interfaceWifiIP: "IP Wi-Fi",
        .interfaceEthernet: "Ethernet",

        .includeExternalVolumes: "Inclure les disques externes",
        .includeNetworkVolumes: "Inclure les disques réseau",

        .wifiPermissionWarningShort: "Nom du Wi-Fi indisponible — autorisation de localisation requise",
        .wifiPermissionPrefsMessage: "Pour afficher le nom du réseau Wi-Fi, BGInfoMac a besoin de l'autorisation de localisation. Activez-la dans Réglages Système → Confidentialité et sécurité → Service de localisation.",
        .openSystemSettingsButton: "Ouvrir Réglages Système",
        .noNetworkConnection: "Aucune connexion réseau",
        .speedTestButtonLabel: "Speedtest",
        .speedTestRunningLabel: "Mesure en cours…",
        .speedTestFailedLabel: "Échec de la mesure",
        .speedTestResultFormat: "%.0f↓ / %.0f↑ Mbps",

        .storageUsedFreeTooltip: "%@ utilisés / %@ libres",
        .dnsMoreSuffix: "+%d autres"
    ]
]

enum Localization {
    static func systemLanguage() -> AppLanguage {
        for preferred in Locale.preferredLanguages {
            let code = String(preferred.prefix(2)).lowercased()
            if let match = AppLanguage(rawValue: code) {
                return match
            }
        }
        return .en
    }

    static func effectiveLanguage(_ preference: AppLanguage) -> AppLanguage {
        preference == .system ? systemLanguage() : preference
    }
}

func L(_ key: LKey, _ language: AppLanguage) -> String {
    let resolved = Localization.effectiveLanguage(language)
    return translations[resolved]?[key] ?? translations[.en]?[key] ?? key.rawValue
}
