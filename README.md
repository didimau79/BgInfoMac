# BGInfoMac

Una alternativa nativa para macOS al clásico **BGInfo** de Windows: muestra información del sistema directamente sobre el fondo de escritorio (detrás de los íconos) y se controla desde un ícono en la barra de menú.

Versión actual: **2.0**.

## Qué muestra

- **Sistema**: nombre del equipo, usuario, versión de macOS con nombre comercial (ej. "macOS Tahoe 26.6.1"), fecha/hora.
- **Hardware**: modelo de Mac, chip, uptime, RAM usada/total.
- **Almacenamiento**: espacio usado/libre de cada volumen montado.
- **Red**: Wi-Fi conectado (si el sistema lo permite), todas las interfaces con IP local, e IP pública.
- **Mensaje**: un texto libre que definís vos (oculto por defecto).

Todo se actualiza automáticamente según el intervalo configurado (por defecto cada 30s). Tanto las secciones como los campos dentro de cada sección se pueden reordenar, mostrar/ocultar, y cada sección puede ocultar su título de forma independiente — todo desde **Preferencias**.

## Cómo compilar y ejecutar

Requiere Xcode Command Line Tools (ya instaladas) — no hace falta Xcode completo.

```bash
cd BGInfoMac
./Scripts/build_app.sh
open BGInfoMac.app
```

El script compila en modo release, arma `BGInfoMac.app` en la raíz del proyecto y lo firma ad-hoc (firma local, suficiente para correr en tu propia Mac).

También podés abrir `Package.swift` directamente con Xcode (`open Package.swift`) para editar/depurar con el IDE.

## Generar un instalador (.dmg)

Una vez compilada la app, `Scripts/build_dmg.sh` arma el típico DMG de macOS: al abrirlo aparece una ventana con el ícono de la app y un acceso directo a "Aplicaciones" al lado, listos para arrastrar uno sobre el otro.

```bash
./Scripts/build_app.sh
./Scripts/build_dmg.sh
```

Genera `BGInfoMac-Installer.dmg` en la raíz del proyecto. El script acomoda la ventana del Finder (tamaño, íconos grandes, sin barra de herramientas) usando AppleScript; si tu Mac no le dio permiso de Automatización a la Terminal, el DMG se genera igual, solo que sin ese acomodo prolijo — macOS te va a pedir ese permiso la primera vez que lo corras.

## Uso

La app no tiene ícono en el Dock — vive en la **barra de menú**.

- **Click izquierdo** en el ícono: abre un **popover** con la información del sistema (estilo iStat Menus), con su propio texto seleccionable.
- **Click derecho**: abre el menú de opciones, desde donde podés:
  - Ver "Acerca de BGInfoMac" (versión, año).
  - Mostrar/ocultar el overlay de escritorio.
  - Activar/desactivar "Iniciar al inicio de sesión".
  - Cambiar el intervalo de actualización (Nunca / 5s / 30s / 1m / 5m). "Nunca" desactiva el refresco automático; los datos solo se actualizan con "Refrescar información" o al cambiar una preferencia.
  - **Refrescar información** al instante (⌘R).
  - Abrir **Preferencias…** (⌘,) para toda la configuración detallada.
  - Salir de la app.

### Popover del menú vs. overlay de escritorio

El popover (click izquierdo) tiene su **propia configuración de secciones y campos**, totalmente independiente del overlay de escritorio — podés mostrar datos distintos en cada uno. Se configuran ambos desde Preferencias → Campos, con un selector arriba de todo para elegir si estás editando "Escritorio" o "Menú". El popover no tiene ajustes de posición/color propios: siempre aparece anclado debajo del ícono, con el estilo nativo de macOS (clic derecho para las demás opciones, sin conflicto con el overlay).

### Ventana de Preferencias

La ventana es **redimensionable** (tamaño mínimo 460×520) y tiene tres pestañas:

- **Campos**: un selector arriba elige si estás configurando el **Escritorio** o el **Menú** (popover) — cada uno guarda su propio orden y visibilidad, de forma independiente. Cada sección (Sistema, Hardware, Almacenamiento, Red, Mensaje) es una fila que se **arrastra hacia arriba/abajo** (ícono ☰) para cambiar el orden. Cada sección tiene:
  - Un toggle para mostrarla/ocultarla.
  - Un checkbox "Mostrar título" para ocultar solo el encabezado (ej. "SISTEMA") sin ocultar los datos.
  - Sus campos (Equipo, Usuario, SO, Fecha, Modelo, Chip, Uptime, RAM, Wi-Fi, Interfaces, IP Pública), también reordenables por separado arrastrándolos, cada uno con su propio toggle de visibilidad.
  - La sección **Mensaje** incluye una caja de texto para escribir un mensaje personalizado que aparece en el overlay como una sección más (reordenable junto a las demás).
- **Posición**: si hay más de un monitor conectado, aparece primero un selector "Mostrar en" (Todas las pantallas o una específica por nombre) — con un solo monitor este control no se muestra. Debajo, elegir la esquina de pantalla y dos sliders de **margen horizontal/vertical** (0–400pt) para correr el overlay más hacia el borde o hacia el centro — por ejemplo, bajarlo más si está anclado arriba.
- **Apariencia**: **Iniciar al inicio de sesión**, idioma de la app, apariencia (Sistema/Claro/Oscuro), color de texto, color de fondo, opacidad del panel de fondo y tamaño de fuente. Todo se aplica en vivo sobre el overlay.

Las preferencias se guardan en `UserDefaults` y persisten entre reinicios.

### Idioma

La app soporta **Español, English, Italiano, Deutsch y Français**. Por defecto usa el idioma del sistema operativo (si no es ninguno de los cinco, cae a inglés); se puede fijar manualmente desde Preferencias → Apariencia → Idioma.

### Apariencia clara/oscura

Por defecto la app sigue el modo del sistema. Desde Preferencias → Apariencia podés forzarla a Claro u Oscuro independientemente del resto de macOS.

## Iniciar automáticamente al iniciar sesión

Activá el toggle **"Iniciar al inicio de sesión"** desde el menú de la barra o desde Preferencias → Apariencia (usa `SMAppService`, la API moderna de macOS — no requiere tocar Ajustes del Sistema). Para que funcione de forma confiable, movés `BGInfoMac.app` a `/Applications` en vez de dejarla en el Escritorio.

## Multi-monitor

Con un solo monitor conectado no hay nada que configurar. Con **dos o más monitores**, Preferencias → Posición muestra un selector "Mostrar en" para elegir si el overlay aparece en **todas las pantallas** o solo en una en particular (identificada por su nombre). Si esa pantalla específica se desconecta más adelante, la app vuelve a mostrarlo en todas hasta que la reconectés.

## Notas

- El **SSID de Wi-Fi** puede no mostrarse en versiones recientes de macOS si el sistema no concede permiso de localización a la app; el resto de la información no depende de ningún permiso especial.
- La **IP pública** se obtiene con una petición HTTPS simple a `api.ipify.org`; si no hay conexión a internet, esa línea simplemente no aparece.
- El overlay se recrea automáticamente si conectás/desconectás monitores.
- Requiere macOS 13 (Ventura) o posterior, por el uso de `SMAppService` para "Iniciar al inicio de sesión".

## Estructura del proyecto

```
BGInfoMac/
├── Package.swift
├── Sources/BGInfoMac/
│   ├── main.swift                  # Entry point
│   ├── AppDelegate.swift           # Orquesta timer, captura de datos y overlay
│   ├── SystemInfoProvider.swift    # Recolección de datos del sistema (sysctl, IOKit, etc.)
│   ├── Preferences.swift           # Preferencias persistidas en UserDefaults
│   ├── LayoutConfig.swift          # Modelo de secciones/campos reordenables
│   ├── Localization.swift          # Strings en 5 idiomas + detección del sistema
│   ├── DragReorderableList.swift   # Componente genérico de arrastrar para reordenar
│   ├── DesktopOverlayController.swift  # Ventanas borderless a nivel de escritorio
│   ├── OverlayContentView.swift    # Vista SwiftUI del overlay de escritorio
│   ├── MenuPopoverView.swift       # Vista SwiftUI del popover (click izquierdo)
│   ├── MenuPopoverController.swift # NSPopover que hostea MenuPopoverView
│   ├── StatusBarController.swift   # Ícono, click izq./der. y menú de la barra
│   ├── PreferencesWindowController.swift  # Ventana de preferencias
│   ├── PreferencesView.swift       # UI de preferencias (campos, posición, apariencia)
│   ├── PreferencesViewModel.swift  # Puente ObservableObject <-> Preferences
│   ├── AboutWindowController.swift / AboutView.swift  # Ventana "Acerca de"
│   └── ColorHex.swift              # Conversión NSColor/Color <-> hex
├── Resources/
│   ├── Info.plist
│   ├── AppIcon.icns
│   ├── StatusIcon.png / StatusIcon@2x.png
│   └── IconSource/                 # PNGs maestros generados por Scripts/generate_icon.swift
└── Scripts/
    ├── build_app.sh                # Compila y empaqueta el .app
    ├── build_dmg.sh                # Genera el instalador .dmg (arrastrar a Aplicaciones)
    └── generate_icon.swift         # Genera los assets de ícono
```
