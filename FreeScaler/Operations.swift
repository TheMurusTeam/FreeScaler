//
//  Operations.swift
//  FreeScaler
//
//  Created by Hany El Imam on 10/10/22.
//

import Foundation
import Cocoa


// APP VERSION AND BUILD

func freescalerVersion() -> String {
    return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "4.0"
}
func freescalerBuild() -> String {
    return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
}
func freescalerFullVersion() -> String {
    return ((Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "4.0") + " (build " + (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "000") + ")")
}





// MARK: IMPORTED NEW FILE

// called when a new image has been imported
func importedNewFile(path:String) {
    if let image = NSImage(contentsOf: URL(fileURLWithPath: path)) {
        // CHECK IMAGE SIZE
        if image.size.width > 3840 || image.size.height > 2160 {
            // ERROR, TOO BIG
            let alert = NSAlert()
            alert.messageText = "Unable to import image"
            alert.informativeText = "Image is too big. Maximum allowed size is 3840x2160."
            alert.runModal()
        } else {
            // SIZE OK
            if let appdelegate = NSApplication.shared.delegate as? AppDelegate {
                // metti app in primo piano
                NSApplication.shared.activate(ignoringOtherApps: true)
                // show tip popover
                appdelegate.popover.close()
                appdelegate.showTipPopover(target: appdelegate.upscaleBtn,
                                    txt: "Click this button to upscale the imported image")
                // enable upscale btn
                appdelegate.upscaleBtn.isEnabled = true
                appdelegate.tb_upscale.isEnabled = true
                // show clear btn
                appdelegate.clearBtn.isEnabled = true
                appdelegate.tb_clear.isEnabled = true
                // hide drop label
                appdelegate.droplabelview.isHidden = true
                // hide share btn
                appdelegate.saveBtn.isEnabled = false
                appdelegate.tb_save.isEnabled = false
                // input image size
                appdelegate.originalsize = image.size
                // input image path
                appdelegate.inputpath = path
                // show input image preview
                appdelegate.preview.image = image
                // collapse split view right side and hide divider
                appdelegate.splitview.setPosition(appdelegate.window.frame.size.width, ofDividerAt: 0)
                // nil output image view
                appdelegate.previewup.image = nil
            }
        }
    }
}



extension AppDelegate {
    
    // MARK: IMPORT IMAGE FROM FILE
    
    @IBAction func clickImport(_ sender: Any) {
        let myFiledialog:NSOpenPanel = NSOpenPanel()
        myFiledialog.allowsMultipleSelection = false
        myFiledialog.canChooseDirectories = false
        myFiledialog.title = "Import Image"
        myFiledialog.runModal()
        let chosenfile = myFiledialog.url
        if (chosenfile != nil) {
            let path = chosenfile!.relativePath
            if path.hasSuffix(".png") || path.hasSuffix(".jpg") || path.hasSuffix(".jpeg") {
                importedNewFile(path: path)
            } else {
                // unsupported image size
                let alert = NSAlert()
                alert.messageText = "Image format not supported"
                alert.informativeText = "You can only import PNG or JPEG files"
                alert.runModal()
            }
        }
    }
    
    
    // MARK: CLICK UPSCALE
    
    @IBAction func clickUpscale(_ sender: Any) {
        if let input = self.inputpath {
            // delete temporary file if needed
            do {
                try FileManager.default.removeItem(atPath: temporaryoutputpath)
            } catch {}
            //
            self.progressLabel.stringValue = "Upscaling..."
            if self.previewup.image != nil {
                // if an output image is already available we want to display it when trying another upscale
                self.splitview.setPosition(0, ofDividerAt: 0)
            }
            // disable toolbar buttons and items
            self.upscaleBtn.isEnabled = false
            self.clearBtn.isEnabled = false
            self.saveBtn.isEnabled = false
            self.importBtn.isEnabled = false
            self.tb_upscale.isEnabled = false
            self.tb_clear.isEnabled = false
            self.tb_save.isEnabled = false
            self.tb_import.isEnabled = false
            // progress view
            self.progress.doubleValue = 0
            self.progress.isHidden = true
            self.iprogress.isHidden = false
            self.iprogress.startAnimation(nil)
            self.progrview.isHidden = false
            self.progrview.wantsLayer = true
            self.progrview.canDrawSubviewsIntoLayer = true
            self.progrview.layer?.cornerRadius = 16.0
            self.progrview.layer?.borderWidth = 1
            self.progrview.layer?.borderColor = NSColor.controlAccentColor.cgColor
            self.progrview.layer?.masksToBounds = true
            self.progress.startAnimation(nil)
            
            // UPSCALER BINARY EXECUTABLE SELECTION
            var upscaler = String()
            if self.popupmodel.indexOfSelectedItem <= 2 {
                // realesrgan
                upscaler = "fs-realesrgan-ncnn-vulkan"
            } else if self.popupmodel.indexOfSelectedItem == 3 {
                // realsr
                upscaler = "fs-realsr-ncnn-vulkan"
            }
            
            // AI MODEL
            var model = String()
            if self.popupmodel.indexOfSelectedItem == 0 {
                model = "realesr-animevideov3"
            } else if self.popupmodel.indexOfSelectedItem == 1 {
                model = "realesrgan-x4plus-anime"
            } else if self.popupmodel.indexOfSelectedItem == 2 {
                model = "realesrgan-x4plus"
            } else if self.popupmodel.indexOfSelectedItem == 3 {
                model = "models-DF2K_JPEG"
            }
            
            // SCALE
            var scale = 4
            if self.popupmodel.indexOfSelectedItem == 0 {
                scale = (self.popupscale.indexOfSelectedItem + 2)
            }
            
            // RUN BUILT-IN UPSCALER EXECUTABLE
            upscale(upscaler: upscaler,
                    input: input,
                    model: model,
                    scale: scale,
                    tta: self.ttaBtn.state == .on)
        }
    }
    
    
    // MARK: CLICK STOP
    
    // abort upscale task
    @IBAction func clickStopBtn(_ sender: Any) {
        stopUpscalerProcess()
        // hide progress view
        self.progress.isHidden = true
        self.iprogress.stopAnimation(nil)
        self.progrview.isHidden = true
        self.progress.stopAnimation(nil)
        // enable toolbar buttons and items
        self.upscaleBtn.isEnabled = true
        self.importBtn.isEnabled = true
        self.saveBtn.isEnabled = false
        self.clearBtn.isEnabled = true
        self.tb_upscale.isEnabled = true
        self.tb_import.isEnabled = true
        self.tb_save.isEnabled = false
        self.tb_clear.isEnabled = true
    }
    
    
    
    
    // MARK: DISPLAY UPSCALE RESULT
    
    // called when upscale procedure has finished
    func displayresult() {
        if let image = NSImage(contentsOf: URL(fileURLWithPath: temporaryoutputpath)) {
            if let size = self.originalsize {
                image.size = size
            }
            // enable toolbar buttons and items
            self.upscaleBtn.isEnabled = true
            self.importBtn.isEnabled = true
            self.saveBtn.isEnabled = true
            self.clearBtn.isEnabled = true
            self.tb_upscale.isEnabled = true
            self.tb_import.isEnabled = true
            self.tb_save.isEnabled = true
            self.tb_clear.isEnabled = true
            self.previewup.image = image
            // hide progress view
            self.progress.isHidden = true
            self.iprogress.stopAnimation(nil)
            self.progrview.isHidden = true
            self.progress.stopAnimation(nil)
            // put split view divider in the middle to display both images
            self.splitview.setPosition((self.window.frame.size.width / 2), ofDividerAt: 0)
            self.showTipPopover(target: self.dividerPlaceholderView,
                                txt: "Move the divider to compare the original and the upscaled image")
        }
    }
    
    
    
    
    // MARK: CLEAR
    
    // clear current images
    @IBAction func clickClear(_ sender: Any) {
        self.splitview.setPosition(self.window.frame.size.width, ofDividerAt: 0)
        self.previewup.image = nil
        self.upscaleBtn.isEnabled = false
        self.saveBtn.isEnabled = false
        self.clearBtn.isEnabled = false
        self.tb_upscale.isEnabled = false
        self.tb_save.isEnabled = false
        self.tb_clear.isEnabled = false
        self.droplabelview.isHidden = false
        self.preview.image = nil
        // delete temporary file if needed
        do {
            try FileManager.default.removeItem(atPath: temporaryoutputpath)
        } catch {}
    }
    
    
    
    
    
    // MARK: SAVE/SHARE
    
    // draw share menu
    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, sharingServicesForItems items: [Any], proposedSharingServices proposedServices: [NSSharingService]) -> [NSSharingService] {
        guard let image = NSImage(named: "Freescaler") else {
            return proposedServices
        }
        var share = proposedServices
        let customService = NSSharingService(title: "Save Image As...", image: image, alternateImage: image, handler: {
            if let _ = items.first as? NSImage {
                // action
                self.displaySavePanel()
            }
        })
        share.insert(customService, at: 0)
        return share
    }
    
    // share or save output image
    @IBAction func clickSaveButton(_ sender: NSButton) {
        let image = self.previewup.image ?? NSImage()
        let sharingPicker = NSSharingServicePicker(items: [image])
        sharingPicker.delegate = self
        sharingPicker.show(relativeTo: NSZeroRect, of: sender, preferredEdge: .minY)
    }
    
    // called when pressing COMMAND-S to save the output image
    @IBAction func selectSaveAsMenuItem(_ sender: Any) {
        if let _ = self.previewup.image {
            displaySavePanel()
        }
    }
    
    
    // save panel
    func displaySavePanel() {
        let panel = NSSavePanel()
        // suggested file name
        if let ipath = inputpath {
            let url = NSURL(fileURLWithPath: ipath)
            if let filename = url.lastPathComponent {
                let filenoext = (filename as NSString).deletingPathExtension
                let proposedfilename = filenoext + "-UPSCALED" + ".\(fileformat)"
                panel.nameFieldStringValue = proposedfilename
            }
        }
        panel.title = "Save image"
        panel.prompt = "Save"
        if panel.runModal().rawValue == 1 {
            if let path = panel.url?.path {
                do {
                    try FileManager.default.copyItem(atPath: temporaryoutputpath, toPath: path)
                } catch {}
            }
        }
    }
    
    
    
    
    
    
    // MARK: POPUPS
    
    // called when switching AI Model from toolbar popup
    @IBAction func switchModel(_ sender: NSPopUpButton) {
        UserDefaults.standard.setValue(sender.indexOfSelectedItem, forKey: lastselectedmodel)
        self.displayScalePopup()
    }
    
    // update toolbar scale popup based on selection of model popup
    func displayScalePopup() {
        self.popupscale.isEnabled = self.popupmodel.indexOfSelectedItem == 0
        self.tb_popupscale.isEnabled = self.popupscale.isEnabled
        if self.popupmodel.indexOfSelectedItem != 0 {
            self.popupscale.selectItem(at: 2)
        }
    }
    
    
    
    // MARK: SHOW ABOUT PANEL
    
    @IBAction func clickAbout(_ sender: Any) {
        self.versionstring.stringValue = freescalerFullVersion()
        self.aboutwin.makeKeyAndOrderFront(nil)
        self.aboutwin.center()
    }
    
    
    
    
    // MARK: WELCOME WINDOW
    
    // display initial welcome window (only one time)
    func displayWelcome() {
#if DEBUG
        // always show welcome in debug
        //self.window?.beginSheet(self.welcomeWindow)
#else
        if UserDefaults.standard.value(forKey: welcomeKey) as? Bool != true {
            // store default value to avoid displaying welcome window more than one time
            UserDefaults.standard.setValue(true, forKey: welcomeKey)
            // display welcome win
            self.window?.beginSheet(self.welcomeWindow)
        }
#endif
        
    }

    // dismiss welcome window in last tabview tab
    @IBAction func closeWelcome(_ sender: Any) {
        self.window?.endSheet(self.welcomeWindow)
        // show tip popover
        self.showTipPopover(target: self.importBtn,
                            txt: "Click this button to import a PNG or JPEG image file or drag an image from the Finder")
    }
    
    
    
    
    
    
    
    
    
    // MARK: TIPS POPOVER

    // suppression button in popover
    @IBAction func clickDoNotDisplayTips(_ sender: NSButton) {
        UserDefaults.standard.setValue(sender.state == .on, forKey: tipsKey)
    }
    
    
    // show tip popover
    func showTipPopover(target:NSView,txt:String) {
        if UserDefaults.standard.value(forKey: tipsKey) as? Bool == true {
            // do not display tips
        } else {
            // display tip
            let popoverCtrl = NSViewController()
            popoverCtrl.view = NSView()
            popover.contentViewController = popoverCtrl
            popover.behavior = NSPopover.Behavior.transient
            popover.animates = true
            self.popoverTxt.stringValue = txt
            popoverCtrl.view = self.popoverView
            popoverCtrl.view.wantsLayer = true
            // show popover
            popover.show(relativeTo: target.bounds,
                         of: target,
                         preferredEdge: NSRectEdge.maxY)
        }
    }
    
    
    
    
    
    // MARK: HELP MENU ITEM
    
    @IBAction func clickHelpMenuItem(_ sender: Any) {
        self.welcomeTabview.selectTabViewItem(at: 1)
        self.window?.beginSheet(self.welcomeWindow)
    }
    
    
}
