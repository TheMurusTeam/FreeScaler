//
//  Start FreeScaler.swift
//  FreeScaler
//
//  Created by Hany El Imam on 13/10/22.
//

import Foundation
import Cocoa

// FreeScaler startup

extension AppDelegate {
    
    
    func startFreeScale() {
        // service provider
        NSApplication.shared.servicesProvider = ServiceProvider()
        NSUpdateDynamicServices()
        // prefs
        self.readPreferences()
        // collapse split view's right view
        self.splitview.setPosition(self.window.frame.size.width, ofDividerAt: 0)
        // toolbar model popup
        if let lastmodelindex = UserDefaults.standard.value(forKey: lastselectedmodel) as? Int {
            self.popupmodel.selectItem(at: lastmodelindex)
        }
        // update status of scale popup
        self.displayScalePopup()
        // tb buttons
        self.saveBtn.sendAction(on: .leftMouseDown)
        self.upscaleBtn.isEnabled = false
        self.saveBtn.isEnabled = false
        self.clearBtn.isEnabled = false
        // draw drop label view border
        self.droplabelview.canDrawSubviewsIntoLayer = true
        self.droplabelview.layer?.cornerRadius = 16.0
        self.droplabelview.layer?.borderWidth = 1
        self.droplabelview.layer?.borderColor = NSColor.tertiaryLabelColor.cgColor
        self.droplabelview.layer?.masksToBounds = true
        // display welcome
        self.displayWelcome()
    }
    
    
}
