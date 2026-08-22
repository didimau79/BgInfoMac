#!/usr/bin/env swift
import AppKit

// Genera el icono de la app (monitor con líneas de info, estilo BGInfo) y el
// glyph monocromático para la barra de menú.

let rootURL = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
let iconSourceDir = rootURL.appendingPathComponent("IconSource")
try? FileManager.default.createDirectory(at: iconSourceDir, withIntermediateDirectories: true)

func renderImage(size: CGFloat, draw: (CGRect) -> Void) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    draw(CGRect(x: 0, y: 0, width: size, height: size))
    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, to url: URL) {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("No se pudo generar PNG para \(url)")
    }
    try? data.write(to: url)
}

// MARK: - Glyph: monitor con líneas de info

func drawMonitorGlyph(in rect: CGRect, monochrome: Bool) {
    let w = rect.width
    let h = rect.height

    let bezelColor = monochrome ? NSColor.black : NSColor(calibratedRed: 0.80, green: 0.83, blue: 0.87, alpha: 1.0)
    let screenColor = NSColor(calibratedRed: 0.09, green: 0.18, blue: 0.33, alpha: 1.0)
    let lineColor = monochrome ? NSColor.black : NSColor(calibratedRed: 0.94, green: 0.97, blue: 1.0, alpha: 1.0)
    let standColor = monochrome ? NSColor.black : NSColor(calibratedRed: 0.62, green: 0.66, blue: 0.71, alpha: 1.0)

    // Base / pie del monitor
    let baseWidth = w * 0.34
    let baseHeight = h * (monochrome ? 0.075 : 0.05)
    let baseRect = CGRect(x: rect.midX - baseWidth / 2, y: rect.minY + h * 0.06, width: baseWidth, height: baseHeight)
    let basePath = NSBezierPath(roundedRect: baseRect, xRadius: baseHeight * 0.4, yRadius: baseHeight * 0.4)
    standColor.setFill()
    basePath.fill()

    // Cuello del monitor
    let neckWidth = w * (monochrome ? 0.16 : 0.12)
    let neckHeight = h * (monochrome ? 0.11 : 0.09)
    let neckRect = CGRect(x: rect.midX - neckWidth / 2, y: baseRect.maxY - baseHeight * 0.2, width: neckWidth, height: neckHeight)
    standColor.setFill()
    NSBezierPath(rect: neckRect).fill()

    // Bezel (marco del monitor)
    let bezelRect = CGRect(x: rect.minX + w * 0.12, y: neckRect.maxY - h * 0.01, width: w * 0.76, height: h * 0.62)
    let bezelPath = NSBezierPath(roundedRect: bezelRect, xRadius: w * 0.045, yRadius: w * 0.045)
    if monochrome {
        // Solo el contorno, para que el interior quede hueco/transparente y las líneas se vean.
        bezelPath.lineWidth = w * 0.10
        bezelColor.setStroke()
        bezelPath.stroke()
    } else {
        bezelColor.setFill()
        bezelPath.fill()
    }

    // Pantalla (interior)
    let inset = w * 0.06
    let screenRect = bezelRect.insetBy(dx: inset, dy: inset)
    if !monochrome {
        let screenPath = NSBezierPath(roundedRect: screenRect, xRadius: w * 0.02, yRadius: w * 0.02)
        screenColor.setFill()
        screenPath.fill()
    }

    // Líneas de "info" dentro de la pantalla
    let lineWidths: [CGFloat] = [0.78, 0.55, 0.68, 0.42, 0.60]
    let lineCount = lineWidths.count
    let lineHeight = screenRect.height * (monochrome ? 0.15 : 0.09)
    let topPadding = screenRect.height * (monochrome ? 0.19 : 0.12)
    let spacing = (screenRect.height - topPadding * 1.6) / CGFloat(lineCount - 1)
    let leftInset = screenRect.width * 0.12

    for (index, widthFraction) in lineWidths.enumerated() {
        let y = screenRect.maxY - topPadding - CGFloat(index) * spacing
        let lineRect = CGRect(
            x: screenRect.minX + leftInset,
            y: y,
            width: (screenRect.width - leftInset * 2) * widthFraction,
            height: lineHeight
        )
        let linePath = NSBezierPath(roundedRect: lineRect, xRadius: lineHeight / 2, yRadius: lineHeight / 2)
        lineColor.setFill()
        linePath.fill()
    }
}

// MARK: - Icono de la app (con fondo squircle)

func drawAppIcon(in rect: CGRect) {
    let w = rect.width
    let h = rect.height

    let backgroundPath = NSBezierPath(roundedRect: rect, xRadius: w * 0.225, yRadius: h * 0.225)
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.16, green: 0.42, blue: 0.78, alpha: 1.0),
        NSColor(calibratedRed: 0.07, green: 0.20, blue: 0.44, alpha: 1.0)
    ])
    gradient?.draw(in: backgroundPath, angle: -90)

    let glyphRect = rect.insetBy(dx: w * 0.16, dy: h * 0.16)
    drawMonitorGlyph(in: glyphRect, monochrome: false)
}

// MARK: - Generación de archivos

let appIconMasterSize: CGFloat = 1024
let appIconImage = renderImage(size: appIconMasterSize) { rect in
    drawAppIcon(in: rect)
}
savePNG(appIconImage, to: iconSourceDir.appendingPathComponent("AppIcon-1024.png"))

let statusIconMasterSize: CGFloat = 256
let statusIconImage = renderImage(size: statusIconMasterSize) { rect in
    let inset = rect.width * 0.06
    drawMonitorGlyph(in: rect.insetBy(dx: inset, dy: inset), monochrome: true)
}
savePNG(statusIconImage, to: iconSourceDir.appendingPathComponent("StatusIcon-master.png"))

print("OK: assets generados en \(iconSourceDir.path)")
