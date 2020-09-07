//
//  KataGoEngine.swift
//  Go
//
//  Created by Jae Seung Lee on 9/5/20.
//  Copyright © 2020 Jae Seung Lee. All rights reserved.
//

import Foundation
import AppKit

class KataGo {
    let model = "/Library/Frameworks/Python.framework/Versions/3.6/lib/python3.6/site-packages/katrain/models/g170e-b15c192-s1672170752-d466197061.bin.gz"
    let cfg = "/Library/Frameworks/Python.framework/Versions/3.6/lib/python3.6/site-packages/katrain/KataGo/analysis_config.cfg"
    let config_thread = "8"
    
    let task = Process()
    let inputPipe = Pipe()
    let outputPipe = Pipe()
    let errorPipe = Pipe()
    
    var progressObserver: NSObjectProtocol!
    var terminationObserver: NSObjectProtocol!
    
    var receivedString = String()
    
    var ready = false
    
    var delegate: EngineDelegate?

    init(with url: URL) {
        task.executableURL = url
        task.arguments = ["analysis",
                          "-model", model,
                          "-config", cfg,
                          "-analysis-threads", config_thread]
        
        task.standardInput = inputPipe
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        
        //print("\(task.executableURL)")
        /*
        progressObserver = NotificationCenter.default
            .addObserver(forName: .NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading, queue: nil) { notification -> Void in
                let data = self.outputPipe.fileHandleForReading.availableData
            
                if data.count > 0 {
                    print("\(data.count)")
                    if let str = String(data: data, encoding: String.Encoding.utf8) {
                        //print(str)
                        self.outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
                    }
                } else {
                    // That means we've reached the end of the input.
                    NotificationCenter.default.removeObserver(self.progressObserver!)
                }
        }
        */
        
        terminationObserver = NotificationCenter.default
            .addObserver(forName: Process.didTerminateNotification, object: task, queue: nil) { notification -> Void in
                print("terminationObserver: Process terminated \(self.task.terminationReason.rawValue)")
                self.outputPipe.fileHandleForReading.readabilityHandler = nil
                NotificationCenter.default.removeObserver(self.terminationObserver!)
        }
        
        //outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
    }
    
    func startEngine() {
        print("Starting KataGo")
        //var isDir = ObjCBool(false)
        //let exists = FileManager.default.fileExists(atPath: task.executableURL!.path, isDirectory: &isDir)
        //print("\(exists)")
        
        //print("\(task.arguments)")
        
        do {
            try task.run()
        } catch {
            print("Error while starting Katago: \(error)")
        }
        
        errorPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = self.errorPipe.fileHandleForReading.availableData
            //print("\(Date()) \(data.count)")
            if data.count > 0 {
                let received = String(data: data, encoding: String.Encoding.utf8)!
                //print("\(Date()) \(data.count)")
                print("\(received)")
                if received.contains("Started, ready to begin handling requests") {
                    self.ready = true
                }
            }
        }
        
        outputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = self.outputPipe.fileHandleForReading.availableData
            //print("\(Date()) \(data.count)")
            if data.count > 0 {
                let received = String(data: data, encoding: String.Encoding.utf8)!
                self.receivedString += received
                print("\(Date()) \(data.count)")
                print("\(received)")
                
                if (received.contains {$0.isNewline}) {
                    //print("Found a new line")
                    self.delegate?.read(result: self.receivedString)
                    self.receivedString = ""
                } else {
                    print("Not the end")
                }
            }
        }
        
        //outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        //inputPipe.fileHandleForWriting.waitForDataInBackgroundAndNotify()
        //print("\(task.standardInput)")
    }
    
    func process(query: String) {
        //DispatchQueue.global(qos: .userInitiated).async {
        //self.receivedString = ""
        self.inputPipe.fileHandleForWriting.write(query.data(using: .utf8)!)
        print("KataGo: query requested")
        //}
        
        /*
        while (true) {
            let data = outputPipe.fileHandleForReading.availableData
            print("\(data.count)")
            if data.count > 0 {
                print(String(data: data, encoding: String.Encoding.utf8)!)
            }
            
            if data.count < 4096 {
                break
            }
        }
        */
    }
    
    func stopEngine() {
        //print("\(receivedString)")
        print("Terminating KataGo")
        delegate = nil
        outputPipe.fileHandleForReading.readabilityHandler = nil
        task.terminate()
    }
}
