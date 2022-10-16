//
//  Upscaler.swift
//  FreeScaler
//
//  Created by Hany El Imam on 10/10/22.
//

import Foundation
import Cocoa

// MARK: UPSCALER

var fileformat = "png" // output image format (jpg/png/webp, default=ext/png)
let bundlepath = Bundle.main.bundlePath
let resourcepath = Bundle.main.resourcePath
let temporaryoutputpath = NSTemporaryDirectory() + "freescaler-output." + fileformat
var upscalername = String() // current upscaler binary name (used for kill command)




// MARK: UPSCALE SINGLE IMAGE

// output image is saved to a temporary directory inside app's sandbox

func upscale(upscaler:String,
             input:String,
             model:String,
             scale:Int,
             tta:Bool) {
    
    upscalername = upscaler
    
    let task = Process()
    task.currentDirectoryURL = Bundle.main.resourceURL
    task.executableURL = Bundle.main.resourceURL
    task.launchPath = "\(resourcepath!)/\(upscaler)"    // upscaler binary exe
    
    // args
    task.arguments = ["-i",input,                       // input path
                      "-o",temporaryoutputpath,         // output path
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
                updateProgress(string: string)
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
        // task finished, display resulting output image
        (NSApplication.shared.delegate as! AppDelegate).displayresult()
    }
    task.launch()
    
}





// MARK: DETERMINATE PROGRESS INDICATOR

extension Int {
    static func parse(from string: String) -> Int? {
        return Int(string.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())
    }
}

// update progress indicator with data from standardError
func updateProgress(string:String) {
    if let number = Int.parse(from: string) {
        if number > 100 {
            (NSApplication.shared.delegate as! AppDelegate).progress.doubleValue = Double(number)
            (NSApplication.shared.delegate as! AppDelegate).progress.isHidden = false
            (NSApplication.shared.delegate as! AppDelegate).iprogress.isHidden = true
        }
        if number > 8500 {
            (NSApplication.shared.delegate as! AppDelegate).iprogress.isHidden = false
            (NSApplication.shared.delegate as! AppDelegate).progress.isHidden = true
            (NSApplication.shared.delegate as! AppDelegate).progressLabel.stringValue = "Please wait..."
        }
    }
}





// MARK: KILL UPSCALE PROCESS

func stopUpscalerProcess() {
    autoreleasepool {
        let shell: Process = Process()
        let outpipe : Pipe = Pipe()
        var filehandle : FileHandle = FileHandle()
        shell.launchPath = "/usr/bin/killall" as String
        shell.arguments = [upscalername]
        shell.standardOutput = outpipe;shell.standardError = outpipe
        shell.launch();shell.waitUntilExit();shell.terminate()
        filehandle.closeFile();filehandle = outpipe.fileHandleForReading
    }
}
