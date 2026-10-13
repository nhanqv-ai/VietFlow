//
//  main.swift
//  VietFlowApp
//
//  Application entry point for VietFlow.
//

import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory) // Runs as Menu Bar Agent (LSUIElement)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
