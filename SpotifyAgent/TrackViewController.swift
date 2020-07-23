//
//  ViewController.swift
//  SpotifyAgent
//
//  Created by Work on 16/07/2020.
//  Copyright © 2020 Work. All rights reserved.
//

import Cocoa
import AVFoundation

class TrackViewController: NSViewController {
    
    @IBOutlet var popoverMenu: NSMenu!
    
    @objc dynamic var isTrackPaused = true
    @objc dynamic var isApplicationRunning = false
    @objc dynamic var isApplicationLaunching = false
    @objc dynamic var isImageLoading = false
    @objc dynamic var image: NSImage?
    private var previousImageAddress: String?
    
    var timerRenewInformation: Timer?
    var timerApplicationRunning: Timer?
    
    var observer: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        renewApplicationState()
        
        timerApplicationRunning = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { [weak self] (_) in
            self?.renewApplicationState()
        })
        
        timerRenewInformation = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { [weak self] (_) in
            guard let self = self else {
                print("Self is nil")
                return
            }
            self.renewApplicationState()
            if self.isApplicationRunning {
                self.renewInformation()
            }
        })
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        renewApplicationState()
        if isApplicationRunning {
            startMonitoringApplication()
        } else {
            timerApplicationRunning?.fire()
        }
        observer = self.observe(\.isApplicationRunning, changeHandler: { [weak self] (_, _) in
            guard let self = self else {
                return
            }
            if self.isApplicationRunning {
                self.isApplicationLaunching = false
            }
        })
        isImageLoading = true
    }
    
    deinit {
        observer?.invalidate()
    }
    
    func startMonitoringApplication() {
        timerRenewInformation?.fire()
        
        getPlayButtonState()
        renewInformation()
    }
    
    func getPlayButtonState() {
        runAppleScript(withName: getPlayerStatus) { [weak self] (result) in
            self?.isTrackPaused = !result.booleanValue
        }
    }
    
    func renewApplicationState() {
        runAppleScript(withName: getApplicationRunning) { [weak self] (result) in
            self?.isApplicationRunning = result.booleanValue
        }
    }
    
    func renewInformation() {
        runAppleScript(withName: getTrackScript) { [weak self] (result) in
            guard let self = self else {
                print("Self is nil")
                return
            }
            var spotifyInfo = [String : Any]()
            if result.numberOfItems > 0 {
                for (index, item) in spotifyKeys.enumerated() {
                    spotifyInfo[item] = result.atIndex(index + 1)?.stringValue
                }
            }
            DispatchQueue.main.async {
                self.representedObject = spotifyInfo.count > 0 ? spotifyInfo : nil
            }
        }
    }
    
    override var representedObject: Any? {
        didSet {
            guard let representedObject = self.representedObject as? [String: Any], let urlString = representedObject["artwork"] as? String, let url = URL(string: urlString), (previousImageAddress == nil || previousImageAddress != urlString) else {
                isImageLoading = false
                return
            }
            previousImageAddress = urlString
            URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
                if let error = error {
                    print("Error \(error.localizedDescription)")
                    return
                }
                guard let data = data else {
                    print("Data is nil")
                    return
                }
                let image = NSImage(data: data)
                DispatchQueue.main.async {
                    self?.image = image
                    self?.isImageLoading = false
                }
            }.resume()
            
        }
    }
    
    func runAppleScript(withName scriptName: String, successBlock: ((NSAppleEventDescriptor) -> Void)?) {
        if let script = NSAppleScript(source: scriptName) {
            var error: NSDictionary?
            let result = script.executeAndReturnError(&error)
            if let err = error {
                print(err)
            } else {
                successBlock?(result)
            }
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func playPauseButtonClicked(_ sender: Any) {
        
        runAppleScript(withName: tellToPlayPause) { [weak self] _ in
            if self?.representedObject == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self?.renewInformation()
                }
            }
            self?.isTrackPaused.toggle()
        }
    }
    
    @IBAction func nextButtonClicked(_ sender: Any) {
        runAppleScript(withName: tellToPlayNext) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self?.renewInformation()
            }
        }
    }
    
    @IBAction func previousButtonClicked(_ sender: Any) {
        runAppleScript(withName: tellToPlayPrevious) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self?.renewInformation()
            }
        }
    }
    
    @IBAction func runApplicationButtonPushed(_ sender: Any) {
        isApplicationLaunching = true
        DispatchQueue.global(qos: .default).async { [weak self] in
            self?.runAppleScript(withName: runApplication, successBlock: nil)
        }
    }
    
    @IBAction func buttonForDropDownMenuPushed(_ sender: NSButton) {
        if let event = NSApplication.shared.currentEvent {
            NSMenu.popUpContextMenu(sender.menu!, with: event, for: sender)
        }
    }
}

extension TrackViewController {
  // MARK: Storyboard instantiation
  static func freshController() -> TrackViewController {
    let storyboard = NSStoryboard(name: "Main", bundle: nil)
    guard let viewController = storyboard.instantiateController(withIdentifier: "TrackViewController") as? TrackViewController else {
      fatalError("Check Main.storyboard")
    }
    return viewController
  }
}

