//
//  AppDelegate.swift
//  FreeScaler
//
//  Created by Hany El Imam on 10/10/22.
//

import Cocoa

/*
 _____  ____     ___    ___  _____   __   ____  _        ___  ____
|     ||    \   /  _]  /  _]/ ___/  /  ] /    || |      /  _]|    \
|   __||  D  ) /  [_  /  [_(   \_  /  / |  o  || |     /  [_ |  D  )
|  |_  |    / |    _]|    _]\__  |/  /  |     || |___ |    _]|    /
|   _] |    \ |   [_ |   [_ /  \ /   \_ |  _  ||     ||   [_ |    \
|  |   |  .  \|     ||     |\    \     ||  |  ||     ||     ||  .  \
|__|   |__|\_||_____||_____| \___|\____||__|__||_____||_____||__|\_|
                                                                             
*/

// Upscaler for macOS
// developed by Hany El Imam
// and Davide Feroldi

// https://www.murusfirewall.com/freescaler
// info@murus.it


// global stores
var viewCtrl = [String:NSViewController]()
var winCtrl = [String:NSWindowController]()

// apply view constraints
func applyConstraints(view:NSView,containerView:NSView,_ translate:Bool = false) {
    view.translatesAutoresizingMaskIntoConstraints = translate
    containerView.addConstraint(NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .top, multiplier: 1, constant: 0))
    containerView.addConstraint(NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: containerView, attribute:.bottom, multiplier: 1, constant: 0))
    containerView.addConstraint(NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: .equal, toItem: containerView, attribute: .trailing, multiplier: 1, constant: 0))
    containerView.addConstraint(NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: containerView, attribute:.leading, multiplier: 1, constant: 0))
}


var freeScalerMode : Int = 0 // 0:single image, 1:batch


@main
class AppDelegate: NSObject, NSApplicationDelegate,
                             NSWindowDelegate,
                             NSSplitViewDelegate,
                             NSSharingServicePickerDelegate {
    
    
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) { self.startFreeScale() }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {return true}
    func applicationWillTerminate(_ aNotification: Notification) { }
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {return true}
    func windowWillClose(_ notification: Notification) {NSApplication.shared.terminate(nil)}
    
    
    
    // OUTLETS
    
    @IBOutlet var window: NSWindow!                     // main freescaler window
    @IBOutlet weak var aboutwin: NSWindow!              // about window
    @IBOutlet weak var welcomeWindow: NSWindow!         // welcome window
    @IBOutlet weak var prefsWindow: NSWindow!           // prefs window
    @IBOutlet weak var mainTabView: NSTabView!
    @IBOutlet weak var droplabelview: NSView!
    @IBOutlet weak var iprogress: NSProgressIndicator!
    @IBOutlet weak var progress: NSProgressIndicator!
    @IBOutlet weak var dragview: NSView!
    @IBOutlet weak var preview: NSImageView!            // original image
    @IBOutlet weak var previewup: NSImageView!          // upscaled image
    @IBOutlet weak var progrview: NSView!
    @IBOutlet weak var versionstring: NSTextField!
    @IBOutlet weak var splitview: NSSplitView!
    @IBOutlet weak var rightview: NSView!
    @IBOutlet weak var leftview: NSView!
    @IBOutlet weak var welcomeTabview: NSTabView!
    @IBOutlet weak var dividerPlaceholderView: NSView!
    @IBOutlet weak var popoverView: NSView!
    @IBOutlet weak var popoverTxt: NSTextField!
    @IBOutlet weak var tipsSuppressionBtn: NSButton!
    @IBOutlet weak var progressLabel: NSTextField!
    // preferences controls
    @IBOutlet weak var btn_alwaysOnTop: NSButton!
    @IBOutlet weak var btn_displaytips: NSButton!
    @IBOutlet weak var popup_format: NSPopUpButton!
    // tb items
    @IBOutlet weak var tb_upscale: NSToolbarItem!
    @IBOutlet weak var tb_clear: NSToolbarItem!
    @IBOutlet weak var tb_save: NSToolbarItem!
    @IBOutlet weak var tb_import: NSToolbarItem!
    @IBOutlet weak var tb_popupscale: NSToolbarItem!
    @IBOutlet weak var tb_popupmodel: NSToolbarItem!
    // tb buttons
    @IBOutlet weak var saveBtn: NSButton!
    @IBOutlet weak var upscaleBtn: NSButton!
    @IBOutlet weak var clearBtn: NSButton!
    @IBOutlet weak var importBtn: NSButton!
    @IBOutlet weak var popupmodel: NSPopUpButton!
    @IBOutlet weak var popupscale: NSPopUpButton!
    @IBOutlet weak var ttaBtn: NSButton!
    
    @IBOutlet weak var view_batch: NSView!
    
    
    
    // VARS
    
    var inputpath : String? = nil
    var originalsize : NSSize? = nil
    
    // USER DEFAULTS KEYS
    
    let tipsKey = "doNotDisplayTips"
    let welcomeKey = "freeScalerWelcomeWindowHasBeenDisplayed"
    let key_ontop = "keepWindowIsAlwaysOnTop"
    let formatpopupkey = "formatpopupkey"
    let lastselectedmodel = "lastSelectedAIModel"
    
    
    // TIPS POPOVER
    
    let popover = NSPopover()
    
    
    // SPLIT VIEW DELEGATE
    
    func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool {return true}
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {return true}
    
    
    
}




