import Cocoa
import CoreGraphics

// =============================================================================
// VietFlow Multi-Pattern App Icon Generator
// Generates 5 distinct luxury Apple-tier design concepts for user preview
// =============================================================================

final class IconPatternGenerator {
    
    static let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    // Helper: Standard macOS Squircle
    static func createSquirclePath(size: CGFloat, margin: CGFloat, radius: CGFloat) -> CGPath {
        let squircleSize = size - 2 * margin
        let rect = CGRect(x: margin, y: margin, width: squircleSize, height: squircleSize)
        return CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    }
    
    // Helper: Draw standard macOS elevation drop shadow
    static func drawBaseShadow(ctx: CGContext, path: CGPath, scale: CGFloat) {
        ctx.saveGState()
        ctx.setShadow(
            offset: CGSize(width: 0, height: -24.0 * scale),
            blur: 36.0 * scale,
            color: NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.60).cgColor
        )
        ctx.addPath(path)
        ctx.setFillColor(NSColor.black.cgColor)
        ctx.fillPath()
        ctx.restoreGState()
    }

    // =========================================================================
    // PATTERN 1: THE DYNAMIC FLOW RIBBON (Dải Lụa Dòng Chảy & Chữ V Thư Pháp)
    // =========================================================================
    static func renderPattern1_FlowRibbon(size: CGFloat) -> NSImage {
        let scale = size / 1024.0
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else { image.unlockFocus(); return image }
        
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        
        let margin = 96.0 * scale
        let squircle = createSquirclePath(size: size, margin: margin, radius: 188.0 * scale)
        
        drawBaseShadow(ctx: ctx, path: squircle, scale: scale)
        
        ctx.saveGState()
        ctx.addPath(squircle)
        ctx.clip()
        
        // Deep Indigo/Space Blue Chassis
        let bgGrad = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(red: 0.08, green: 0.10, blue: 0.18, alpha: 1.0).cgColor,
            NSColor(red: 0.04, green: 0.05, blue: 0.10, alpha: 1.0).cgColor
        ] as CFArray, locations: [0.0, 1.0])!
        ctx.drawLinearGradient(bgGrad, start: CGPoint(x: margin, y: size - margin), end: CGPoint(x: size - margin, y: margin), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        
        // Inner Dish
        let dishMargin = margin + 32.0 * scale
        let dishSquircle = createSquirclePath(size: size, margin: dishMargin, radius: 160.0 * scale)
        ctx.saveGState()
        ctx.addPath(dishSquircle)
        ctx.clip()
        let dishGrad = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(red: 0.05, green: 0.06, blue: 0.12, alpha: 1.0).cgColor,
            NSColor(red: 0.02, green: 0.03, blue: 0.07, alpha: 1.0).cgColor
        ] as CFArray, locations: [0.0, 1.0])!
        ctx.drawLinearGradient(dishGrad, start: CGPoint(x: size * 0.5, y: size - dishMargin), end: CGPoint(x: size * 0.5, y: dishMargin), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        
        // Center ambient cyan glow
        let radialGlow = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(red: 0.10, green: 0.40, blue: 0.85, alpha: 0.25).cgColor,
            NSColor(white: 0.0, alpha: 0.0).cgColor
        ] as CFArray, locations: [0.0, 1.0])!
        ctx.drawRadialGradient(radialGlow, startCenter: CGPoint(x: size * 0.5, y: size * 0.48), startRadius: 0, endCenter: CGPoint(x: size * 0.5, y: size * 0.48), endRadius: 360 * scale, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        ctx.restoreGState()
        
        // Dish Rim Highlight
        ctx.saveGState()
        ctx.addPath(dishSquircle)
        ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.10).cgColor)
        ctx.setLineWidth(1.5 * scale)
        ctx.strokePath()
        ctx.restoreGState()
        
        // Ribbon Geometry: Fluid 3D folded V ribbon
        let cx = size * 0.5
        
        // Right wing of ribbon (drawn under fold)
        let rightRibbon = CGMutablePath()
        rightRibbon.move(to: CGPoint(x: cx, y: 220 * scale))
        rightRibbon.addCurve(
            to: CGPoint(x: cx + 180 * scale, y: 640 * scale),
            control1: CGPoint(x: cx + 50 * scale, y: 270 * scale),
            control2: CGPoint(x: cx + 120 * scale, y: 480 * scale)
        )
        rightRibbon.addLine(to: CGPoint(x: cx + 110 * scale, y: 660 * scale))
        rightRibbon.addCurve(
            to: CGPoint(x: cx, y: 280 * scale),
            control1: CGPoint(x: cx + 70 * scale, y: 500 * scale),
            control2: CGPoint(x: cx + 20 * scale, y: 340 * scale)
        )
        rightRibbon.closeSubpath()
        
        // Left wing of ribbon (folds over the apex)
        let leftRibbon = CGMutablePath()
        leftRibbon.move(to: CGPoint(x: cx - 180 * scale, y: 640 * scale))
        leftRibbon.addCurve(
            to: CGPoint(x: cx + 25 * scale, y: 215 * scale),
            control1: CGPoint(x: cx - 120 * scale, y: 480 * scale),
            control2: CGPoint(x: cx - 40 * scale, y: 270 * scale)
        )
        leftRibbon.addLine(to: CGPoint(x: cx - 25 * scale, y: 210 * scale))
        leftRibbon.addCurve(
            to: CGPoint(x: cx - 110 * scale, y: 660 * scale),
            control1: CGPoint(x: cx - 70 * scale, y: 310 * scale),
            control2: CGPoint(x: cx - 80 * scale, y: 510 * scale)
        )
        leftRibbon.closeSubpath()
        
        // Draw Right Ribbon with Purple/Magenta
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -12 * scale), blur: 20 * scale, color: NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.6).cgColor)
        ctx.addPath(rightRibbon)
        ctx.clip()
        let rGrad = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(red: 0.35, green: 0.20, blue: 0.95, alpha: 1.0).cgColor,
            NSColor(red: 0.90, green: 0.15, blue: 0.75, alpha: 1.0).cgColor
        ] as CFArray, locations: [0.0, 1.0])!
        ctx.drawLinearGradient(rGrad, start: CGPoint(x: cx, y: 220 * scale), end: CGPoint(x: cx + 180 * scale, y: 650 * scale), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        ctx.restoreGState()
        
        // Draw Left Ribbon with Cyan/Azure folding over
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 6 * scale, height: -14 * scale), blur: 26 * scale, color: NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.75).cgColor)
        ctx.addPath(leftRibbon)
        ctx.clip()
        let lGrad = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(red: 0.08, green: 0.95, blue: 0.98, alpha: 1.0).cgColor,
            NSColor(red: 0.15, green: 0.50, blue: 0.98, alpha: 1.0).cgColor
        ] as CFArray, locations: [0.0, 1.0])!
        ctx.drawLinearGradient(lGrad, start: CGPoint(x: cx - 180 * scale, y: 650 * scale), end: CGPoint(x: cx, y: 210 * scale), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        ctx.restoreGState()
        
        // Flowing Wave Crest (Hovering accent)
        let crestLine = CGMutablePath()
        crestLine.move(to: CGPoint(x: cx - 100 * scale, y: 720 * scale))
        crestLine.addCurve(to: CGPoint(x: cx, y: 785 * scale), control1: CGPoint(x: cx - 45 * scale, y: 740 * scale), control2: CGPoint(x: cx - 18 * scale, y: 785 * scale))
        crestLine.addCurve(to: CGPoint(x: cx + 100 * scale, y: 720 * scale), control1: CGPoint(x: cx + 18 * scale, y: 785 * scale), control2: CGPoint(x: cx + 45 * scale, y: 740 * scale))
        let crestPath = crestLine.copy(strokingWithWidth: 32 * scale, lineCap: .round, lineJoin: .round, miterLimit: 10)
        
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: 4 * scale), blur: 28 * scale, color: NSColor(red: 1.0, green: 0.45, blue: 0.20, alpha: 0.65).cgColor)
        ctx.addPath(crestPath)
        ctx.clip()
        let cGrad = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(red: 1.0, green: 0.75, blue: 0.20, alpha: 1.0).cgColor,
            NSColor(red: 1.0, green: 0.25, blue: 0.35, alpha: 1.0).cgColor
        ] as CFArray, locations: [0.0, 1.0])!
        ctx.drawLinearGradient(cGrad, start: CGPoint(x: cx - 100 * scale, y: 720 * scale), end: CGPoint(x: cx + 100 * scale, y: 720 * scale), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        ctx.restoreGState()
        
        // Bevel stroke on crest
        ctx.saveGState()
        ctx.addPath(crestPath)
        ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.7).cgColor)
        ctx.setLineWidth(1.5 * scale)
        ctx.strokePath()
        ctx.restoreGState()
        
        // Soft surface sheen
        let surfaceSheen = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(white: 1.0, alpha: 0.08).cgColor,
            NSColor(white: 1.0, alpha: 0.0).cgColor
        ] as CFArray, locations: [0.0, 0.45])!
        ctx.drawLinearGradient(surfaceSheen, start: CGPoint(x: size * 0.5, y: size - margin), end: CGPoint(x: size * 0.5, y: size * 0.5), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        
        ctx.restoreGState()
        image.unlockFocus()
        return image
    }

    // =========================================================================
    // PATTERN 2: THE TACTILE MECHANICAL KEYCAP (Phím Cơ Backlit Cao Cấp)
    // =========================================================================
    static func renderPattern2_KeycapTactile(size: CGFloat) -> NSImage {
        let scale = size / 1024.0
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else { image.unlockFocus(); return image }
        
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        
        let margin = 96.0 * scale
        let squircle = createSquirclePath(size: size, margin: margin, radius: 188.0 * scale)
        drawBaseShadow(ctx: ctx, path: squircle, scale: scale)
        
        ctx.saveGState()
        ctx.addPath(squircle)
        ctx.clip()
        
        // Matte Brushed Dark Titanium Plate
        let plateGrad = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(red: 0.15, green: 0.16, blue: 0.19, alpha: 1.0).cgColor,
            NSColor(red: 0.08, green: 0.09, blue: 0.11, alpha: 1.0).cgColor
        ] as CFArray, locations: [0.0, 1.0])!
        ctx.drawLinearGradient(plateGrad, start: CGPoint(x: margin, y: size - margin), end: CGPoint(x: size - margin, y: margin), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        
        // 3D Angled Mechanical Keycap Body
        // Base skirt of keycap
        let skirtRect = CGRect(x: margin + 40 * scale, y: margin + 35 * scale, width: size - 2 * (margin + 40 * scale), height: size - 2 * (margin + 40 * scale))
        let skirtPath = CGPath(roundedRect: skirtRect, cornerWidth: 140 * scale, cornerHeight: 140 * scale, transform: nil)
        
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -20 * scale), blur: 30 * scale, color: NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.85).cgColor)
        ctx.addPath(skirtPath)
        ctx.setFillColor(NSColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 1.0).cgColor)
        ctx.fillPath()
        ctx.restoreGState()
        
        // Elevated Keycap Top Surface (trapezoidal projection feel)
        let topRect = CGRect(x: margin + 70 * scale, y: margin + 85 * scale, width: size - 2 * (margin + 70 * scale), height: size - 2 * (margin + 70 * scale) - 30 * scale)
        let topPath = CGPath(roundedRect: topRect, cornerWidth: 105 * scale, cornerHeight: 105 * scale, transform: nil)
        
        ctx.saveGState()
        ctx.addPath(topPath)
        ctx.clip()
        
        // Top surface matte PBT keycap texture with subtle dish curve
        let keyGrad = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(red: 0.18, green: 0.20, blue: 0.24, alpha: 1.0).cgColor,
            NSColor(red: 0.12, green: 0.13, blue: 0.16, alpha: 1.0).cgColor
        ] as CFArray, locations: [0.0, 1.0])!
        ctx.drawLinearGradient(keyGrad, start: CGPoint(x: size * 0.5, y: topRect.maxY), end: CGPoint(x: size * 0.5, y: topRect.minY), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        
        // Recessed spherical dish shadow
        let dishRadial = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0).cgColor,
            NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.45).cgColor
        ] as CFArray, locations: [0.4, 1.0])!
        ctx.drawRadialGradient(dishRadial, startCenter: CGPoint(x: size * 0.5, y: size * 0.5), startRadius: 100 * scale, endCenter: CGPoint(x: size * 0.5, y: size * 0.5), endRadius: 280 * scale, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        
        // Laser-etched Translucent "V" Legend with Backlit RGB Underglow
        let cx = size * 0.5
        let cy = size * 0.47
        
        // Sharp modern mechanical legend for V
        let legendV = CGMutablePath()
        legendV.move(to: CGPoint(x: cx - 125 * scale, y: cy + 140 * scale))
        legendV.addLine(to: CGPoint(x: cx, y: cy - 130 * scale))
        legendV.addLine(to: CGPoint(x: cx + 125 * scale, y: cy + 140 * scale))
        let legendVOutlined = legendV.copy(strokingWithWidth: 54 * scale, lineCap: .round, lineJoin: .round, miterLimit: 10)
        
        // Accent mark: subtle illuminated chevron
        let legendCrest = CGMutablePath()
        legendCrest.move(to: CGPoint(x: cx - 75 * scale, y: cy + 185 * scale))
        legendCrest.addLine(to: CGPoint(x: cx, y: cy + 230 * scale))
        legendCrest.addLine(to: CGPoint(x: cx + 75 * scale, y: cy + 185 * scale))
        let legendCrestOutlined = legendCrest.copy(strokingWithWidth: 26 * scale, lineCap: .round, lineJoin: .round, miterLimit: 10)
        
        // Backlight RGB Glow for Legend
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: 34 * scale, color: NSColor(red: 0.0, green: 0.85, blue: 1.0, alpha: 0.85).cgColor)
        ctx.addPath(legendVOutlined)
        ctx.setFillColor(NSColor(red: 0.2, green: 0.9, blue: 1.0, alpha: 0.7).cgColor)
        ctx.fillPath()
        ctx.restoreGState()
        
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: 28 * scale, color: NSColor(red: 1.0, green: 0.35, blue: 0.2, alpha: 0.85).cgColor)
        ctx.addPath(legendCrestOutlined)
        ctx.setFillColor(NSColor(red: 1.0, green: 0.45, blue: 0.25, alpha: 0.7).cgColor)
        ctx.fillPath()
        ctx.restoreGState()
        
        // Laser Cut Core Fill (Translucent Frosted White Core with glowing edges)
        ctx.saveGState()
        ctx.addPath(legendVOutlined)
        ctx.setFillColor(NSColor(white: 0.96, alpha: 0.95).cgColor)
        ctx.fillPath()
        ctx.addPath(legendCrestOutlined)
        ctx.setFillColor(NSColor(white: 0.96, alpha: 0.95).cgColor)
        ctx.fillPath()
        ctx.restoreGState()
        
        ctx.restoreGState() // End top surface clip
        
        // Keycap Edge Bevel Highlight (Precision mechanical chamfer)
        ctx.saveGState()
        ctx.addPath(topPath)
        ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.28).cgColor)
        ctx.setLineWidth(2.0 * scale)
        ctx.strokePath()
        ctx.restoreGState()
        
        ctx.restoreGState() // End squircle clip
        image.unlockFocus()
        return image
    }

    // =========================================================================
    // PATTERN 3: THE MINIMALIST LACQUER & GOLD (Sơn Mài Đen & Vàng Champagne)
    // =========================================================================
    static func renderPattern3_MinimalGold(size: CGFloat) -> NSImage {
        let scale = size / 1024.0
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else { image.unlockFocus(); return image }
        
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        
        let margin = 96.0 * scale
        let squircle = createSquirclePath(size: size, margin: margin, radius: 188.0 * scale)
        drawBaseShadow(ctx: ctx, path: squircle, scale: scale)
        
        ctx.saveGState()
        ctx.addPath(squircle)
        ctx.clip()
        
        // Deep Obsidian Piano Lacquer with warm amber undertone
        let lacquerGrad = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(red: 0.08, green: 0.07, blue: 0.06, alpha: 1.0).cgColor,
            NSColor(red: 0.02, green: 0.02, blue: 0.02, alpha: 1.0).cgColor
        ] as CFArray, locations: [0.0, 1.0])!
        ctx.drawLinearGradient(lacquerGrad, start: CGPoint(x: margin, y: size - margin), end: CGPoint(x: size - margin, y: margin), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        
        // Deep warm ambient pool
        let amberGlow = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(red: 0.75, green: 0.50, blue: 0.20, alpha: 0.10).cgColor,
            NSColor(white: 0.0, alpha: 0.0).cgColor
        ] as CFArray, locations: [0.0, 1.0])!
        ctx.drawRadialGradient(amberGlow, startCenter: CGPoint(x: size * 0.5, y: size * 0.5), startRadius: 0, endCenter: CGPoint(x: size * 0.5, y: size * 0.5), endRadius: 400 * scale, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        
        // Ultra-thin 18k Champagne Gold Rim
        ctx.saveGState()
        ctx.addPath(squircle)
        ctx.setStrokeColor(NSColor(red: 0.88, green: 0.75, blue: 0.45, alpha: 0.40).cgColor)
        ctx.setLineWidth(2.0 * scale)
        ctx.strokePath()
        ctx.restoreGState()
        
        // Dual-Tone Faceted Champagne Gold 'V'
        let cx = size * 0.5
        let cy = size * 0.46
        
        // Left arm of V (Polished Mirror Gold)
        let leftArm = CGMutablePath()
        leftArm.move(to: CGPoint(x: cx, y: cy - 150 * scale))
        leftArm.addLine(to: CGPoint(x: cx - 130 * scale, y: cy + 170 * scale))
        leftArm.addLine(to: CGPoint(x: cx - 75 * scale, y: cy + 170 * scale))
        leftArm.addLine(to: CGPoint(x: cx, y: cy - 30 * scale))
        leftArm.closeSubpath()
        
        // Right arm of V (Brushed Satin Gold)
        let rightArm = CGMutablePath()
        rightArm.move(to: CGPoint(x: cx, y: cy - 150 * scale))
        rightArm.addLine(to: CGPoint(x: cx, y: cy - 30 * scale))
        rightArm.addLine(to: CGPoint(x: cx + 75 * scale, y: cy + 170 * scale))
        rightArm.addLine(to: CGPoint(x: cx + 130 * scale, y: cy + 170 * scale))
        rightArm.closeSubpath()
        
        // Minimalist Chevron Accent
        let goldCrest = CGMutablePath()
        goldCrest.move(to: CGPoint(x: cx - 85 * scale, y: cy + 215 * scale))
        goldCrest.addLine(to: CGPoint(x: cx, y: cy + 270 * scale))
        goldCrest.addLine(to: CGPoint(x: cx + 85 * scale, y: cy + 215 * scale))
        let goldCrestOutlined = goldCrest.copy(strokingWithWidth: 20 * scale, lineCap: .round, lineJoin: .round, miterLimit: 10)
        
        // Drop Shadows for gold emblems
        let vCombined = CGMutablePath()
        vCombined.addPath(leftArm)
        vCombined.addPath(rightArm)
        vCombined.addPath(goldCrestOutlined)
        
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -14 * scale), blur: 24 * scale, color: NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.90).cgColor)
        ctx.addPath(vCombined)
        ctx.setFillColor(NSColor.black.cgColor)
        ctx.fillPath()
        ctx.restoreGState()
        
        // Draw Left Arm (Polished High-Key Gold)
        ctx.saveGState()
        ctx.addPath(leftArm)
        ctx.clip()
        let goldHighGrad = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(red: 1.00, green: 0.92, blue: 0.65, alpha: 1.0).cgColor,
            NSColor(red: 0.88, green: 0.72, blue: 0.40, alpha: 1.0).cgColor,
            NSColor(red: 0.70, green: 0.50, blue: 0.22, alpha: 1.0).cgColor
        ] as CFArray, locations: [0.0, 0.5, 1.0])!
        ctx.drawLinearGradient(goldHighGrad, start: CGPoint(x: cx - 130 * scale, y: cy + 170 * scale), end: CGPoint(x: cx, y: cy - 150 * scale), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        ctx.restoreGState()
        
        // Draw Right Arm (Rich Deep Satin Gold)
        ctx.saveGState()
        ctx.addPath(rightArm)
        ctx.clip()
        let goldDeepGrad = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(red: 0.82, green: 0.65, blue: 0.32, alpha: 1.0).cgColor,
            NSColor(red: 0.60, green: 0.42, blue: 0.18, alpha: 1.0).cgColor,
            NSColor(red: 0.45, green: 0.30, blue: 0.12, alpha: 1.0).cgColor
        ] as CFArray, locations: [0.0, 0.5, 1.0])!
        ctx.drawLinearGradient(goldDeepGrad, start: CGPoint(x: cx, y: cy - 150 * scale), end: CGPoint(x: cx + 130 * scale, y: cy + 170 * scale), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        ctx.restoreGState()
        
        // Draw Gold Crest
        ctx.saveGState()
        ctx.addPath(goldCrestOutlined)
        ctx.clip()
        ctx.drawLinearGradient(goldHighGrad, start: CGPoint(x: cx - 85 * scale, y: cy + 215 * scale), end: CGPoint(x: cx + 85 * scale, y: cy + 270 * scale), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        ctx.restoreGState()
        
        // Center Spine Bevel Highlight
        ctx.saveGState()
        let spine = CGMutablePath()
        spine.move(to: CGPoint(x: cx, y: cy - 150 * scale))
        spine.addLine(to: CGPoint(x: cx, y: cy - 30 * scale))
        ctx.addPath(spine)
        ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.6).cgColor)
        ctx.setLineWidth(1.5 * scale)
        ctx.strokePath()
        ctx.restoreGState()
        
        ctx.restoreGState() // End squircle clip
        image.unlockFocus()
        return image
    }

    // =========================================================================
    // PATTERN 4: THE CYBER PRISM / CHIM LẠC FACETS (Lăng Kính Đa Diện)
    // =========================================================================
    static func renderPattern4_CyberPrism(size: CGFloat) -> NSImage {
        let scale = size / 1024.0
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else { image.unlockFocus(); return image }
        
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        
        let margin = 96.0 * scale
        let squircle = createSquirclePath(size: size, margin: margin, radius: 188.0 * scale)
        drawBaseShadow(ctx: ctx, path: squircle, scale: scale)
        
        ctx.saveGState()
        ctx.addPath(squircle)
        ctx.clip()
        
        // Matte Dark Slate Chassis
        let bgGrad = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(red: 0.10, green: 0.11, blue: 0.15, alpha: 1.0).cgColor,
            NSColor(red: 0.04, green: 0.05, blue: 0.07, alpha: 1.0).cgColor
        ] as CFArray, locations: [0.0, 1.0])!
        ctx.drawLinearGradient(bgGrad, start: CGPoint(x: margin, y: size - margin), end: CGPoint(x: size - margin, y: margin), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        
        let cx = size * 0.5
        let cy = size * 0.46
        
        // 4 Facets of V:
        // 1. Left Outer Facet (Aqua)
        let f1 = CGMutablePath()
        f1.move(to: CGPoint(x: cx, y: cy - 160 * scale))
        f1.addLine(to: CGPoint(x: cx - 145 * scale, y: cy + 160 * scale))
        f1.addLine(to: CGPoint(x: cx - 85 * scale, y: cy + 175 * scale))
        f1.closeSubpath()
        
        // 2. Left Inner Facet (Electric Cobalt)
        let f2 = CGMutablePath()
        f2.move(to: CGPoint(x: cx, y: cy - 160 * scale))
        f2.addLine(to: CGPoint(x: cx - 85 * scale, y: cy + 175 * scale))
        f2.addLine(to: CGPoint(x: cx, y: cy - 20 * scale))
        f2.closeSubpath()
        
        // 3. Right Inner Facet (Neon Violet)
        let f3 = CGMutablePath()
        f3.move(to: CGPoint(x: cx, y: cy - 160 * scale))
        f3.addLine(to: CGPoint(x: cx, y: cy - 20 * scale))
        f3.addLine(to: CGPoint(x: cx + 85 * scale, y: cy + 175 * scale))
        f3.closeSubpath()
        
        // 4. Right Outer Facet (Hot Pink)
        let f4 = CGMutablePath()
        f4.move(to: CGPoint(x: cx, y: cy - 160 * scale))
        f4.addLine(to: CGPoint(x: cx + 85 * scale, y: cy + 175 * scale))
        f4.addLine(to: CGPoint(x: cx + 145 * scale, y: cy + 160 * scale))
        f4.closeSubpath()
        
        // Faceted Crest
        let fcLeft = CGMutablePath()
        fcLeft.move(to: CGPoint(x: cx - 110 * scale, y: cy + 225 * scale))
        fcLeft.addLine(to: CGPoint(x: cx, y: cy + 285 * scale))
        fcLeft.addLine(to: CGPoint(x: cx, y: cy + 245 * scale))
        fcLeft.closeSubpath()
        
        let fcRight = CGMutablePath()
        fcRight.move(to: CGPoint(x: cx + 110 * scale, y: cy + 225 * scale))
        fcRight.addLine(to: CGPoint(x: cx, y: cy + 285 * scale))
        fcRight.addLine(to: CGPoint(x: cx, y: cy + 245 * scale))
        fcRight.closeSubpath()
        
        // Draw Facet 1 (Aqua Cyan)
        ctx.saveGState()
        ctx.addPath(f1)
        ctx.clip()
        let g1 = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(red: 0.15, green: 0.95, blue: 0.95, alpha: 1.0).cgColor,
            NSColor(red: 0.05, green: 0.65, blue: 0.85, alpha: 1.0).cgColor
        ] as CFArray, locations: [0.0, 1.0])!
        ctx.drawLinearGradient(g1, start: CGPoint(x: cx - 145 * scale, y: cy + 160 * scale), end: CGPoint(x: cx, y: cy - 160 * scale), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        ctx.restoreGState()
        
        // Draw Facet 2 (Electric Cobalt)
        ctx.saveGState()
        ctx.addPath(f2)
        ctx.clip()
        let g2 = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(red: 0.12, green: 0.45, blue: 0.98, alpha: 1.0).cgColor,
            NSColor(red: 0.08, green: 0.22, blue: 0.75, alpha: 1.0).cgColor
        ] as CFArray, locations: [0.0, 1.0])!
        ctx.drawLinearGradient(g2, start: CGPoint(x: cx - 85 * scale, y: cy + 175 * scale), end: CGPoint(x: cx, y: cy - 160 * scale), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        ctx.restoreGState()
        
        // Draw Facet 3 (Neon Violet)
        ctx.saveGState()
        ctx.addPath(f3)
        ctx.clip()
        let g3 = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(red: 0.55, green: 0.20, blue: 0.95, alpha: 1.0).cgColor,
            NSColor(red: 0.32, green: 0.10, blue: 0.68, alpha: 1.0).cgColor
        ] as CFArray, locations: [0.0, 1.0])!
        ctx.drawLinearGradient(g3, start: CGPoint(x: cx, y: cy - 160 * scale), end: CGPoint(x: cx + 85 * scale, y: cy + 175 * scale), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        ctx.restoreGState()
        
        // Draw Facet 4 (Hot Pink)
        ctx.saveGState()
        ctx.addPath(f4)
        ctx.clip()
        let g4 = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(red: 0.98, green: 0.20, blue: 0.70, alpha: 1.0).cgColor,
            NSColor(red: 0.75, green: 0.10, blue: 0.45, alpha: 1.0).cgColor
        ] as CFArray, locations: [0.0, 1.0])!
        ctx.drawLinearGradient(g4, start: CGPoint(x: cx + 85 * scale, y: cy + 175 * scale), end: CGPoint(x: cx + 145 * scale, y: cy + 160 * scale), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        ctx.restoreGState()
        
        // Draw Facet Crests
        ctx.saveGState()
        ctx.addPath(fcLeft)
        ctx.clip()
        let gcL = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(red: 1.0, green: 0.70, blue: 0.20, alpha: 1.0).cgColor,
            NSColor(red: 1.0, green: 0.35, blue: 0.15, alpha: 1.0).cgColor
        ] as CFArray, locations: [0.0, 1.0])!
        ctx.drawLinearGradient(gcL, start: CGPoint(x: cx - 110 * scale, y: cy + 225 * scale), end: CGPoint(x: cx, y: cy + 285 * scale), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        ctx.restoreGState()
        
        ctx.saveGState()
        ctx.addPath(fcRight)
        ctx.clip()
        let gcR = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(red: 1.0, green: 0.35, blue: 0.15, alpha: 1.0).cgColor,
            NSColor(red: 0.90, green: 0.10, blue: 0.45, alpha: 1.0).cgColor
        ] as CFArray, locations: [0.0, 1.0])!
        ctx.drawLinearGradient(gcR, start: CGPoint(x: cx, y: cy + 285 * scale), end: CGPoint(x: cx + 110 * scale, y: cy + 225 * scale), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        ctx.restoreGState()
        
        // Fine White Bevel Strokes on Facet Edges
        let edges = [f1, f2, f3, f4, fcLeft, fcRight]
        for e in edges {
            ctx.saveGState()
            ctx.addPath(e)
            ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.35).cgColor)
            ctx.setLineWidth(1.0 * scale)
            ctx.strokePath()
            ctx.restoreGState()
        }
        
        ctx.restoreGState() // End squircle clip
        image.unlockFocus()
        return image
    }

    // =========================================================================
    // PATTERN 5: APPLE PURE GLASSMORHISM (Kính Mờ macOS Tahoe / Cupertino Native)
    // =========================================================================
    static func renderPattern5_AppleGlass(size: CGFloat) -> NSImage {
        let scale = size / 1024.0
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else { image.unlockFocus(); return image }
        
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        
        let margin = 96.0 * scale
        let squircle = createSquirclePath(size: size, margin: margin, radius: 188.0 * scale)
        drawBaseShadow(ctx: ctx, path: squircle, scale: scale)
        
        ctx.saveGState()
        ctx.addPath(squircle)
        ctx.clip()
        
        // Deep Space Midnight Canvas
        let bgGrad = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(red: 0.12, green: 0.14, blue: 0.20, alpha: 1.0).cgColor,
            NSColor(red: 0.05, green: 0.06, blue: 0.09, alpha: 1.0).cgColor
        ] as CFArray, locations: [0.0, 1.0])!
        ctx.drawLinearGradient(bgGrad, start: CGPoint(x: margin, y: size - margin), end: CGPoint(x: size - margin, y: margin), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        
        let cx = size * 0.5
        let cy = size * 0.46
        
        // Background Neon Emitters (Glow through frosted glass)
        let glowGrad1 = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(red: 0.05, green: 0.85, blue: 1.0, alpha: 0.65).cgColor,
            NSColor(white: 0.0, alpha: 0.0).cgColor
        ] as CFArray, locations: [0.0, 1.0])!
        ctx.drawRadialGradient(glowGrad1, startCenter: CGPoint(x: cx - 110 * scale, y: cy + 60 * scale), startRadius: 0, endCenter: CGPoint(x: cx - 110 * scale, y: cy + 60 * scale), endRadius: 280 * scale, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        
        let glowGrad2 = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(red: 0.85, green: 0.20, blue: 0.95, alpha: 0.60).cgColor,
            NSColor(white: 0.0, alpha: 0.0).cgColor
        ] as CFArray, locations: [0.0, 1.0])!
        ctx.drawRadialGradient(glowGrad2, startCenter: CGPoint(x: cx + 110 * scale, y: cy + 60 * scale), startRadius: 0, endCenter: CGPoint(x: cx + 110 * scale, y: cy + 60 * scale), endRadius: 280 * scale, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        
        let glowGrad3 = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(red: 1.0, green: 0.50, blue: 0.20, alpha: 0.55).cgColor,
            NSColor(white: 0.0, alpha: 0.0).cgColor
        ] as CFArray, locations: [0.0, 1.0])!
        ctx.drawRadialGradient(glowGrad3, startCenter: CGPoint(x: cx, y: cy + 240 * scale), startRadius: 0, endCenter: CGPoint(x: cx, y: cy + 240 * scale), endRadius: 220 * scale, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        
        // Floating Frosted Acrylic Plate (Inverted V Shape)
        let vPlateLine = CGMutablePath()
        vPlateLine.move(to: CGPoint(x: cx - 130 * scale, y: cy + 160 * scale))
        vPlateLine.addLine(to: CGPoint(x: cx, y: cy - 140 * scale))
        vPlateLine.addLine(to: CGPoint(x: cx + 130 * scale, y: cy + 160 * scale))
        let vPlate = vPlateLine.copy(strokingWithWidth: 92 * scale, lineCap: .round, lineJoin: .round, miterLimit: 10)
        
        let crestPlateLine = CGMutablePath()
        crestPlateLine.move(to: CGPoint(x: cx - 95 * scale, y: cy + 215 * scale))
        crestPlateLine.addCurve(to: CGPoint(x: cx, y: cy + 275 * scale), control1: CGPoint(x: cx - 40 * scale, y: cy + 235 * scale), control2: CGPoint(x: cx - 18 * scale, y: cy + 275 * scale))
        crestPlateLine.addCurve(to: CGPoint(x: cx + 95 * scale, y: cy + 215 * scale), control1: CGPoint(x: cx + 18 * scale, y: cy + 275 * scale), control2: CGPoint(x: cx + 40 * scale, y: cy + 235 * scale))
        let crestPlate = crestPlateLine.copy(strokingWithWidth: 36 * scale, lineCap: .round, lineJoin: .round, miterLimit: 10)
        
        // Frosted Glass V Plate
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -18 * scale), blur: 28 * scale, color: NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.65).cgColor)
        ctx.addPath(vPlate)
        ctx.clip()
        
        let frostedGrad = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(white: 1.0, alpha: 0.42).cgColor,
            NSColor(white: 1.0, alpha: 0.18).cgColor,
            NSColor(white: 1.0, alpha: 0.08).cgColor
        ] as CFArray, locations: [0.0, 0.5, 1.0])!
        ctx.drawLinearGradient(frostedGrad, start: CGPoint(x: cx, y: cy + 200 * scale), end: CGPoint(x: cx, y: cy - 140 * scale), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        ctx.restoreGState()
        
        // Frosted Glass Crest Plate
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -10 * scale), blur: 18 * scale, color: NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.55).cgColor)
        ctx.addPath(crestPlate)
        ctx.clip()
        ctx.drawLinearGradient(frostedGrad, start: CGPoint(x: cx, y: cy + 280 * scale), end: CGPoint(x: cx, y: cy + 200 * scale), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        ctx.restoreGState()
        
        // Crisp Diamond-Cut Glass Bevel Edge on Plates
        ctx.saveGState()
        ctx.addPath(vPlate)
        ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.85).cgColor)
        ctx.setLineWidth(2.0 * scale)
        ctx.strokePath()
        ctx.restoreGState()
        
        ctx.saveGState()
        ctx.addPath(crestPlate)
        ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.85).cgColor)
        ctx.setLineWidth(1.8 * scale)
        ctx.strokePath()
        ctx.restoreGState()
        
        ctx.restoreGState() // End squircle clip
        image.unlockFocus()
        return image
    }

    // =========================================================================
    // MASTER SHOWCASE CANVAS: All 5 patterns in a single high-res comparison
    // =========================================================================
    static func renderShowcase(outputDirectory: URL) throws {
        let width: CGFloat = 2800
        let height: CGFloat = 850
        let showcase = NSImage(size: NSSize(width: width, height: height))
        showcase.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else { showcase.unlockFocus(); return }
        
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        
        // Dark Studio Stage Background
        let studioGrad = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(red: 0.07, green: 0.08, blue: 0.11, alpha: 1.0).cgColor,
            NSColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1.0).cgColor
        ] as CFArray, locations: [0.0, 1.0])!
        ctx.drawLinearGradient(studioGrad, start: CGPoint(x: 0, y: height), end: CGPoint(x: width, y: 0), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        
        let patterns: [(name: String, title: String, subtitle: String, image: NSImage)] = [
            ("Pattern 1", "Flow Ribbon", "Sóng Lụa Neon Chuyển Sắc", renderPattern1_FlowRibbon(size: 512)),
            ("Pattern 2", "Tactile Keycap", "Phím Cơ Cyber Backlit", renderPattern2_KeycapTactile(size: 512)),
            ("Pattern 3", "Heritage Gold", "Sơn Mài Đen & Vàng Champagne", renderPattern3_MinimalGold(size: 512)),
            ("Pattern 4", "Cyber Prism", "Lăng Kính Khối Đa Diện", renderPattern4_CyberPrism(size: 512)),
            ("Pattern 5", "Apple Glass", "Kính Mờ macOS Tahoe", renderPattern5_AppleGlass(size: 512))
        ]
        
        let iconDisplaySize: CGFloat = 420
        let spacing: CGFloat = 530
        let startX: CGFloat = 110
        let iconY: CGFloat = 280
        
        for (i, p) in patterns.enumerated() {
            let x = startX + CGFloat(i) * spacing
            let rect = CGRect(x: x, y: iconY, width: iconDisplaySize, height: iconDisplaySize)
            p.image.draw(in: rect)
            
            // Text Label
            let badge = p.name as NSString
            let title = p.title as NSString
            let sub = p.subtitle as NSString
            
            let badgeAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 18, weight: .bold),
                .foregroundColor: NSColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 1.0)
            ]
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 26, weight: .heavy),
                .foregroundColor: NSColor.white
            ]
            let subAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 18, weight: .medium),
                .foregroundColor: NSColor(white: 0.65, alpha: 1.0)
            ]
            
            let textX = x + 30
            badge.draw(at: CGPoint(x: textX, y: 220), withAttributes: badgeAttrs)
            title.draw(at: CGPoint(x: textX, y: 180), withAttributes: titleAttrs)
            sub.draw(at: CGPoint(x: textX, y: 150), withAttributes: subAttrs)
            
            // Also save individual 1024x1024 pattern image
            let fullSizeImg: NSImage
            switch i {
            case 0: fullSizeImg = renderPattern1_FlowRibbon(size: 1024)
            case 1: fullSizeImg = renderPattern2_KeycapTactile(size: 1024)
            case 2: fullSizeImg = renderPattern3_MinimalGold(size: 1024)
            case 3: fullSizeImg = renderPattern4_CyberPrism(size: 1024)
            default: fullSizeImg = renderPattern5_AppleGlass(size: 1024)
            }
            if let tiff = fullSizeImg.tiffRepresentation,
               let rep = NSBitmapImageRep(data: tiff),
               let png = rep.representation(using: .png, properties: [:]) {
                let fileURL = outputDirectory.appendingPathComponent("Icon_Pattern_\(i + 1).png")
                try? png.write(to: fileURL)
            }
        }
        
        showcase.unlockFocus()
        
        if let tiff = showcase.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            let showcaseURL = outputDirectory.appendingPathComponent("Icon_Showcase_All_Patterns.png")
            try png.write(to: showcaseURL)
            print("SUCCESS: Showcase banner saved to \(showcaseURL.path)")
        }
    }
}

let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
do {
    try IconPatternGenerator.renderShowcase(outputDirectory: cwd)
    print("SUCCESS: All 5 patterns generated!")
} catch {
    print("ERROR: \(error)")
    exit(1)
}
