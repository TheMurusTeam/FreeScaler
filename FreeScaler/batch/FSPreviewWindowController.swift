//
//  FSPreviewWindowController.swift
//  FreeScaler
//
//  Created by Hany El Imam on 16/10/22.
//

import Cocoa

class FSPreviewWindowController: NSWindowController, NSWindowDelegate, NSSplitViewDelegate {
    
    
    var inputPath = String()
    var upscaledImage = NSImage()
    @IBOutlet weak var splitview: NSSplitView!
    @IBOutlet weak var right: NSView!
    @IBOutlet weak var left: NSView!
    @IBOutlet weak var img_left: NSImageView!
    @IBOutlet weak var img_right: NSImageView!
    
    
    
    convenience init(windowNibName:String, inputPath: String, upscaledImage: NSImage) {
        self.init(windowNibName:windowNibName)
        self.inputPath = inputPath
        self.upscaledImage = upscaledImage
    }
    
    
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.img_left.image = NSImage(contentsOf: URL(fileURLWithPath: self.inputPath))
        self.upscaledImage.size = self.img_left.image!.size
        self.img_right.image = self.upscaledImage
        
        let filename = URL(fileURLWithPath: self.inputPath).lastPathComponent
        let filenoext = (filename as NSString).deletingPathExtension
        self.window?.title = filenoext + ".\(fileformat)"
        
        
        
    }
    
    
    
    
    
    
    
    
    
}







