import Cocoa
import CoreGraphics

// =============================================================================
// VietFlow Status Bar Icon Patterns Generator
// Creates 5 distinct design patterns for the macOS Menu Bar (V and E states)
// Displays them on simulated macOS Dark & Light Menu Bars for real-life preview
// =============================================================================

struct PatternItem {
    let id: String
    let name: String
    let desc: String
    let renderV: (CGFloat, Bool) -> NSImage
    let renderE: (CGFloat, Bool) -> NSImage
}

final class StatusBarPatternRenderer {
    static let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    // =========================================================================
    // PATTERN A: TACTILE KEYCAP SQUIRCLE (Phím Bấm Tối Giản Bo Tròn)
    // =========================================================================
    static func renderPatternA(mode: String, size: CGFloat = 22, isDark: Bool = true) -> NSImage {
        let img = NSImage(size: NSSize(width: size, height: size))
        img.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else { img.unlockFocus(); return img }
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        
        let scale = size / 22.0
        let fgColor: NSColor = isDark ? .white : .black
        let isViet = (mode == "V")
        
        // Keycap squircle box
        let boxRect = CGRect(x: 1.5 * scale, y: 1.5 * scale, width: 19 * scale, height: 19 * scale)
        let boxPath = CGPath(roundedRect: boxRect, cornerWidth: 5.5 * scale, cornerHeight: 5.5 * scale, transform: nil)
        
        if isViet {
            // Filled active keycap
            ctx.saveGState()
            ctx.addPath(boxPath)
            ctx.setFillColor(fgColor.withAlphaComponent(0.92).cgColor)
            ctx.fillPath()
            ctx.restoreGState()
            
            // Inverted letter
            let font = NSFont.systemFont(ofSize: 12 * scale, weight: .bold)
            let text = "V" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: isDark ? NSColor.black : NSColor.white
            ]
            let strSize = text.size(withAttributes: attrs)
            text.draw(at: CGPoint(x: (size - strSize.width) / 2, y: (size - strSize.height) / 2 + 0.5 * scale), withAttributes: attrs)
        } else {
            // Outline keycap for English
            ctx.saveGState()
            ctx.addPath(boxPath)
            ctx.setStrokeColor(fgColor.withAlphaComponent(0.65).cgColor)
            ctx.setLineWidth(1.4 * scale)
            ctx.strokePath()
            ctx.restoreGState()
            
            let font = NSFont.systemFont(ofSize: 11.5 * scale, weight: .semibold)
            let text = "E" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: fgColor.withAlphaComponent(0.85)
            ]
            let strSize = text.size(withAttributes: attrs)
            text.draw(at: CGPoint(x: (size - strSize.width) / 2, y: (size - strSize.height) / 2 + 0.5 * scale), withAttributes: attrs)
        }
        
        img.unlockFocus()
        return img
    }

    // =========================================================================
    // PATTERN B: VIETFLOW DYNAMIC WING (Cánh Chim Lạc & Sóng Lụa Vector)
    // =========================================================================
    static func renderPatternB(mode: String, size: CGFloat = 22, isDark: Bool = true) -> NSImage {
        let img = NSImage(size: NSSize(width: size, height: size))
        img.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else { img.unlockFocus(); return img }
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        
        let scale = size / 22.0
        let fgColor: NSColor = isDark ? .white : .black
        let cx = size * 0.5
        let isViet = (mode == "V")
        
        if isViet {
            // Custom drawn stylized V with aerodynamic wings
            let vLine = CGMutablePath()
            vLine.move(to: CGPoint(x: cx - 6.5 * scale, y: 15.5 * scale))
            vLine.addLine(to: CGPoint(x: cx, y: 4.0 * scale))
            vLine.addLine(to: CGPoint(x: cx + 6.5 * scale, y: 15.5 * scale))
            
            ctx.saveGState()
            ctx.addPath(vLine)
            ctx.setStrokeColor(fgColor.withAlphaComponent(0.95).cgColor)
            ctx.setLineWidth(2.2 * scale)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            ctx.strokePath()
            ctx.restoreGState()
            
            // Hovering Diacritical Tone Wing / Chevron
            let crestLine = CGMutablePath()
            crestLine.move(to: CGPoint(x: cx - 4.2 * scale, y: 17.5 * scale))
            crestLine.addLine(to: CGPoint(x: cx, y: 19.8 * scale))
            crestLine.addLine(to: CGPoint(x: cx + 4.2 * scale, y: 17.5 * scale))
            
            ctx.saveGState()
            ctx.addPath(crestLine)
            ctx.setStrokeColor(fgColor.withAlphaComponent(0.95).cgColor)
            ctx.setLineWidth(1.6 * scale)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            ctx.strokePath()
            ctx.restoreGState()
        } else {
            // Matching clean geometric E with rounded caps
            let eLine = CGMutablePath()
            // Vertical backbone
            eLine.move(to: CGPoint(x: cx - 4.5 * scale, y: 18.0 * scale))
            eLine.addLine(to: CGPoint(x: cx - 4.5 * scale, y: 4.5 * scale))
            // Bottom tine
            eLine.addLine(to: CGPoint(x: cx + 4.5 * scale, y: 4.5 * scale))
            // Top tine
            eLine.move(to: CGPoint(x: cx - 4.5 * scale, y: 18.0 * scale))
            eLine.addLine(to: CGPoint(x: cx + 4.5 * scale, y: 18.0 * scale))
            // Mid tine
            eLine.move(to: CGPoint(x: cx - 4.5 * scale, y: 11.25 * scale))
            eLine.addLine(to: CGPoint(x: cx + 2.5 * scale, y: 11.25 * scale))
            
            ctx.saveGState()
            ctx.addPath(eLine)
            ctx.setStrokeColor(fgColor.withAlphaComponent(0.75).cgColor)
            ctx.setLineWidth(2.0 * scale)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            ctx.strokePath()
            ctx.restoreGState()
        }
        
        img.unlockFocus()
        return img
    }

    // =========================================================================
    // PATTERN C: SEGMENTED CAPSULE TOGGLE (Viên Thuốc Chuyển Đổi V | E)
    // =========================================================================
    static func renderPatternC(mode: String, size: CGFloat = 22, isDark: Bool = true) -> NSImage {
        let width = size * 1.55 // Wider capsule: ~34pt
        let height = size
        let img = NSImage(size: NSSize(width: width, height: height))
        img.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else { img.unlockFocus(); return img }
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        
        let scale = size / 22.0
        let fgColor: NSColor = isDark ? .white : .black
        let isViet = (mode == "V")
        
        // Outer pill capsule
        let capsuleRect = CGRect(x: 1.0 * scale, y: 2.5 * scale, width: width - 2.0 * scale, height: height - 5.0 * scale)
        let capsulePath = CGPath(roundedRect: capsuleRect, cornerWidth: capsuleRect.height * 0.5, cornerHeight: capsuleRect.height * 0.5, transform: nil)
        
        // Background track
        ctx.saveGState()
        ctx.addPath(capsulePath)
        ctx.setFillColor(fgColor.withAlphaComponent(0.12).cgColor)
        ctx.fillPath()
        ctx.restoreGState()
        
        // Active thumb pill
        let thumbWidth = (capsuleRect.width - 2.0 * scale) * 0.5
        let thumbX = isViet ? (capsuleRect.minX + 1.0 * scale) : (capsuleRect.minX + 1.0 * scale + thumbWidth)
        let thumbRect = CGRect(x: thumbX, y: capsuleRect.minY + 1.0 * scale, width: thumbWidth, height: capsuleRect.height - 2.0 * scale)
        let thumbPath = CGPath(roundedRect: thumbRect, cornerWidth: thumbRect.height * 0.5, cornerHeight: thumbRect.height * 0.5, transform: nil)
        
        ctx.saveGState()
        ctx.addPath(thumbPath)
        ctx.setFillColor(fgColor.withAlphaComponent(0.88).cgColor)
        ctx.fillPath()
        ctx.restoreGState()
        
        // Letters "V" and "E"
        let font = NSFont.systemFont(ofSize: 10.0 * scale, weight: .bold)
        
        let vText = "V" as NSString
        let eText = "E" as NSString
        
        let vColor: NSColor = isViet ? (isDark ? .black : .white) : fgColor.withAlphaComponent(0.40)
        let eColor: NSColor = (!isViet) ? (isDark ? .black : .white) : fgColor.withAlphaComponent(0.40)
        
        let vAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: vColor]
        let eAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: eColor]
        
        let vSize = vText.size(withAttributes: vAttrs)
        let eSize = eText.size(withAttributes: eAttrs)
        
        let leftCenterX = capsuleRect.minX + thumbWidth * 0.5
        let rightCenterX = capsuleRect.maxX - thumbWidth * 0.5
        
        vText.draw(at: CGPoint(x: leftCenterX - vSize.width * 0.5, y: (height - vSize.height) * 0.5 + 0.5 * scale), withAttributes: vAttrs)
        eText.draw(at: CGPoint(x: rightCenterX - eSize.width * 0.5, y: (height - eSize.height) * 0.5 + 0.5 * scale), withAttributes: eAttrs)
        
        img.unlockFocus()
        return img
    }

    // =========================================================================
    // PATTERN D: APPLE SF-PRO MONOGRAM (Monogram Chuẩn Apple SF Tuyệt Đối)
    // =========================================================================
    static func renderPatternD(mode: String, size: CGFloat = 22, isDark: Bool = true) -> NSImage {
        let img = NSImage(size: NSSize(width: size, height: size))
        img.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else { img.unlockFocus(); return img }
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        
        let scale = size / 22.0
        let fgColor: NSColor = isDark ? .white : .black
        let cx = size * 0.5
        let isViet = (mode == "V")
        
        let font = NSFont.systemFont(ofSize: 13.5 * scale, weight: .bold)
        let text = (isViet ? "V" : "E") as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: fgColor.withAlphaComponent(isViet ? 0.95 : 0.75)
        ]
        let strSize = text.size(withAttributes: attrs)
        let x = (size - strSize.width) / 2
        let y = (size - strSize.height) / 2 - (isViet ? 1.0 * scale : 0.0)
        text.draw(at: CGPoint(x: x, y: y), withAttributes: attrs)
        
        if isViet {
            // Subtle, exquisite Apple-style Diacritic Accent mark hovering above V
            let dotRadius = 1.3 * scale
            let dotY = y + strSize.height + 0.8 * scale
            let dotPath = CGPath(ellipseIn: CGRect(x: cx - dotRadius, y: dotY, width: dotRadius * 2, height: dotRadius * 2), transform: nil)
            
            ctx.saveGState()
            ctx.addPath(dotPath)
            ctx.setFillColor(fgColor.withAlphaComponent(0.95).cgColor)
            ctx.fillPath()
            ctx.restoreGState()
        }
        
        img.unlockFocus()
        return img
    }

    // =========================================================================
    // PATTERN E: BACKLIT KEYCAP SWITCH WITH STATUS DOT (Phím Có Chấm LED)
    // =========================================================================
    static func renderPatternE(mode: String, size: CGFloat = 22, isDark: Bool = true) -> NSImage {
        let img = NSImage(size: NSSize(width: size, height: size))
        img.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else { img.unlockFocus(); return img }
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        
        let scale = size / 22.0
        let fgColor: NSColor = isDark ? .white : .black
        let isViet = (mode == "V")
        
        // Soft rounded badge
        let rect = CGRect(x: 1.0 * scale, y: 1.0 * scale, width: 20 * scale, height: 20 * scale)
        let path = CGPath(roundedRect: rect, cornerWidth: 6.0 * scale, cornerHeight: 6.0 * scale, transform: nil)
        
        ctx.saveGState()
        ctx.addPath(path)
        ctx.setFillColor(fgColor.withAlphaComponent(0.10).cgColor)
        ctx.fillPath()
        ctx.setStrokeColor(fgColor.withAlphaComponent(0.25).cgColor)
        ctx.setLineWidth(1.0 * scale)
        ctx.strokePath()
        ctx.restoreGState()
        
        // Letter
        let font = NSFont.systemFont(ofSize: 11.5 * scale, weight: .bold)
        let text = (isViet ? "V" : "E") as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: fgColor.withAlphaComponent(0.90)
        ]
        let strSize = text.size(withAttributes: attrs)
        text.draw(at: CGPoint(x: (size - strSize.width) / 2 - 1.5 * scale, y: (size - strSize.height) / 2 + 0.5 * scale), withAttributes: attrs)
        
        // Active indicator dot on top-right
        let dotCenter = CGPoint(x: size - 4.5 * scale, y: size - 4.5 * scale)
        let dotR: CGFloat = 1.8 * scale
        let dotPath = CGPath(ellipseIn: CGRect(x: dotCenter.x - dotR, y: dotCenter.y - dotR, width: dotR * 2, height: dotR * 2), transform: nil)
        
        ctx.saveGState()
        if isViet {
            // Glowing cyan/green LED accent
            let ledColor = NSColor(red: 0.15, green: 0.85, blue: 0.95, alpha: 1.0)
            ctx.setShadow(offset: .zero, blur: 4.0 * scale, color: ledColor.cgColor)
            ctx.addPath(dotPath)
            ctx.setFillColor(ledColor.cgColor)
            ctx.fillPath()
        } else {
            // Inactive subtle dot
            ctx.addPath(dotPath)
            ctx.setFillColor(fgColor.withAlphaComponent(0.25).cgColor)
            ctx.fillPath()
        }
        ctx.restoreGState()
        
        img.unlockFocus()
        return img
    }

    // =========================================================================
    // MASTER PREVIEW SHOWCASE: Simulated macOS Menu Bar (Dark & Light)
    // =========================================================================
    static func renderShowcase(outputDirectory: URL) throws {
        let width: CGFloat = 2600
        let height: CGFloat = 1350
        let canvas = NSImage(size: NSSize(width: width, height: height))
        canvas.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else { canvas.unlockFocus(); return }
        
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        
        // Studio Stage Background
        let stageGrad = CGGradient(colorsSpace: colorSpace, colors: [
            NSColor(red: 0.08, green: 0.09, blue: 0.12, alpha: 1.0).cgColor,
            NSColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1.0).cgColor
        ] as CFArray, locations: [0.0, 1.0])!
        ctx.drawLinearGradient(stageGrad, start: CGPoint(x: 0, y: height), end: CGPoint(x: width, y: 0), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        
        // Header
        let mainTitle = "VietFlow — Status Bar Icon Design Patterns" as NSString
        let subTitle = "Xem trước 5 phong cách biểu tượng thanh trạng thái (Menu Bar) trên macOS Dark Mode & Light Mode" as NSString
        
        mainTitle.draw(at: CGPoint(x: 100, y: height - 90), withAttributes: [
            .font: NSFont.systemFont(ofSize: 34, weight: .heavy),
            .foregroundColor: NSColor.white
        ])
        subTitle.draw(at: CGPoint(x: 100, y: height - 130), withAttributes: [
            .font: NSFont.systemFont(ofSize: 20, weight: .regular),
            .foregroundColor: NSColor(white: 0.65, alpha: 1.0)
        ])
        
        var patterns: [PatternItem] = []
        patterns.append(PatternItem(id: "Pattern A", name: "Tactile Keycap", desc: "Phím Bấm Bo Tròn (Fill khi V, Outline khi E)", renderV: { s, d in StatusBarPatternRenderer.renderPatternA(mode: "V", size: s, isDark: d) }, renderE: { s, d in StatusBarPatternRenderer.renderPatternA(mode: "E", size: s, isDark: d) }))
        patterns.append(PatternItem(id: "Pattern B", name: "VietFlow Wing", desc: "Cánh Chim Lạc & Sóng Lụa Vector Tự Do", renderV: { s, d in StatusBarPatternRenderer.renderPatternB(mode: "V", size: s, isDark: d) }, renderE: { s, d in StatusBarPatternRenderer.renderPatternB(mode: "E", size: s, isDark: d) }))
        patterns.append(PatternItem(id: "Pattern C", name: "Toggle Capsule", desc: "Viên Thuốc Chuyển Đổi V | E Phân Đoạn", renderV: { s, d in StatusBarPatternRenderer.renderPatternC(mode: "V", size: s, isDark: d) }, renderE: { s, d in StatusBarPatternRenderer.renderPatternC(mode: "E", size: s, isDark: d) }))
        patterns.append(PatternItem(id: "Pattern D", name: "Apple SF Monogram", desc: "Monogram Chuẩn Apple SF + Dấu Thanh Tinh Tế", renderV: { s, d in StatusBarPatternRenderer.renderPatternD(mode: "V", size: s, isDark: d) }, renderE: { s, d in StatusBarPatternRenderer.renderPatternD(mode: "E", size: s, isDark: d) }))
        patterns.append(PatternItem(id: "Pattern E", name: "LED Keycap Switch", desc: "Phím Bấm Tích Hợp Đèn LED Trạng Thái", renderV: { s, d in StatusBarPatternRenderer.renderPatternE(mode: "V", size: s, isDark: d) }, renderE: { s, d in StatusBarPatternRenderer.renderPatternE(mode: "E", size: s, isDark: d) }))
        
        let darkBarY: CGFloat = height - 340
        drawSimulatedMenuBar(ctx: ctx, x: 100, y: darkBarY, width: 2400, isDark: true, patterns: patterns)
        
        // Label for Dark Mode Section
        let darkLabel = "1. MÔ PHỎNG TRÊN MACOS MENU BAR (DARK MODE)" as NSString
        darkLabel.draw(at: CGPoint(x: 100, y: darkBarY + 80), withAttributes: [
            .font: NSFont.systemFont(ofSize: 18, weight: .bold),
            .foregroundColor: NSColor(red: 0.3, green: 0.75, blue: 1.0, alpha: 1.0)
        ])
        
        // ---------------------------------------------------------------------
        // SECTION 2: MAC OS LIGHT MODE MENU BAR SIMULATION
        // ---------------------------------------------------------------------
        let lightBarY: CGFloat = height - 560
        drawSimulatedMenuBar(ctx: ctx, x: 100, y: lightBarY, width: 2400, isDark: false, patterns: patterns)
        
        // Label for Light Mode Section
        let lightLabel = "2. MÔ PHỎNG TRÊN MACOS MENU BAR (LIGHT MODE)" as NSString
        lightLabel.draw(at: CGPoint(x: 100, y: lightBarY + 80), withAttributes: [
            .font: NSFont.systemFont(ofSize: 18, weight: .bold),
            .foregroundColor: NSColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0)
        ])
        
        // ---------------------------------------------------------------------
        // SECTION 3: 5X ZOOM DETAIL INSPECTION CARDS
        // ---------------------------------------------------------------------
        let detailY: CGFloat = 60
        let detailLabel = "3. CHI TIẾT PHÓNG ĐẠI (ZOOM DETAIL INSPECTION: TRẠNG THÁI [V] VÀ [E])" as NSString
        detailLabel.draw(at: CGPoint(x: 100, y: detailY + 420), withAttributes: [
            .font: NSFont.systemFont(ofSize: 18, weight: .bold),
            .foregroundColor: NSColor(white: 0.90, alpha: 1.0)
        ])
        
        let cardWidth: CGFloat = 450
        let cardSpacing: CGFloat = 485
        for (i, p) in patterns.enumerated() {
            let cardX = 100 + CGFloat(i) * cardSpacing
            let cardRect = CGRect(x: cardX, y: detailY, width: cardWidth, height: 390)
            let cardPath = CGPath(roundedRect: cardRect, cornerWidth: 16, cornerHeight: 16, transform: nil)
            
            // Card background
            ctx.saveGState()
            ctx.addPath(cardPath)
            ctx.setFillColor(NSColor(red: 0.11, green: 0.12, blue: 0.16, alpha: 1.0).cgColor)
            ctx.fillPath()
            ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.12).cgColor)
            ctx.setLineWidth(1.0)
            ctx.strokePath()
            ctx.restoreGState()
            
            // Badge & Title
            (p.id as NSString).draw(at: CGPoint(x: cardX + 24, y: detailY + 345), withAttributes: [
                .font: NSFont.systemFont(ofSize: 16, weight: .bold),
                .foregroundColor: NSColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 1.0)
            ])
            (p.name as NSString).draw(at: CGPoint(x: cardX + 24, y: detailY + 315), withAttributes: [
                .font: NSFont.systemFont(ofSize: 22, weight: .heavy),
                .foregroundColor: NSColor.white
            ])
            (p.desc as NSString).draw(at: CGPoint(x: cardX + 24, y: detailY + 288), withAttributes: [
                .font: NSFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: NSColor(white: 0.65, alpha: 1.0)
            ])
            
            // 2 Zoom Plates: Left is [V], Right is [E]
            let plateWidth: CGFloat = 185
            let plateHeight: CGFloat = 160
            let plateY = detailY + 90
            
            // Left Plate: V
            let vPlateRect = CGRect(x: cardX + 24, y: plateY, width: plateWidth, height: plateHeight)
            let vPlatePath = CGPath(roundedRect: vPlateRect, cornerWidth: 12, cornerHeight: 12, transform: nil)
            ctx.saveGState()
            ctx.addPath(vPlatePath)
            ctx.setFillColor(NSColor(red: 0.06, green: 0.07, blue: 0.10, alpha: 1.0).cgColor)
            ctx.fillPath()
            ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.08).cgColor)
            ctx.strokePath()
            ctx.restoreGState()
            
            // Draw 5x zoom icon
            let zoomSize: CGFloat = (p.id == "Pattern C") ? 100 : 72
            let imgV = p.renderV(zoomSize, true)
            let imgVX = vPlateRect.midX - imgV.size.width * 0.5
            let imgVY = vPlateRect.midY - imgV.size.height * 0.5 + 8
            imgV.draw(in: CGRect(x: imgVX, y: imgVY, width: imgV.size.width, height: imgV.size.height))
            
            ("Tiếng Việt [V]" as NSString).draw(at: CGPoint(x: vPlateRect.midX - 45, y: plateY + 12), withAttributes: [
                .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: NSColor(white: 0.7, alpha: 1.0)
            ])
            
            // Right Plate: E
            let ePlateRect = CGRect(x: cardX + 240, y: plateY, width: plateWidth, height: plateHeight)
            let ePlatePath = CGPath(roundedRect: ePlateRect, cornerWidth: 12, cornerHeight: 12, transform: nil)
            ctx.saveGState()
            ctx.addPath(ePlatePath)
            ctx.setFillColor(NSColor(red: 0.06, green: 0.07, blue: 0.10, alpha: 1.0).cgColor)
            ctx.fillPath()
            ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.08).cgColor)
            ctx.strokePath()
            ctx.restoreGState()
            
            let imgE = p.renderE(zoomSize, true)
            let imgEX = ePlateRect.midX - imgE.size.width * 0.5
            let imgEY = ePlateRect.midY - imgE.size.height * 0.5 + 8
            imgE.draw(in: CGRect(x: imgEX, y: imgEY, width: imgE.size.width, height: imgE.size.height))
            
            ("English [E]" as NSString).draw(at: CGPoint(x: ePlateRect.midX - 35, y: plateY + 12), withAttributes: [
                .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: NSColor(white: 0.55, alpha: 1.0)
            ])
            
            // Bottom button tag
            let pickTag = "Chọn \(p.id)" as NSString
            let pickAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 15, weight: .bold),
                .foregroundColor: NSColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 1.0)
            ]
            pickTag.draw(at: CGPoint(x: cardX + 24, y: detailY + 35), withAttributes: pickAttrs)
        }
        
        canvas.unlockFocus()
        
        if let tiff = canvas.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            let outURL = outputDirectory.appendingPathComponent("StatusBar_Patterns_Showcase.png")
            try png.write(to: outURL)
            print("SUCCESS: StatusBar patterns showcase saved to \(outURL.path)")
        }
    }
    
    // Helper to draw realistic macOS Menu Bar
    private static func drawSimulatedMenuBar(
        ctx: CGContext,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        isDark: Bool,
        patterns: [PatternItem]
    ) {
        let barHeight: CGFloat = 46.0
        let barRect = CGRect(x: x, y: y, width: width, height: barHeight)
        let barPath = CGPath(roundedRect: barRect, cornerWidth: 10, cornerHeight: 10, transform: nil)
        
        // Bar chassis
        ctx.saveGState()
        ctx.addPath(barPath)
        if isDark {
            ctx.setFillColor(NSColor(red: 0.12, green: 0.13, blue: 0.18, alpha: 0.95).cgColor)
        } else {
            ctx.setFillColor(NSColor(red: 0.92, green: 0.93, blue: 0.96, alpha: 0.95).cgColor)
        }
        ctx.fillPath()
        ctx.setStrokeColor(isDark ? NSColor(white: 1.0, alpha: 0.12).cgColor : NSColor(white: 0.12, alpha: 0.15).cgColor)
        ctx.setLineWidth(1.0)
        ctx.strokePath()
        ctx.restoreGState()
        
        let textColor: NSColor = isDark ? .white : .black
        
        // Left Apple Logo
        let appleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: textColor.withAlphaComponent(0.9)
        ]
        ("" as NSString).draw(at: CGPoint(x: x + 20, y: y + 13), withAttributes: appleAttrs)
        
        // Simulated App Menus
        let menuAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: textColor.withAlphaComponent(0.9)
        ]
        ("VietFlow   File   Edit   View   Window   Help" as NSString).draw(at: CGPoint(x: x + 50, y: y + 14), withAttributes: menuAttrs)
        
        // Right Side: Standard macOS status items
        let rightEdge = x + width - 25
        let clockAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13.5, weight: .medium),
            .foregroundColor: textColor.withAlphaComponent(0.9)
        ]
        let timeStr = "Tue Oct 13   16:10" as NSString
        let timeSize = timeStr.size(withAttributes: clockAttrs)
        timeStr.draw(at: CGPoint(x: rightEdge - timeSize.width, y: y + 14), withAttributes: clockAttrs)
        
        var currentRight = rightEdge - timeSize.width - 30
        
        // Control Center & Battery icons (simulated)
        let glyphAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .regular),
            .foregroundColor: textColor.withAlphaComponent(0.8)
        ]
        for sysGlyph in ["WiFi", "BATT", "CTRL"] {
            (sysGlyph as NSString).draw(at: CGPoint(x: currentRight - 32, y: y + 14), withAttributes: glyphAttrs)
            currentRight -= 42
        }
        
        currentRight -= 25 // Divider gap
        
        // Now draw all 5 VietFlow Status Bar Pattern candidates side-by-side!
        for p in patterns.reversed() {
            let imgV = p.renderV(20, isDark)
            let imgW = imgV.size.width
            
            // Capsule highlight slot for current pattern
            let slotRect = CGRect(x: currentRight - imgW - 8, y: y + 8, width: imgW + 16, height: 30)
            let slotPath = CGPath(roundedRect: slotRect, cornerWidth: 6, cornerHeight: 6, transform: nil)
            ctx.saveGState()
            ctx.addPath(slotPath)
            ctx.setFillColor(isDark ? NSColor(white: 1.0, alpha: 0.08).cgColor : NSColor(white: 0.0, alpha: 0.06).cgColor)
            ctx.fillPath()
            ctx.restoreGState()
            
            imgV.draw(in: CGRect(x: currentRight - imgW, y: y + 13, width: imgW, height: 20))
            
            // Label above slot
            let tagAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 10, weight: .bold),
                .foregroundColor: isDark ? NSColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 0.9) : NSColor(red: 0.0, green: 0.45, blue: 0.85, alpha: 1.0)
            ]
            let tag = p.id as NSString
            tag.draw(at: CGPoint(x: currentRight - imgW - 6, y: y + barHeight + 5), withAttributes: tagAttrs)
            
            currentRight -= (imgW + 36)
        }
    }
}

let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
do {
    try StatusBarPatternRenderer.renderShowcase(outputDirectory: cwd)
    print("SUCCESS: StatusBar showcase generated at: \(cwd.path)/StatusBar_Patterns_Showcase.png")
} catch {
    print("ERROR: \(error)")
    exit(1)
}
