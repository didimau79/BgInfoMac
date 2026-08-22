import Foundation

struct HelpTopic: Identifiable, Hashable {
    let id: Int
    let title: String
    let body: [String]
}

enum HelpContent {
    /// Índice fijo (mismo en los 5 idiomas) del tema "Introducción" — HelpView
    /// lo usa para mostrar debajo el botón de donar.
    static let introductionTopicIndex = 0

    /// Índice fijo (mismo en los 5 idiomas) del tema "Permisos" — HelpView lo
    /// usa para mostrar debajo el botón que abre Ajustes del Sistema.
    static let permissionsTopicIndex = 11

    static func topics(for lang: AppLanguage) -> [HelpTopic] {
        let resolved = Localization.effectiveLanguage(lang)
        let entries = rawContent[resolved] ?? rawContent[.en] ?? []
        return entries.enumerated().map { HelpTopic(id: $0.offset, title: $0.element.0, body: $0.element.1) }
    }

    private static let rawContent: [AppLanguage: [(String, [String])]] = [
        .es: [
            (
                "Introducción",
                [
                    "BGInfoMac muestra información del sistema en dos lugares.",
                    "Como overlay en el escritorio, detrás de los íconos.",
                    "Y en una burbuja al hacer clic izquierdo en el ícono de la barra de menú.",
                    "Ambos se pueden configurar de forma totalmente independiente: qué mostrar, en qué orden, y con qué apariencia."
                ]
            ),
            (
                "Overlay de escritorio",
                [
                    "El overlay se dibuja detrás de los íconos del escritorio, en la esquina que elijas.",
                    "No interfiere con el uso normal del Finder.",
                    "Se activa o desactiva desde el menú, con \"Mostrar overlay de escritorio\".",
                    "Y podés elegir en qué pantalla aparece desde Preferencias → Campos → Escritorio → \"Mostrar en\"."
                ]
            ),
            (
                "Burbuja del menú",
                [
                    "Un clic izquierdo en el ícono de la barra de menú abre la burbuja.",
                    "Tiene su propia configuración independiente, en Preferencias → Campos → Menú.",
                    "Incluye barras gráficas para RAM y almacenamiento.",
                    "Y tooltips al pasar el mouse — por ejemplo sobre las barras, la bandera del país de la IP pública, o el \"+N\" de servidores DNS adicionales.",
                    "Se cierra sola al hacer clic afuera."
                ]
            ),
            (
                "Preferencias — Campos",
                [
                    "Elegí qué secciones y qué campos dentro de cada una se muestran.",
                    "Y en qué orden — se pueden arrastrar para reordenar.",
                    "Cada campo tiene su propio interruptor de visibilidad, y cada sección puede ocultar su título.",
                    "Esta configuración es independiente para el overlay de escritorio y para la burbuja del menú."
                ]
            ),
            (
                "Preferencias — Apariencia",
                [
                    "Controlá la esquina del overlay y los márgenes horizontal y vertical.",
                    "Los colores de texto y fondo, y la opacidad del fondo.",
                    "El tamaño de fuente.",
                    "Y si la aplicación usa apariencia clara, oscura, o la del sistema."
                ]
            ),
            (
                "Red y VPN",
                [
                    "La sección Red muestra la red Wi-Fi conectada, las interfaces locales, el proveedor de Internet, la IP pública, el gateway y los servidores DNS.",
                    "La IP pública se muestra con el país de origen, cuando se puede determinar.",
                    "Cuando hay una VPN conectada, sus datos se agrupan aparte, separados por una línea divisoria: Proveedor, VPN, IP del túnel, IP pública, gateway y DNS.",
                    "Si no hay ninguna conexión de red activa, la sección lo indica en vez de mostrar datos vacíos."
                ]
            ),
            (
                "Hardware",
                [
                    "Modelo de Mac, chip, y tiempo de actividad (uptime).",
                    "Uso de RAM, con barra gráfica en la burbuja que cambia de color según el porcentaje usado.",
                    "Batería, también con barra gráfica: azul de 100% a 50%, naranja de 49% a 15%, y rojo por debajo de 15%.",
                    "Salud y ciclos de carga aparecen al pasar el mouse sobre la barra de batería.",
                    "Núcleos de CPU, separados en rendimiento/eficiencia en Apple Silicon.",
                    "Y GPU: modelo y cantidad de núcleos, cuando se puede determinar."
                ]
            ),
            (
                "Almacenamiento",
                [
                    "Todos los volúmenes montados se muestran automáticamente.",
                    "Podés elegir si incluir discos externos y unidades de red, desde Preferencias → Campos → Almacenamiento.",
                    "En la burbuja, el uso se representa con una barra gráfica que cambia de color: azul por debajo de 80% usado, naranja de 80% a 89%, y rojo de 90% en adelante.",
                    "Al pasar el mouse por encima se ve el espacio usado y libre, y el formato del disco (APFS, NTFS, exFAT, etc.)."
                ]
            ),
            (
                "Selección de pantallas",
                [
                    "Si tenés más de un monitor, podés elegir en cuál (o en todos) se muestra el overlay.",
                    "Desde Preferencias → Campos → Escritorio → \"Mostrar en\".",
                    "La lista de pantallas se actualiza sola al conectar o desconectar un monitor."
                ]
            ),
            (
                "Idioma y apariencia de la app",
                [
                    "BGInfoMac está disponible en español, inglés, italiano, alemán y francés.",
                    "Podés fijar un idioma específico, o dejar que siga el idioma del sistema, desde Preferencias.",
                    "Este manual se adapta automáticamente al idioma elegido."
                ]
            ),
            (
                "Ejecutar al inicio y actualización",
                [
                    "Activá \"Ejecutar al inicio\" para que BGInfoMac se abra solo al iniciar sesión.",
                    "La información se actualiza sola, según el intervalo elegido en \"Actualizar cada\" — 5 segundos por defecto.",
                    "O podés forzar una actualización inmediata con ⌘R."
                ]
            ),
            (
                "Permisos",
                [
                    "BGInfoMac pide un solo permiso: Ubicación.",
                    "macOS lo exige para poder leer el nombre (SSID) de la red Wi-Fi conectada — es un requisito del sistema, no una elección de la app.",
                    "La ubicación real nunca se usa, no se guarda ni se envía a ningún lado.",
                    "Si no se concede, la app funciona igual — solo no va a poder mostrar el nombre de la red Wi-Fi.",
                    "Podés otorgarlo o revisarlo en cualquier momento desde Ajustes del Sistema → Privacidad y Seguridad → Localización."
                ]
            )
        ],
        .en: [
            (
                "Introduction",
                [
                    "BGInfoMac shows system information in two places.",
                    "As a desktop overlay, behind your desktop icons.",
                    "And in a bubble that opens when you left-click the menu bar icon.",
                    "Both can be configured completely independently: what to show, in what order, and with what appearance."
                ]
            ),
            (
                "Desktop overlay",
                [
                    "The overlay is drawn behind your desktop icons, in whichever corner you choose.",
                    "It doesn't interfere with normal Finder use.",
                    "Turn it on or off from the menu, with \"Show Desktop Overlay\".",
                    "And choose which screen it appears on from Preferences → Fields → Desktop → \"Show On\"."
                ]
            ),
            (
                "Menu bar bubble",
                [
                    "A left-click on the menu bar icon opens the bubble.",
                    "It has its own independent configuration, in Preferences → Fields → Menu.",
                    "It includes graphical bars for RAM and storage.",
                    "And tooltips on hover — for example over the bars, the public IP's country flag, or the \"+N\" for additional DNS servers.",
                    "It closes automatically when you click outside it."
                ]
            ),
            (
                "Preferences — Fields",
                [
                    "Choose which sections and which fields within each are shown.",
                    "And in what order — you can drag to reorder them.",
                    "Each field has its own visibility toggle, and each section can hide its title.",
                    "This configuration is independent for the desktop overlay and the menu bar bubble."
                ]
            ),
            (
                "Preferences — Appearance",
                [
                    "Control the overlay's corner and its horizontal and vertical margins.",
                    "Text and background colors, and background opacity.",
                    "Font size.",
                    "And whether the app uses light, dark, or system appearance."
                ]
            ),
            (
                "Network and VPN",
                [
                    "The Network section shows the connected Wi-Fi network, local interfaces, your Internet provider, your public IP, the gateway and the DNS servers.",
                    "The public IP is shown with its country of origin, when it can be determined.",
                    "When a VPN is connected, its data is grouped separately, below a divider line: Provider, VPN, tunnel IP, public IP, gateway and DNS.",
                    "If there's no active network connection at all, the section says so instead of showing empty data."
                ]
            ),
            (
                "Hardware",
                [
                    "Mac model, chip, and uptime.",
                    "RAM usage, with a graphical bar in the bubble that changes color based on how much is used.",
                    "Battery, also as a graphical bar: blue from 100% to 50%, orange from 49% to 15%, and red below 15%.",
                    "Health and cycle count show up when you hover over the battery bar.",
                    "CPU cores, split into performance/efficiency on Apple Silicon.",
                    "And GPU: model and core count, when it can be determined."
                ]
            ),
            (
                "Storage",
                [
                    "All mounted volumes are shown automatically.",
                    "You can choose whether to include external drives and network volumes, from Preferences → Fields → Storage.",
                    "In the bubble, usage is shown as a graphical bar that changes color: blue under 80% used, orange from 80% to 89%, and red from 90% up.",
                    "Hovering over it shows used and free space, and the disk format (APFS, NTFS, exFAT, etc.)."
                ]
            ),
            (
                "Display selection",
                [
                    "If you have more than one monitor, you can choose which one (or all of them) shows the overlay.",
                    "From Preferences → Fields → Desktop → \"Show On\".",
                    "The list of displays updates automatically when you connect or disconnect a monitor."
                ]
            ),
            (
                "Language and app appearance",
                [
                    "BGInfoMac is available in Spanish, English, Italian, German and French.",
                    "You can set a specific language, or let it follow your system language, from Preferences.",
                    "This manual automatically adapts to the language you choose."
                ]
            ),
            (
                "Launch at login and refresh",
                [
                    "Enable \"Launch at Login\" so BGInfoMac opens automatically when you sign in.",
                    "Information refreshes on its own, according to the interval chosen in \"Refresh Every\" — 5 seconds by default.",
                    "Or you can force an immediate refresh with ⌘R."
                ]
            ),
            (
                "Permissions",
                [
                    "BGInfoMac asks for a single permission: Location.",
                    "macOS requires it to read the connected Wi-Fi network's name (SSID) — it's a system requirement, not a choice made by the app.",
                    "Your actual location is never used, stored, or sent anywhere.",
                    "If you don't grant it, the app still works fine — it just won't be able to show the Wi-Fi network name.",
                    "You can grant or review it anytime from System Settings → Privacy & Security → Location Services."
                ]
            )
        ],
        .it: [
            (
                "Introduzione",
                [
                    "BGInfoMac mostra le informazioni di sistema in due punti.",
                    "Come overlay sulla scrivania, dietro le icone del desktop.",
                    "E in una bolla che si apre con un clic sinistro sull'icona nella barra dei menu.",
                    "Entrambi si possono configurare in modo completamente indipendente: cosa mostrare, in che ordine, e con quale aspetto."
                ]
            ),
            (
                "Overlay desktop",
                [
                    "L'overlay viene disegnato dietro le icone del desktop, nell'angolo che preferisci.",
                    "Non interferisce con il normale uso del Finder.",
                    "Si attiva o disattiva dal menu, con \"Mostra overlay desktop\".",
                    "E puoi scegliere su quale schermo appare da Preferenze → Campi → Scrivania → \"Mostra su\"."
                ]
            ),
            (
                "Bolla della barra dei menu",
                [
                    "Un clic sinistro sull'icona nella barra dei menu apre la bolla.",
                    "Ha una configurazione propria e indipendente, in Preferenze → Campi → Menu.",
                    "Include barre grafiche per RAM e archiviazione.",
                    "E suggerimenti al passaggio del mouse — ad esempio sulle barre, sulla bandiera del paese dell'IP pubblico, o sul \"+N\" dei server DNS aggiuntivi.",
                    "Si chiude da sola quando fai clic fuori da essa."
                ]
            ),
            (
                "Preferenze — Campi",
                [
                    "Scegli quali sezioni e quali campi al loro interno vengono mostrati.",
                    "E in che ordine — puoi trascinarli per riordinarli.",
                    "Ogni campo ha il proprio interruttore di visibilità, e ogni sezione può nascondere il proprio titolo.",
                    "Questa configurazione è indipendente per l'overlay desktop e per la bolla della barra dei menu."
                ]
            ),
            (
                "Preferenze — Aspetto",
                [
                    "Controlla l'angolo dell'overlay e i margini orizzontale e verticale.",
                    "I colori di testo e sfondo, e l'opacità dello sfondo.",
                    "La dimensione del carattere.",
                    "E se l'app usa l'aspetto chiaro, scuro, o quello di sistema."
                ]
            ),
            (
                "Rete e VPN",
                [
                    "La sezione Rete mostra la rete Wi-Fi connessa, le interfacce locali, il tuo provider Internet, il tuo IP pubblico, il gateway e i server DNS.",
                    "L'IP pubblico viene mostrato con il paese di origine, quando è possibile determinarlo.",
                    "Quando è connessa una VPN, i suoi dati vengono raggruppati a parte, sotto una linea divisoria: Provider, VPN, IP del tunnel, IP pubblico, gateway e DNS.",
                    "Se non c'è alcuna connessione di rete attiva, la sezione lo indica invece di mostrare dati vuoti."
                ]
            ),
            (
                "Hardware",
                [
                    "Modello del Mac, chip, e tempo di attività (uptime).",
                    "Utilizzo della RAM, con barra grafica nella bolla che cambia colore in base alla percentuale usata.",
                    "Batteria, anch'essa con barra grafica: blu dal 100% al 50%, arancione dal 49% al 15%, e rossa sotto il 15%.",
                    "Salute e cicli di carica appaiono passando il mouse sulla barra della batteria.",
                    "Core della CPU, divisi in prestazioni/efficienza su Apple Silicon.",
                    "E GPU: modello e numero di core, quando è possibile determinarlo."
                ]
            ),
            (
                "Archiviazione",
                [
                    "Tutti i volumi montati vengono mostrati automaticamente.",
                    "Puoi scegliere se includere dischi esterni e unità di rete, da Preferenze → Campi → Archiviazione.",
                    "Nella bolla, l'utilizzo è rappresentato con una barra grafica che cambia colore: blu sotto l'80% usato, arancione dall'80% all'89%, e rossa dal 90% in su.",
                    "Passando il mouse sopra si vede lo spazio usato e libero, e il formato del disco (APFS, NTFS, exFAT, ecc.)."
                ]
            ),
            (
                "Selezione degli schermi",
                [
                    "Se hai più di un monitor, puoi scegliere su quale (o su tutti) viene mostrato l'overlay.",
                    "Da Preferenze → Campi → Scrivania → \"Mostra su\".",
                    "L'elenco degli schermi si aggiorna da solo quando colleghi o scolleghi un monitor."
                ]
            ),
            (
                "Lingua e aspetto dell'app",
                [
                    "BGInfoMac è disponibile in spagnolo, inglese, italiano, tedesco e francese.",
                    "Puoi impostare una lingua specifica, o lasciare che segua la lingua di sistema, da Preferenze.",
                    "Questo manuale si adatta automaticamente alla lingua scelta."
                ]
            ),
            (
                "Avvio automatico e aggiornamento",
                [
                    "Attiva \"Avvia all'accesso\" affinché BGInfoMac si apra da solo all'accesso.",
                    "Le informazioni si aggiornano da sole, in base all'intervallo scelto in \"Aggiorna ogni\" — 5 secondi di default.",
                    "Oppure puoi forzare un aggiornamento immediato con ⌘R."
                ]
            ),
            (
                "Permessi",
                [
                    "BGInfoMac richiede un solo permesso: Localizzazione.",
                    "macOS lo richiede per poter leggere il nome (SSID) della rete Wi-Fi connessa — è un requisito di sistema, non una scelta dell'app.",
                    "La posizione reale non viene mai usata, salvata o inviata da nessuna parte.",
                    "Se non lo concedi, l'app funziona comunque — semplicemente non potrà mostrare il nome della rete Wi-Fi.",
                    "Puoi concederlo o rivederlo in qualsiasi momento da Impostazioni di Sistema → Privacy e Sicurezza → Localizzazione."
                ]
            )
        ],
        .de: [
            (
                "Einführung",
                [
                    "BGInfoMac zeigt Systeminformationen an zwei Stellen.",
                    "Als Desktop-Overlay, hinter deinen Schreibtischsymbolen.",
                    "Und in einer Sprechblase, die sich per Linksklick auf das Menüleistensymbol öffnet.",
                    "Beide lassen sich völlig unabhängig konfigurieren: was angezeigt wird, in welcher Reihenfolge, und mit welchem Erscheinungsbild."
                ]
            ),
            (
                "Desktop-Overlay",
                [
                    "Das Overlay wird hinter deinen Schreibtischsymbolen gezeichnet, in der von dir gewählten Ecke.",
                    "Es stört die normale Finder-Nutzung nicht.",
                    "Über das Menü ein- oder ausschalten, mit \"Desktop-Overlay anzeigen\".",
                    "Und wähle in den Einstellungen → Felder → Schreibtisch → \"Anzeigen auf\", auf welchem Bildschirm es erscheint."
                ]
            ),
            (
                "Sprechblase der Menüleiste",
                [
                    "Ein Linksklick auf das Menüleistensymbol öffnet die Sprechblase.",
                    "Sie hat eine eigene, unabhängige Konfiguration, in Einstellungen → Felder → Menü.",
                    "Sie enthält grafische Balken für RAM und Speicher.",
                    "Und Tooltips beim Überfahren mit der Maus — zum Beispiel über den Balken, der Länderflagge der öffentlichen IP, oder dem \"+N\" für weitere DNS-Server.",
                    "Sie schließt sich automatisch, wenn du außerhalb klickst."
                ]
            ),
            (
                "Einstellungen — Felder",
                [
                    "Lege fest, welche Abschnitte und welche Felder darin angezeigt werden.",
                    "Und in welcher Reihenfolge — per Drag & Drop neu anordnen.",
                    "Jedes Feld hat einen eigenen Sichtbarkeitsschalter, und jeder Abschnitt kann seinen Titel ausblenden.",
                    "Diese Einstellung ist für das Desktop-Overlay und die Sprechblase der Menüleiste unabhängig."
                ]
            ),
            (
                "Einstellungen — Erscheinungsbild",
                [
                    "Steuere die Ecke des Overlays und den horizontalen und vertikalen Rand.",
                    "Text- und Hintergrundfarbe, und die Hintergrundtransparenz.",
                    "Die Schriftgröße.",
                    "Und ob die App ein helles, dunkles, oder das Systemerscheinungsbild verwendet."
                ]
            ),
            (
                "Netzwerk und VPN",
                [
                    "Der Netzwerk-Abschnitt zeigt das verbundene Wi-Fi-Netzwerk, lokale Schnittstellen, deinen Internetanbieter, deine öffentliche IP, das Gateway und die DNS-Server.",
                    "Die öffentliche IP wird mit ihrem Herkunftsland angezeigt, sofern ermittelbar.",
                    "Ist ein VPN verbunden, werden dessen Daten getrennt unter einer Trennlinie gruppiert: Anbieter, VPN, Tunnel-IP, öffentliche IP, Gateway und DNS.",
                    "Besteht überhaupt keine aktive Netzwerkverbindung, zeigt der Abschnitt das an, statt leere Daten anzuzeigen."
                ]
            ),
            (
                "Hardware",
                [
                    "Mac-Modell, Chip, und Laufzeit (Uptime).",
                    "RAM-Nutzung, mit grafischem Balken in der Sprechblase, der je nach genutztem Anteil die Farbe wechselt.",
                    "Akku, ebenfalls als grafischer Balken: Blau von 100% bis 50%, Orange von 49% bis 15%, und Rot unter 15%.",
                    "Zustand und Ladezyklen erscheinen, wenn du mit der Maus über den Akku-Balken fährst.",
                    "CPU-Kerne, bei Apple Silicon getrennt nach Performance-/Effizienzkernen.",
                    "Und GPU: Modell und Kernanzahl, sofern ermittelbar."
                ]
            ),
            (
                "Speicher",
                [
                    "Alle eingebundenen Volumes werden automatisch angezeigt.",
                    "Du kannst festlegen, ob externe Laufwerke und Netzlaufwerke einbezogen werden, in Einstellungen → Felder → Speicher.",
                    "In der Sprechblase wird die Nutzung als grafischer Balken dargestellt, der die Farbe wechselt: Blau unter 80% Nutzung, Orange von 80% bis 89%, und Rot ab 90%.",
                    "Beim Überfahren mit der Maus siehst du belegten und freien Speicherplatz, und das Laufwerksformat (APFS, NTFS, exFAT usw.)."
                ]
            ),
            (
                "Bildschirmauswahl",
                [
                    "Wenn du mehr als einen Monitor hast, kannst du festlegen, auf welchem (oder auf allen) das Overlay angezeigt wird.",
                    "In den Einstellungen → Felder → Schreibtisch → \"Anzeigen auf\".",
                    "Die Bildschirmliste aktualisiert sich automatisch, wenn du einen Monitor an- oder abschließt."
                ]
            ),
            (
                "Sprache und App-Erscheinungsbild",
                [
                    "BGInfoMac ist auf Spanisch, Englisch, Italienisch, Deutsch und Französisch verfügbar.",
                    "Du kannst in den Einstellungen eine bestimmte Sprache festlegen, oder die Systemsprache übernehmen lassen.",
                    "Dieses Handbuch passt sich automatisch an die gewählte Sprache an."
                ]
            ),
            (
                "Start bei Anmeldung und Aktualisierung",
                [
                    "Aktiviere \"Bei Anmeldung starten\", damit sich BGInfoMac automatisch bei der Anmeldung öffnet.",
                    "Die Informationen aktualisieren sich von selbst, gemäß dem in \"Aktualisieren alle\" gewählten Intervall — standardmäßig 5 Sekunden.",
                    "Oder du erzwingst eine sofortige Aktualisierung mit ⌘R."
                ]
            ),
            (
                "Berechtigungen",
                [
                    "BGInfoMac benötigt nur eine Berechtigung: Standort.",
                    "macOS verlangt sie, um den Namen (SSID) des verbundenen Wi-Fi-Netzwerks lesen zu können — das ist eine Systemanforderung, keine Entscheidung der App.",
                    "Dein tatsächlicher Standort wird niemals verwendet, gespeichert oder irgendwohin gesendet.",
                    "Ohne diese Berechtigung funktioniert die App trotzdem — sie kann nur den Namen des Wi-Fi-Netzwerks nicht anzeigen.",
                    "Du kannst sie jederzeit über Systemeinstellungen → Datenschutz & Sicherheit → Ortungsdienste erteilen oder überprüfen."
                ]
            )
        ],
        .fr: [
            (
                "Introduction",
                [
                    "BGInfoMac affiche des informations système à deux endroits.",
                    "En incrustation sur le bureau, derrière les icônes.",
                    "Et dans une bulle qui s'ouvre par un clic gauche sur l'icône de la barre de menus.",
                    "Les deux peuvent être configurés de manière totalement indépendante : quoi afficher, dans quel ordre, et avec quelle apparence."
                ]
            ),
            (
                "Incrustation bureau",
                [
                    "L'incrustation est dessinée derrière les icônes du bureau, dans le coin de votre choix.",
                    "Elle n'interfère pas avec l'utilisation normale du Finder.",
                    "Activez-la ou désactivez-la depuis le menu, avec \"Afficher l'incrustation bureau\".",
                    "Et choisissez sur quel écran elle apparaît depuis Préférences → Champs → Bureau → \"Afficher sur\"."
                ]
            ),
            (
                "Bulle de la barre de menus",
                [
                    "Un clic gauche sur l'icône de la barre de menus ouvre la bulle.",
                    "Elle a sa propre configuration indépendante, dans Préférences → Champs → Menu.",
                    "Elle inclut des barres graphiques pour la RAM et le stockage.",
                    "Et des info-bulles au survol — par exemple sur les barres, le drapeau du pays de l'IP publique, ou le \"+N\" des serveurs DNS supplémentaires.",
                    "Elle se ferme automatiquement lorsque vous cliquez en dehors."
                ]
            ),
            (
                "Préférences — Champs",
                [
                    "Choisissez quelles sections et quels champs de chacune sont affichés.",
                    "Et dans quel ordre — vous pouvez les glisser pour les réorganiser.",
                    "Chaque champ possède son propre interrupteur de visibilité, et chaque section peut masquer son titre.",
                    "Cette configuration est indépendante pour l'incrustation bureau et pour la bulle de la barre de menus."
                ]
            ),
            (
                "Préférences — Apparence",
                [
                    "Contrôlez le coin de l'incrustation et ses marges horizontale et verticale.",
                    "Les couleurs du texte et du fond, et l'opacité de l'arrière-plan.",
                    "La taille de police.",
                    "Et si l'application utilise l'apparence claire, sombre, ou celle du système."
                ]
            ),
            (
                "Réseau et VPN",
                [
                    "La section Réseau affiche le réseau Wi-Fi connecté, les interfaces locales, votre fournisseur Internet, votre IP publique, la passerelle et les serveurs DNS.",
                    "L'IP publique est affichée avec son pays d'origine, lorsqu'il peut être déterminé.",
                    "Lorsqu'un VPN est connecté, ses données sont regroupées à part, sous une ligne de séparation : Fournisseur, VPN, IP du tunnel, IP publique, passerelle et DNS.",
                    "S'il n'y a aucune connexion réseau active, la section l'indique au lieu d'afficher des données vides."
                ]
            ),
            (
                "Matériel",
                [
                    "Modèle du Mac, puce, et durée de fonctionnement (uptime).",
                    "Utilisation de la RAM, avec une barre graphique dans la bulle qui change de couleur selon le pourcentage utilisé.",
                    "Batterie, également sous forme de barre graphique : bleu de 100% à 50%, orange de 49% à 15%, et rouge sous 15%.",
                    "La santé et les cycles de charge apparaissent en survolant la barre de batterie.",
                    "Cœurs du CPU, séparés en performance/efficacité sur Apple Silicon.",
                    "Et GPU : modèle et nombre de cœurs, lorsque cela peut être déterminé."
                ]
            ),
            (
                "Stockage",
                [
                    "Tous les volumes montés s'affichent automatiquement.",
                    "Vous pouvez choisir d'inclure les disques externes et les disques réseau, depuis Préférences → Champs → Stockage.",
                    "Dans la bulle, l'utilisation est représentée par une barre graphique qui change de couleur : bleu sous 80% utilisé, orange de 80% à 89%, et rouge à partir de 90%.",
                    "En survolant celle-ci, vous voyez l'espace utilisé et libre, et le format du disque (APFS, NTFS, exFAT, etc.)."
                ]
            ),
            (
                "Sélection des écrans",
                [
                    "Si vous avez plusieurs moniteurs, vous pouvez choisir sur lequel (ou sur tous) l'incrustation s'affiche.",
                    "Depuis Préférences → Champs → Bureau → \"Afficher sur\".",
                    "La liste des écrans se met à jour automatiquement lorsque vous connectez ou déconnectez un moniteur."
                ]
            ),
            (
                "Langue et apparence de l'app",
                [
                    "BGInfoMac est disponible en espagnol, anglais, italien, allemand et français.",
                    "Vous pouvez définir une langue précise, ou laisser l'application suivre la langue du système, depuis les Préférences.",
                    "Ce manuel s'adapte automatiquement à la langue choisie."
                ]
            ),
            (
                "Lancement à la connexion et actualisation",
                [
                    "Activez \"Lancer à la connexion\" pour que BGInfoMac s'ouvre automatiquement à la connexion.",
                    "Les informations s'actualisent seules, selon l'intervalle choisi dans \"Actualiser toutes les\" — 5 secondes par défaut.",
                    "Ou vous pouvez forcer une actualisation immédiate avec ⌘R."
                ]
            ),
            (
                "Autorisations",
                [
                    "BGInfoMac ne demande qu'une seule autorisation : Localisation.",
                    "macOS l'exige pour pouvoir lire le nom (SSID) du réseau Wi-Fi connecté — c'est une exigence du système, pas un choix de l'application.",
                    "Votre position réelle n'est jamais utilisée, enregistrée, ni envoyée où que ce soit.",
                    "Si vous ne l'accordez pas, l'application fonctionne quand même — elle ne pourra simplement pas afficher le nom du réseau Wi-Fi.",
                    "Vous pouvez l'accorder ou la vérifier à tout moment depuis Réglages Système → Confidentialité et sécurité → Service de localisation."
                ]
            )
        ]
    ]
}
