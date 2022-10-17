//
//  FSBatchViewController.swift
//  FreeScaler
//
//  Created by Hany El Imam on 15/10/22.
//

import Cocoa


let temporaryoutputBatchpath = NSTemporaryDirectory() + "batch/"


class FSImage : NSObject {
    @objc dynamic var path: String
    @objc dynamic var outputpath : String? = nil
    @objc dynamic var thumbnail: NSImage
    @objc dynamic var sizeString: String
    @objc dynamic var isUpscaling: Bool
    @objc dynamic var upscaled: Bool
    @objc dynamic var progr: Double {
        didSet {
            if progr > 8800 {
                progr = 10000
            }
        }
    }
    var upscaledImage = NSImage()
    
    init(path: String, thumbnail:NSImage, originalSize:NSSize) {
        self.path = path
        self.thumbnail = thumbnail
        self.sizeString = "\(Int(originalSize.width))x\(Int(originalSize.height))"
        self.isUpscaling = false
        self.upscaled = false
        self.progr = 0
    }
}


class FSProgressIndicator : NSProgressIndicator {
    
}



class FSBatchViewController: NSViewController,NSSharingServicePickerDelegate {
    
    @objc dynamic var images = [FSImage]()
    @IBOutlet var imagesArrayController: NSArrayController!
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var progrview: NSView!
    
    @IBOutlet weak var progress: NSProgressIndicator!
    @IBOutlet weak var progrLabel: NSTextField!
    @IBOutlet weak var progrStopBtn: NSButton!
    @IBOutlet weak var iprogress: NSProgressIndicator!
    @objc dynamic var isUpscaling = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // progress view
        self.progrview.wantsLayer = true
        self.progrview.canDrawSubviewsIntoLayer = true
        self.progrview.layer?.cornerRadius = 16.0
        self.progrview.layer?.borderWidth = 1
        self.progrview.layer?.borderColor = NSColor.controlAccentColor.cgColor
        self.progrview.layer?.masksToBounds = true
        self.iprogress.startAnimation(nil)
        self.hideProgressView()
    }
    
    
    func hideProgressView() {
        self.progress.doubleValue = 0
        self.progress.isHidden = true
        self.progress.stopAnimation(nil)
        self.iprogress.isHidden = true
        self.iprogress.stopAnimation(nil)
        self.progrStopBtn.isHidden = false
        self.progrview.isHidden = true
    }
    
    func showProgressViewForImport() {
        self.progress.doubleValue = 0
        self.progress.isHidden = true
        self.progress.stopAnimation(nil)
        self.iprogress.isHidden = false
        self.iprogress.startAnimation(nil)
        self.progrview.isHidden = false
        self.progrStopBtn.isHidden = true
        self.progrLabel.stringValue = "Importing images..."
    }
    
    
    
    // MARK: IMPORT IMAGES FROM FOLDER
    
    func importedNewFolder(selectedURL:URL) {
        self.images = [FSImage]()
        self.imagesArrayController.content = nil
        // switch to batch view
        freeScalerMode = 1
        (NSApplication.shared.delegate as? AppDelegate)?.mainTabView.selectTabViewItem(at: 1)
        self.showProgressViewForImport()
        
        DispatchQueue.global().async {
            
            var imagesHasBeenFound = false
            if let enumerator = FileManager.default.enumerator(at: selectedURL,
                                                               includingPropertiesForKeys: [.isDirectoryKey, .nameKey],
                                                               options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles],
                                                               errorHandler: nil) {
                enumerator.forEach { (url) in
                    guard let url = url as? URL else { return }
                    if url.isPNG || url.isJPEG {
                        imagesHasBeenFound = true
                        if let imageInfo = imageInfoFromFile(photoAt: url, to: NSSize(width: 241, height: 162)) {
                            DispatchQueue.main.async {
                                self.imagesArrayController.addObject(FSImage(path: url.relativePath,
                                                                             thumbnail: imageInfo.1,
                                                                             originalSize: imageInfo.0))
                            }
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                if let appdelegate = NSApplication.shared.delegate as? AppDelegate {
                    if imagesHasBeenFound {
                        
                        // enable upscale btn
                        appdelegate.upscaleBtn.isEnabled = true
                        appdelegate.tb_upscale.isEnabled = true
                        // show clear btn
                        appdelegate.clearBtn.isEnabled = true
                        appdelegate.tb_clear.isEnabled = true
                        // hide share btn
                        appdelegate.saveBtn.isEnabled = false
                        appdelegate.tb_save.isEnabled = false
                        appdelegate.showTipPopover(target: appdelegate.upscaleBtn,
                                                   txt: "Click this button to start batch upscale")
                    } else {
                        // NO IMAGE IMPORTED
                        
                        let alert = NSAlert()
                        alert.messageText = "No images to import"
                        alert.runModal()
                        (NSApplication.shared.delegate as? AppDelegate)?.mainTabView.selectTabViewItem(at: 0)
                    }
                }
                self.hideProgressView()
            }
            
        }
        
    }
    
    
    
    
    // MARK: REMOVE IMAGE FROM LIST
    
    @IBAction func deleteImage(_ sender: NSButton) {
        if let pathToDelete = sender.toolTip {
            // delete output file if needed
            for img in self.images {
                if pathToDelete == img.path {
                    do {
                        if let outpath = img.outputpath {
                            if FileManager.default.fileExists(atPath: outpath) {
                                try FileManager.default.removeItem(at: URL(fileURLWithPath: outpath))
                            }
                        }
                    } catch {}
                }
            }
            // update images array
            self.images = self.images.filter {$0.path != pathToDelete}
        }
        if self.images.isEmpty {
            (NSApplication.shared.delegate as? AppDelegate)?.clearAll()
        }
    }
    
    
    
    
    
    
    
    
    // MARK: - CLICK UPSCALE
    
    
    var upscaleStopped = false
    
    func stopUpscale() {
        self.upscaleStopped = true
        stopUpscalerProcess()
        
    }
    
    // called from toolbar button
    func runBatchUpscale() {
        // delete temporary batch files if needed
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: temporaryoutputBatchpath),
                                                                       includingPropertiesForKeys: nil,
                                                                       options: .skipsHiddenFiles)
            for fileURL in fileURLs {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch  { }
        
        self.isUpscaling = true
        self.upscaleStopped = false
        
        // reset models
        for img in self.images {
            img.isUpscaling = false
            img.upscaled = false
            img.upscaledImage = NSImage()
            img.progr = 0
            img.outputpath = nil
        }
        
        if let appdelegate = (NSApplication.shared.delegate as? AppDelegate) {
            // toolbar buttons
            appdelegate.upscaleBtn.isEnabled = false
            appdelegate.saveBtn.isEnabled = false
            appdelegate.clearBtn.isEnabled = false
            appdelegate.importBtn.isEnabled = false
            appdelegate.tb_upscale.isEnabled = false
            appdelegate.tb_save.isEnabled = false
            appdelegate.tb_clear.isEnabled = false
            appdelegate.tb_import.isEnabled = false
            appdelegate.popupscale.isEnabled = false
            appdelegate.popupmodel.isEnabled = false
            appdelegate.tb_popupscale.isEnabled = false
            appdelegate.tb_popupmodel.isEnabled = false
            appdelegate.tb_tta.isEnabled = false
            appdelegate.ttaBtn.isEnabled = false
            appdelegate.tb_stop.isEnabled = true
            appdelegate.stopBtn.isEnabled = true
        }
        //
        self.upscaleBatch(index: 0)
    }
    
    
    // main upscale loop
    func upscaleBatch(index:Int) { //
        
        var upscaler = String()
        var model = String()
        var scale = 4
        var tta = false
        
        // read upscale options
        if let appdelegate = (NSApplication.shared.delegate as? AppDelegate) {
            // UPSCALER BINARY EXECUTABLE SELECTION
            if appdelegate.popupmodel.indexOfSelectedItem <= 2 {
                // realesrgan
                upscaler = "fs-realesrgan-ncnn-vulkan"
            } else if appdelegate.popupmodel.indexOfSelectedItem == 3 {
                // realsr
                upscaler = "fs-realsr-ncnn-vulkan"
            }
            
            // AI MODEL
            if appdelegate.popupmodel.indexOfSelectedItem == 0 {
                model = "realesr-animevideov3"
            } else if appdelegate.popupmodel.indexOfSelectedItem == 1 {
                model = "realesrgan-x4plus-anime"
            } else if appdelegate.popupmodel.indexOfSelectedItem == 2 {
                model = "realesrgan-x4plus"
            } else if appdelegate.popupmodel.indexOfSelectedItem == 3 {
                model = "models-DF2K_JPEG"
            }
            
            // SCALE
            if appdelegate.popupmodel.indexOfSelectedItem == 0 {
                scale = (appdelegate.popupscale.indexOfSelectedItem + 2)
            }
            
            // TTA
            tta = appdelegate.ttaBtn.state == .on
        }
        
        // RUN BUILT-IN UPSCALER EXECUTABLE
        
        let img = self.images[index]
        // print("upscaling index:\(index) path:\(img.path)")
        self.bupscale(upscaler: upscaler,
                      input: img.path,
                      model: model,
                      scale: scale,
                      tta: tta,
                      img: img,
                      index: index)
        
    }
    
    
    
    // MARK: UPSCALE BATCH TASK
    
    // output images are saved to a temporary directory inside app's sandbox
    func bupscale(upscaler:String,
                  input:String,
                  model:String,
                  scale:Int,
                  tta:Bool,
                  img:FSImage,
                  index:Int) {
        
        
        img.isUpscaling = true
        img.progr = 0
        upscalername = upscaler
        
        // define outout file name
        var proposedfilename : String? = nil
        let url = NSURL(fileURLWithPath: input)
        if let filename = url.lastPathComponent {
            let filenoext = (filename as NSString).deletingPathExtension
            proposedfilename = filenoext + "-UPSCALED" + ".\(fileformat)"
        }
        
        if let outputFileName = proposedfilename {
            
            let task = Process()
            task.currentDirectoryURL = Bundle.main.resourceURL
            task.executableURL = Bundle.main.resourceURL
            task.launchPath = "\(resourcepath!)/\(upscaler)"    // upscaler binary exe
            
            // args
            task.arguments = ["-i",input,                       // input path
                              "-o",temporaryoutputBatchpath + outputFileName,         // output path
                              "-s",String(scale),               // scale size (2x,3x,4x)
                              "-f","ext/" + fileformat          // export file format
            ]
            // options
            if tta { task.arguments?.append("-x") }             // test-time augmentation
            // AI model selection
            if upscaler == "fs-realesrgan-ncnn-vulkan" {
                task.arguments?.append("-n")
                task.arguments?.append(model)                   // realesrgan model name
            } else if upscaler == "fs-realsr-ncnn-vulkan" {
                task.arguments?.append("-m")
                task.arguments?.append(model)                   // realsr model name
            }
            
            // task
            let pipe = Pipe()
            task.standardError = pipe
            let outHandle = pipe.fileHandleForReading
            outHandle.waitForDataInBackgroundAndNotify()
            
            // get standardError in real time
            var obs1 : NSObjectProtocol!
            obs1 = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable,object: outHandle, queue: nil) {  notification -> Void in
                let data = outHandle.availableData
                if data.count > 0 {
                    if let string = String(data: data,
                                           encoding: String.Encoding.ascii) {
                        // update determinate progress indicator
                        if let number = Int.parse(from: string) {
                            if number > 10 {
                                img.progr = Double(number)
                            }
                        }
                    }
                    outHandle.waitForDataInBackgroundAndNotify()
                } else {
                    NotificationCenter.default.removeObserver(obs1!)
                }
            }
            
            // task has finished
            var obs2 : NSObjectProtocol!
            obs2 = NotificationCenter.default.addObserver(forName: Process.didTerminateNotification,object: task, queue: nil) { notification -> Void in
                NotificationCenter.default.removeObserver(obs2!)
                
                // TASK FINISHED
                
                img.isUpscaling = false
                
                if let upscaledImage = NSImage(contentsOf: URL(fileURLWithPath: temporaryoutputBatchpath + outputFileName)) {
                    // print("storing upscaled image into model")
                    img.upscaledImage = upscaledImage
                    img.upscaled = true
                    img.outputpath = temporaryoutputBatchpath + outputFileName
                }
                
                // BATCH LOOP
                
                if index < (self.images.count - 1) && self.upscaleStopped == false {
                    // upscale next image
                    self.upscaleBatch(index: index + 1)
                } else {
                    // batch finished
                    self.displayBatchResult()
                }
            }
            task.launch()
        }
    }
    
    
    
    
    // MARK: - DISPLAY RESULT
    
    func displayBatchResult() {
        self.isUpscaling = false
        // toolbar buttons
        if let appdelegate = (NSApplication.shared.delegate as? AppDelegate) {
            appdelegate.upscaleBtn.isEnabled = true
            appdelegate.saveBtn.isEnabled = true
            appdelegate.clearBtn.isEnabled = true
            appdelegate.importBtn.isEnabled = true
            appdelegate.tb_upscale.isEnabled = true
            appdelegate.tb_save.isEnabled = true
            appdelegate.tb_clear.isEnabled = true
            appdelegate.tb_import.isEnabled = true
            appdelegate.popupscale.isEnabled = true
            appdelegate.popupmodel.isEnabled = true
            appdelegate.tb_popupscale.isEnabled = true
            appdelegate.tb_popupmodel.isEnabled = true
            appdelegate.tb_tta.isEnabled = true
            appdelegate.ttaBtn.isEnabled = true
            appdelegate.tb_stop.isEnabled = false
            appdelegate.stopBtn.isEnabled = false
        }
        for img in self.images {
            if img.isUpscaling {
                img.isUpscaling = false
                img.upscaled = false
            }
        }
        
        if !self.images.filter({ $0.upscaled }).isEmpty {
            if !self.images.isEmpty {
                if let firstitem = self.collectionView.item(at: 0) {
                    if let appdelegate = (NSApplication.shared.delegate as? AppDelegate) {
                        appdelegate.showTipPopover(target: firstitem.view,
                                                   txt: "Select an image and click the magnifier to compare original and upscaled image or click the share button to save the image\n\nClick the share button in the toolbar to save all outscaled images to folder")
                    }
                }
            }
        }
        
        // show tmp dir
        //NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: temporaryoutputBatchpath)])
    }
    
    
    // MARK: PREVIEW
    
    @IBAction func clickPreview(_ sender: NSButton) {
        if let path = sender.toolTip {
            let images = self.images.filter({ $0.path == path })
            if images.count == 1 {
                let image = images[0]
                // print("preview image at \(path)")
                winCtrl["preview"] = FSPreviewWindowController(windowNibName: "FSPreviewWindowController",
                                                               inputPath: image.path,
                                                               upscaledImage: image.upscaledImage)
                (winCtrl["preview"] as? FSPreviewWindowController)?.window?.makeKeyAndOrderFront(nil)
            }
        }
    }
    
    
    // MARK: SAVE/SHARE
    
    // draw share menu
    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, sharingServicesForItems items: [Any], proposedSharingServices proposedServices: [NSSharingService]) -> [NSSharingService] {
        guard let image = NSImage(named: "Freescaler") else {
            return proposedServices
        }
        var share = proposedServices
        let customService = NSSharingService(title: "Save As...", image: image, alternateImage: image, handler: {
            if let _ = items.first as? NSImage {
                // action
                self.displaySavePanel()
            }
        })
        share.insert(customService, at: 0)
        return share
    }
    
    var singleImageOutputPath = String()
    var singleImagePath = String()
    
    @IBAction func clickShareImage(_ sender: NSButton) {
        if let path = sender.toolTip {
            self.singleImagePath = path
            let images = self.images.filter({ $0.path == path })
            if images.count == 1 {
                let image = images[0]
                if let outpath = image.outputpath {
                    self.singleImageOutputPath = outpath
                    let items = [image.upscaledImage]
                    let sharingPicker = NSSharingServicePicker(items: items)
                    sharingPicker.delegate = self
                    sharingPicker.show(relativeTo: NSZeroRect, of: sender, preferredEdge: .minY)
                }
            }
        }
    }
    
    
    // save panel for single batch image
    func displaySavePanel() {
        let panel = NSSavePanel()
        // suggested file name
        let ipath = self.singleImagePath
        let url = NSURL(fileURLWithPath: ipath)
        if let filename = url.lastPathComponent {
            let filenoext = (filename as NSString).deletingPathExtension
            let proposedfilename = filenoext + "-UPSCALED" + ".\(fileformat)"
            panel.nameFieldStringValue = proposedfilename
        }
        
        panel.title = "Save image"
        panel.prompt = "Save Image"
        if panel.runModal().rawValue == 1 {
            if let path = panel.url?.path {
                do {
                    try FileManager.default.copyItem(atPath: self.singleImageOutputPath, toPath: path)
                } catch {}
            }
        }
        self.singleImagePath = String()
        self.singleImageOutputPath = String()
    }
    
    
}












// MARK: IMAGE INFO FROM FILE

// get original size and thumbnail
func imageInfoFromFile(photoAt url: URL?, to size: NSSize) -> (NSSize,NSImage)? {
    if let url = url, let photo = NSImage(contentsOf: url) {
        let originalSize = photo.size
        if originalSize.width > 3840 || originalSize.height > 2160 {
            return nil // image too big
        }
        let ratio = photo.size.width > photo.size.height ? size.width / photo.size.width : size.height / photo.size.height
        var rect = NSRect(origin: .zero, size: NSSize(width: photo.size.width * ratio, height: photo.size.height * ratio))
        rect.origin = NSPoint(x: (size.width - rect.size.width)/2, y: (size.height - rect.size.height)/2)
        let thumbnail = NSImage(size: size)
        thumbnail.lockFocus()
        photo.draw(in: rect,
                   from: NSRect(origin: .zero, size: photo.size),
                   operation: .copy, fraction: 1.0)
        thumbnail.unlockFocus()
        return (originalSize, thumbnail)
    }
    
    return nil
}

