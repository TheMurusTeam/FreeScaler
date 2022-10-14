//
//  Preferences.swift
//  FreeScaler
//
//  Created by Hany El Imam on 12/10/22.
//

import Foundation
import Cocoa

extension AppDelegate {
    
    
    @IBAction func openPreferences(_ sender: Any) {
        self.prefsWindow.makeKeyAndOrderFront(nil)
        self.readPreferences()
    }
    
    
    
    // MARK: READ PREFERENCES
    
    func readPreferences() {
        // draw preferences controls
        // always on top
        if (UserDefaults.standard.value(forKey: key_ontop) as? Bool) == true {
            self.btn_alwaysOnTop.state = .on
        } else {
            self.btn_alwaysOnTop.state = .off
        }
        // display tips
        if UserDefaults.standard.value(forKey: tipsKey) as? Bool == true {
            self.btn_displaytips.state = .off
        } else {
            self.btn_displaytips.state = .on
        }
        // format popup
        if let formindex = UserDefaults.standard.value(forKey: formatpopupkey) as? Int {
            self.popup_format.selectItem(at: formindex)
            if formindex == 0 {
                fileformat = "png"
            } else if formindex == 1 {
                fileformat = "jpg"
            }
        } else {
            self.popup_format.selectItem(at: 0)
            fileformat = "png"
        }
        
        
        // windows
        if (UserDefaults.standard.value(forKey: key_ontop) as? Bool) == true {
            self.window?.level = .modalPanel
            self.prefsWindow.level = .modalPanel
        } else {
            self.window?.level = .normal
            self.prefsWindow.level = .normal
        }
        
    }
    
    
    // MARK: CHANGE PREFS
    
    @IBAction func switchAlwaysOnTop(_ sender: NSButton) {
        UserDefaults.standard.setValue(sender.state == .on, forKey: key_ontop)
        self.readPreferences()
    }
    
    
    @IBAction func switchDisplayTips(_ sender: NSButton) {
        UserDefaults.standard.setValue(sender.state == .off, forKey: tipsKey)
    }
    
    @IBAction func switchExportFormat(_ sender: NSPopUpButton) {
        UserDefaults.standard.set(sender.indexOfSelectedItem, forKey: formatpopupkey)
        if sender.indexOfSelectedItem == 0 {
            fileformat = "png"
        } else if sender.indexOfSelectedItem == 1 {
            fileformat = "jpg"
        }
    }
    
    
    
    
    
    
}













