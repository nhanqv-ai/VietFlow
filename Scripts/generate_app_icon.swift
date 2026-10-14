import Cocoa
import CoreGraphics

public final class CapsuleIconRenderer {
    
    public static func render(size: CGFloat) -> NSImage {
        let scale = size / 1024.0
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }
        
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        ctx.interpolationQuality = .high
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        // ---------------------------------------------------------------------
        // 1. MAC OS SQUIRCLE CHASSIS & DROP SHADOW
        // ---------------------------------------------------------------------
        let margin = 96.0 * scale
        let squircleSize = size - 2 * margin
        let cornerRadius = 188.0 * scale
        let squircleRect = CGRect(x: margin, y: margin, width: squircleSize, height: squircleSize)
        let squirclePath = CGPath(
            roundedRect: squircleRect,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )
        
        // Canvas Elevation Drop Shadow (Apple Dock standard)
        ctx.saveGState()
        ctx.setShadow(
            offset: CGSize(width: 0, height: -24.0 * scale),
            blur: 36.0 * scale,
            color: NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.60).cgColor
        )
        ctx.addPath(squirclePath)
        ctx.setFillColor(NSColor.black.cgColor)
        ctx.fillPath()
        ctx.restoreGState()
        
        // Clip all interior elements to squircle
        ctx.saveGState()
        ctx.addPath(squirclePath)
        ctx.clip()
        
        // Space Obsidian / Titanium Chassis Gradient
        let chassisColors = [
            NSColor(red: 0.13, green: 0.15, blue: 0.22, alpha: 1.0).cgColor,
            NSColor(red: 0.07, green: 0.08, blue: 0.14, alpha: 1.0).cgColor,
            NSColor(red: 0.03, green: 0.04, blue: 0.07, alpha: 1.0).cgColor
        ] as CFArray
        if let chassisGrad = CGGradient(colorsSpace: colorSpace, colors: chassisColors, locations: [0.0, 0.45, 1.0]) {
            ctx.drawLinearGradient(
                chassisGrad,
                start: CGPoint(x: margin, y: size - margin),
                end: CGPoint(x: size - margin, y: margin),
                options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
            )
        }
        
        // ---------------------------------------------------------------------
        // 2. INNER RECESSED KEYCAP DISH
        // ---------------------------------------------------------------------
        let dishInset = 34.0 * scale
        let dishMargin = margin + dishInset
        let dishSize = size - 2 * dishMargin
        let dishRadius = cornerRadius - 26.0 * scale
        let dishRect = CGRect(x: dishMargin, y: dishMargin, width: dishSize, height: dishSize)
        let dishPath = CGPath(
            roundedRect: dishRect,
            cornerWidth: dishRadius,
            cornerHeight: dishRadius,
            transform: nil
        )
        
        ctx.saveGState()
        ctx.addPath(dishPath)
        ctx.clip()
        
        let dishColors = [
            NSColor(red: 0.05, green: 0.06, blue: 0.10, alpha: 1.0).cgColor,
            NSColor(red: 0.08, green: 0.10, blue: 0.16, alpha: 1.0).cgColor,
            NSColor(red: 0.04, green: 0.05, blue: 0.08, alpha: 1.0).cgColor
        ] as CFArray
        if let dishGrad = CGGradient(colorsSpace: colorSpace, colors: dishColors, locations: [0.0, 0.50, 1.0]) {
            ctx.drawLinearGradient(
                dishGrad,
                start: CGPoint(x: size * 0.5, y: size - dishMargin),
                end: CGPoint(x: size * 0.5, y: dishMargin),
                options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
            )
        }
        
        // Ambient Center Glow Pool
        if let glowPool = CGGradient(
            colorsSpace: colorSpace,
            colors: [
                NSColor(red: 0.12, green: 0.32, blue: 0.65, alpha: 0.28).cgColor,
                NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0).cgColor
            ] as CFArray,
            locations: [0.0, 1.0]
        ) {
            ctx.drawRadialGradient(
                glowPool,
                startCenter: CGPoint(x: size * 0.5, y: size * 0.48),
                startRadius: 0,
                endCenter: CGPoint(x: size * 0.5, y: size * 0.48),
                endRadius: 380 * scale,
                options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
            )
        }
        
        // Acoustic Cadence / Flow Waves
        for i in 0..<8 {
            let waveY = (dishMargin + 70 * scale) + CGFloat(i) * (42 * scale)
            let wavePath = CGMutablePath()
            wavePath.move(to: CGPoint(x: dishMargin + 25 * scale, y: waveY))
            wavePath.addCurve(
                to: CGPoint(x: size - dishMargin - 25 * scale, y: waveY),
                control1: CGPoint(x: size * 0.35, y: waveY + 12 * scale),
                control2: CGPoint(x: size * 0.65, y: waveY - 12 * scale)
            )
            ctx.saveGState()
            ctx.addPath(wavePath)
            ctx.setStrokeColor(NSColor(red: 0.35, green: 0.55, blue: 0.90, alpha: 0.035).cgColor)
            ctx.setLineWidth(1.5 * scale)
            ctx.strokePath()
            ctx.restoreGState()
        }
        
        ctx.restoreGState() // End dish clip
        
        // Dish Rim Specular Stroke
        ctx.saveGState()
        ctx.addPath(dishPath)
        ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.10).cgColor)
        ctx.setLineWidth(1.5 * scale)
        ctx.strokePath()
        ctx.restoreGState()
        
        // Squircle Rim Specular Stroke
        ctx.saveGState()
        ctx.addPath(squirclePath)
        ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.18).cgColor)
        ctx.setLineWidth(2.0 * scale)
        ctx.strokePath()
        ctx.restoreGState()
        
        // ---------------------------------------------------------------------
        // 3. FLAWLESS 'V' (WATERTIGHT QUAD-TANGENT ARCS)
        // ---------------------------------------------------------------------
        let cx = size * 0.5
        let armHalfW: CGFloat = 46.0 * scale
        let topY: CGFloat = 630.0 * scale
        
        let leftTopCenter = CGPoint(x: cx - 138.0 * scale, y: topY)
        let rightTopCenter = CGPoint(x: cx + 138.0 * scale, y: topY)
        
        let sharpApex = CGPoint(x: cx, y: 210.0 * scale)
        let sharpCrotch = CGPoint(x: cx, y: 395.0 * scale)
        
        let apexRadius: CGFloat = 44.0 * scale
        let crotchRadius: CGFloat = 28.0 * scale
        
        // Right arm unit vectors
        let rDx = rightTopCenter.x - sharpApex.x
        let rDy = rightTopCenter.y - sharpApex.y
        let rLen = sqrt(rDx * rDx + rDy * rDy)
        let rUx = rDx / rLen
        let rUy = rDy / rLen
        let rNx = -rUy
        let rNy = rUx
        
        let rOuterTop = CGPoint(x: rightTopCenter.x - rNx * armHalfW, y: rightTopCenter.y - rNy * armHalfW)
        let rInnerTop = CGPoint(x: rightTopCenter.x + rNx * armHalfW, y: rightTopCenter.y + rNy * armHalfW)
        let rCapCorner1 = CGPoint(x: rOuterTop.x + rUx * armHalfW, y: rOuterTop.y + rUy * armHalfW)
        let rCapCorner2 = CGPoint(x: rInnerTop.x + rUx * armHalfW, y: rInnerTop.y + rUy * armHalfW)
        
        // Left arm unit vectors
        let lDx = leftTopCenter.x - sharpApex.x
        let lDy = leftTopCenter.y - sharpApex.y
        let lLen = sqrt(lDx * lDx + lDy * lDy)
        let lUx = lDx / lLen
        let lUy = lDy / lLen
        let lNx = lUy
        let lNy = -lUx
        
        let lOuterTop = CGPoint(x: leftTopCenter.x - lNx * armHalfW, y: leftTopCenter.y - lNy * armHalfW)
        let lInnerTop = CGPoint(x: leftTopCenter.x + lNx * armHalfW, y: leftTopCenter.y + lNy * armHalfW)
        let lCapCorner1 = CGPoint(x: lInnerTop.x + lUx * armHalfW, y: lInnerTop.y + lUy * armHalfW)
        let lCapCorner2 = CGPoint(x: lOuterTop.x + lUx * armHalfW, y: lOuterTop.y + lUy * armHalfW)
        
        let vPath = CGMutablePath()
        
        // Start at Left Outer Top
        vPath.move(to: lOuterTop)
        
        // Bottom apex arc
        vPath.addArc(tangent1End: sharpApex, tangent2End: rOuterTop, radius: apexRadius)
        vPath.addLine(to: rOuterTop)
        
        // Top right rounded cap
        vPath.addArc(tangent1End: rCapCorner1, tangent2End: rCapCorner2, radius: armHalfW)
        vPath.addArc(tangent1End: rCapCorner2, tangent2End: rInnerTop, radius: armHalfW)
        vPath.addLine(to: rInnerTop)
        
        // Inner crotch fillet arc
        vPath.addArc(tangent1End: sharpCrotch, tangent2End: lInnerTop, radius: crotchRadius)
        vPath.addLine(to: lInnerTop)
        
        // Top left rounded cap
        vPath.addArc(tangent1End: lCapCorner1, tangent2End: lCapCorner2, radius: armHalfW)
        vPath.addArc(tangent1End: lCapCorner2, tangent2End: lOuterTop, radius: armHalfW)
        vPath.addLine(to: lOuterTop)
        
        vPath.closeSubpath()
        
        // ---------------------------------------------------------------------
        // 4. CHIM LẠC / VIETNAMESE ACCENT CREST
        // ---------------------------------------------------------------------
        let crestApexY = 782.0 * scale
        let crestBaseY = 714.0 * scale
        let crestSpan = 104.0 * scale
        let crestThick = 36.0 * scale
        
        let crestLine = CGMutablePath()
        crestLine.move(to: CGPoint(x: cx - crestSpan, y: crestBaseY))
        crestLine.addCurve(
            to: CGPoint(x: cx, y: crestApexY),
            control1: CGPoint(x: cx - crestSpan * 0.45, y: crestBaseY + 26 * scale),
            control2: CGPoint(x: cx - 20 * scale, y: crestApexY)
        )
        crestLine.addCurve(
            to: CGPoint(x: cx + crestSpan, y: crestBaseY),
            control1: CGPoint(x: cx + 20 * scale, y: crestApexY),
            control2: CGPoint(x: cx + crestSpan * 0.45, y: crestBaseY + 26 * scale)
        )
        
        let crestOutlined = crestLine.copy(
            strokingWithWidth: crestThick,
            lineCap: .round,
            lineJoin: .round,
            miterLimit: 10
        )
        
        // ---------------------------------------------------------------------
        // 5. RENDER 'V' WITH LUMINESCENCE
        // ---------------------------------------------------------------------
        // Ambient Aqua Bloom
        ctx.saveGState()
        ctx.setShadow(
            offset: CGSize(width: 0, height: -4.0 * scale),
            blur: 42.0 * scale,
            color: NSColor(red: 0.05, green: 0.85, blue: 1.0, alpha: 0.50).cgColor
        )
        ctx.addPath(vPath)
        ctx.setFillColor(NSColor(red: 0.05, green: 0.70, blue: 0.95, alpha: 0.5).cgColor)
        ctx.fillPath()
        ctx.restoreGState()
        
        // Contact Shadow onto Dish
        ctx.saveGState()
        ctx.setShadow(
            offset: CGSize(width: 0, height: -18.0 * scale),
            blur: 24.0 * scale,
            color: NSColor(red: 0.0, green: 0.02, blue: 0.08, alpha: 0.80).cgColor
        )
        ctx.addPath(vPath)
        ctx.setFillColor(NSColor(red: 0.05, green: 0.08, blue: 0.18, alpha: 1.0).cgColor)
        ctx.fillPath()
        ctx.restoreGState()
        
        // Fill V with Radiant Aqua -> Azure -> Royal Violet Gradient
        ctx.saveGState()
        ctx.addPath(vPath)
        ctx.clip()
        
        let vColors = [
            NSColor(red: 0.06, green: 0.95, blue: 0.98, alpha: 1.0).cgColor,
            NSColor(red: 0.18, green: 0.60, blue: 0.98, alpha: 1.0).cgColor,
            NSColor(red: 0.42, green: 0.25, blue: 0.98, alpha: 1.0).cgColor,
            NSColor(red: 0.88, green: 0.18, blue: 0.78, alpha: 1.0).cgColor
        ] as CFArray
        let vLocations: [CGFloat] = [0.0, 0.36, 0.72, 1.0]
        if let vGrad = CGGradient(colorsSpace: colorSpace, colors: vColors, locations: vLocations) {
            ctx.drawLinearGradient(
                vGrad,
                start: CGPoint(x: leftTopCenter.x - armHalfW, y: topY),
                end: CGPoint(x: rightTopCenter.x + armHalfW, y: topY),
                options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
            )
        }
        
        // Specular Glass Sheen
        if let sheenGrad = CGGradient(
            colorsSpace: colorSpace,
            colors: [
                NSColor(white: 1.0, alpha: 0.48).cgColor,
                NSColor(white: 1.0, alpha: 0.0).cgColor
            ] as CFArray,
            locations: [0.0, 0.65]
        ) {
            ctx.drawLinearGradient(
                sheenGrad,
                start: CGPoint(x: cx, y: topY + armHalfW),
                end: CGPoint(x: cx, y: 220 * scale),
                options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
            )
        }
        ctx.restoreGState()
        
        // Bevel Rim Highlight on V
        ctx.saveGState()
        ctx.addPath(vPath)
        ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.65).cgColor)
        ctx.setLineWidth(1.5 * scale)
        ctx.strokePath()
        ctx.restoreGState()
        
        // ---------------------------------------------------------------------
        // 6. RENDER ACCENT CREST
        // ---------------------------------------------------------------------
        // Warm Amber Bloom
        ctx.saveGState()
        ctx.setShadow(
            offset: CGSize(width: 0, height: 4.0 * scale),
            blur: 32.0 * scale,
            color: NSColor(red: 1.0, green: 0.45, blue: 0.20, alpha: 0.65).cgColor
        )
        ctx.addPath(crestOutlined)
        ctx.setFillColor(NSColor(red: 1.0, green: 0.4, blue: 0.15, alpha: 0.6).cgColor)
        ctx.fillPath()
        ctx.restoreGState()
        
        // Contact Shadow
        ctx.saveGState()
        ctx.setShadow(
            offset: CGSize(width: 0, height: -12.0 * scale),
            blur: 16.0 * scale,
            color: NSColor(red: 0.0, green: 0.01, blue: 0.06, alpha: 0.70).cgColor
        )
        ctx.addPath(crestOutlined)
        ctx.setFillColor(NSColor(red: 0.12, green: 0.06, blue: 0.02, alpha: 1.0).cgColor)
        ctx.fillPath()
        ctx.restoreGState()
        
        // Solar Gold -> Coral Orange -> Sunset Crimson
        ctx.saveGState()
        ctx.addPath(crestOutlined)
        ctx.clip()
        
        let crestColors = [
            NSColor(red: 1.0, green: 0.72, blue: 0.22, alpha: 1.0).cgColor,
            NSColor(red: 1.0, green: 0.32, blue: 0.30, alpha: 1.0).cgColor,
            NSColor(red: 0.94, green: 0.12, blue: 0.55, alpha: 1.0).cgColor
        ] as CFArray
        if let crestGrad = CGGradient(colorsSpace: colorSpace, colors: crestColors, locations: [0.0, 0.50, 1.0]) {
            ctx.drawLinearGradient(
                crestGrad,
                start: CGPoint(x: cx - crestSpan, y: crestBaseY),
                end: CGPoint(x: cx + crestSpan, y: crestBaseY),
                options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
            )
        }
        
        // Specular highlight on crest
        if let crestSheen = CGGradient(
            colorsSpace: colorSpace,
            colors: [
                NSColor(white: 1.0, alpha: 0.65).cgColor,
                NSColor(white: 1.0, alpha: 0.0).cgColor
            ] as CFArray,
            locations: [0.0, 0.60]
        ) {
            ctx.drawLinearGradient(
                crestSheen,
                start: CGPoint(x: cx, y: crestApexY + 20 * scale),
                end: CGPoint(x: cx, y: crestBaseY - 20 * scale),
                options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
            )
        }
        ctx.restoreGState()
        
        // Bevel Rim Highlight on crest
        ctx.saveGState()
        ctx.addPath(crestOutlined)
        ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.70).cgColor)
        ctx.setLineWidth(1.5 * scale)
        ctx.strokePath()
        ctx.restoreGState()
        
        // ---------------------------------------------------------------------
        // 7. MODERN APPLE AMBIENT SURFACE SHEEN
        // ---------------------------------------------------------------------
        ctx.saveGState()
        ctx.addPath(squirclePath)
        ctx.clip()
        
        if let surfaceGrad = CGGradient(
            colorsSpace: colorSpace,
            colors: [
                NSColor(white: 1.0, alpha: 0.08).cgColor,
                NSColor(white: 1.0, alpha: 0.0).cgColor
            ] as CFArray,
            locations: [0.0, 0.50]
        ) {
            ctx.drawLinearGradient(
                surfaceGrad,
                start: CGPoint(x: size * 0.5, y: size - margin),
                end: CGPoint(x: size * 0.5, y: size * 0.50),
                options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
            )
        }
        ctx.restoreGState()
        
        ctx.restoreGState() // End squircle clip
        
        image.unlockFocus()
        return image
    }
    
    public static func generateIconset(outputDirectory: URL) throws -> URL {
        let fileManager = FileManager.default
        let iconsetDir = outputDirectory.appendingPathComponent("AppIcon.iconset")
        try? fileManager.removeItem(at: iconsetDir)
        try fileManager.createDirectory(at: iconsetDir, withIntermediateDirectories: true)
        
        let specifications: [(name: String, points: CGFloat, scale: CGFloat)] = [
            ("icon_16x16.png", 16, 1),
            ("icon_16x16@2x.png", 16, 2),
            ("icon_32x32.png", 32, 1),
            ("icon_32x32@2x.png", 32, 2),
            ("icon_128x128.png", 128, 1),
            ("icon_128x128@2x.png", 128, 2),
            ("icon_256x256.png", 256, 1),
            ("icon_256x256@2x.png", 256, 2),
            ("icon_512x512.png", 512, 1),
            ("icon_512x512@2x.png", 512, 2)
        ]
        
        for spec in specifications {
            let pixelSize = spec.points * spec.scale
            let img = render(size: pixelSize)
            let fileURL = iconsetDir.appendingPathComponent(spec.name)
            
            guard let tiff = img.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: tiff),
                  let pngData = rep.representation(using: .png, properties: [:]) else {
                throw NSError(domain: "CapsuleRenderer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to render PNG"])
            }
            try pngData.write(to: fileURL)
        }
        
        let icnsURL = outputDirectory.appendingPathComponent("AppIcon.icns")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
        process.arguments = ["-c", "icns", iconsetDir.path, "-o", icnsURL.path]
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "CapsuleRenderer", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "iconutil failed"])
        }
        
        try? fileManager.removeItem(at: iconsetDir)
        return icnsURL
    }
}

let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
do {
    let outputICNS = try CapsuleIconRenderer.generateIconset(outputDirectory: cwd)
    print("SUCCESS: Master luxury AppIcon.icns compiled at: \(outputICNS.path)")
} catch {
    print("ERROR: \(error)")
    exit(1)
}
