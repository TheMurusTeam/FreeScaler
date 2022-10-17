//
//  ServiceProvider.swift
//  FreeScaler
//
//  Created by Hany El Imam on 15/10/22.
//

import Foundation
import Cocoa

// /System/Library/CoreServices/pbs -flush

class ServiceProvider: NSObject {
    
    // SINGLE IMAGE
    
    @objc func serviceUpscale(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            if fileURLs.count == 1 {
                let url = fileURLs[0]
                if !(url.isPNG || url.isJPEG) {
                    // unsupported file format
                    let alert = NSAlert()
                    alert.messageText = "Unable to import this file"
                    alert.informativeText = "File format not supported. You can only upscale PNG or JPEG images."
                    alert.runModal()
                    return
                } else {
                    // import PNG/JPEG
                    importedNewFile(path: url.relativePath)
                }
                
            }
        }
    }
    
    
    // BATCH
    
    @objc func serviceBatchUpscale(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            if fileURLs.count == 1 {
                let url = fileURLs[0]
                if !url.isFolder {
                    // unsupported file format
                    let alert = NSAlert()
                    alert.messageText = "Unable to import this file"
                    alert.informativeText = "File format not supported. You can only upscale PNG or JPEG images."
                    alert.runModal()
                    return
                } else {
                    // import from folder
                    (viewCtrl["batch"] as? FSBatchViewController)?.importedNewFolder(selectedURL: url)
                }
                
            }
        }
    }
}
