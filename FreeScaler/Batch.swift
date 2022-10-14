//
//  Batch.swift
//  FreeScaler
//
//  Created by Hany El Imam on 14/10/22.
//

import Foundation
import Cocoa





extension AppDelegate {
    
    /*
    // MARK: SELECT BATCH FOLDER
    
    @IBAction func openDir(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.title = "Select folder"
        panel.runModal()
        if let choosenurl = panel.url {
            let files = self.getPNGandJPEGimagesFromDir(path: choosenurl)
            let pngs = files.0
            let jpgs = files.1
            print("PNGs:\(pngs.joined(separator: ","))")
            print("JPGs:\(jpgs.joined(separator: ","))")
        }
    }
    
    
    
    
    // MARK: FIND PNG AND JPEG FILES IN DIRECTORY
    
    func getPNGandJPEGimagesFromDir(path:URL) -> ([String],[String]) {
        do {
            // FILES
            let directoryContents = try FileManager.default.contentsOfDirectory(
                at: path,
                includingPropertiesForKeys: nil
            )
            // PNG
            let png_images = directoryContents.filter(\.isPNG).map { $0.localizedName ?? $0.lastPathComponent }
            // JPG
            let jpg_images = directoryContents.filter(\.isJPEG).map { $0.localizedName ?? $0.lastPathComponent }
            // OUT
            return (png_images,jpg_images)
        } catch {}
        return ([],[])
    }
    */
    
    
}





















