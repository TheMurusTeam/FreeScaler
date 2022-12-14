//
//  Dropview.swift
//  FreeScaler
//
//  Created by Hany El Imam on 10/10/22.
//

import Foundation
import Cocoa



// MARK: URL TYPE IDENTIFIER

// UTI Docs: https://developer.apple.com/documentation/uniformtypeidentifiers/system-declared_uniform_type_identifiers

extension URL {
    var typeIdentifier: String? { (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier }
    var isPNG: Bool { typeIdentifier == "public.png" }
    var isJPEG: Bool { typeIdentifier == "public.jpeg" }
    var isFolder: Bool { typeIdentifier == "public.folder" }
    var isDirectory: Bool { typeIdentifier == "public.directory" }
    var localizedName: String? { (try? resourceValues(forKeys: [.localizedNameKey]))?.localizedName }
    var hasHiddenExtension: Bool {
        get { (try? resourceValues(forKeys: [.hasHiddenExtensionKey]))?.hasHiddenExtension == true }
        set {
            var resourceValues = URLResourceValues()
            resourceValues.hasHiddenExtension = newValue
            try? setResourceValues(resourceValues)
        }
    }
}



// MARK: DROP VIEW

class DropView: NSView {

    var mycolor : CGColor = CGColor.clear

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.gray.cgColor
        registerForDraggedTypes([NSPasteboard.PasteboardType.URL, NSPasteboard.PasteboardType.fileURL])
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        // Drag only one item
        guard let pasteboard = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
              let path = pasteboard[0] as? String
        else { return NSDragOperation() }
        
        if pasteboard.count == 1 {
            if URL(fileURLWithPath: path).isPNG || URL(fileURLWithPath: path).isJPEG || URL(fileURLWithPath: path).isFolder {
                return .copy
            }
        }
        
        return NSDragOperation()
        
    }

   
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        self.layer?.backgroundColor = self.mycolor
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        self.layer?.backgroundColor = self.mycolor
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let pasteboard = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
              let path = pasteboard[0] as? String
        else { return false }
        
        
        let url = URL(fileURLWithPath: path)
        if url.isJPEG || url.isPNG {
            
            // SINGLE IMAGE
            
            // print("importing single image from file at \(path)")
            importedNewFile(path: path)
            return true
        } else if url.isFolder {
            
            // BATCH FOLDER
            
            // print("importing images from folder at \(path)")
            if let batchview = viewCtrl["batch"] as? FSBatchViewController {
                batchview.importedNewFolder(selectedURL: url)
            }
            return true
        } else {
            // print("cannot import, object is not a PNG or JPEG image")
            return false
        }
        
        
    }
}




