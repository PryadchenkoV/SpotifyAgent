//
//  ViewController.swift
//  SpotifyAgent
//
//  Created by Work on 16/07/2020.
//  Copyright © 2020 Work. All rights reserved.
//

import Cocoa
import os.log

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
let kNeedRefreshNotificationName = Notification.Name.init(rawValue: "NeedRefreshNotification")

class TrackViewController: NSViewController {
    
    @IBOutlet var popoverMenu: NSMenu!
    @IBOutlet weak var viewToPlacePopover: NSView!
    
    @objc dynamic var isTrackPaused = true
    @objc dynamic var isApplicationInstalled = false
    @objc dynamic var isApplicationRunning = false
    @objc dynamic var isApplicationLaunching = false
    @objc dynamic var isHistoryShown = false
    
    let songModel = SongModel.shared
    
    var timerApplicationInstalled: Timer?
    var timerRenewInformation: Timer?
    var timerApplicationRunning: Timer?
    
    var observer: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        renewAppInstalled()
        if isApplicationInstalled {
            renewApplicationState()
        }
        
        NotificationCenter.default.addObserver(forName: kNeedRefreshNotificationName, object: nil, queue: .main) { [weak self] (_) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.renewInformation()
            }
        }
        
        timerApplicationInstalled = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { [weak self] (timer) in
            guard let self = self else {
                os_log("Self is nil, return")
                return
            }
            self.renewAppInstalled()
            if self.isApplicationInstalled {
                timer.invalidate()
                self.startMonitoringApplicationOnAppInstalled()
            }
        })
        
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
        
        renewAppInstalled()
        if isApplicationInstalled {
            startMonitoringApplicationOnAppInstalled()
        } else {
            timerApplicationInstalled?.fire()
        }
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        isHistoryShown = false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        observer?.invalidate()
    }
    
    func startMonitoringApplicationOnAppInstalled() {
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
    
    func renewAppInstalled() {
        runAppleScript(withName: getSpotifyInstalled) { [weak self] (result) in
            self?.willChangeValue(forKey: "isApplicationInstalled")
            self?.isApplicationInstalled = result.booleanValue
            self?.didChangeValue(forKey: "isApplicationInstalled")
        }
    }
    
    func renewInformation() {
        runAppleScript(withName: getTrackScript) { [weak self] (result) in
            guard let self = self else {
                print("Self is nil")
                return
            }
            var spotifyInfo = [String : String]()
            var song: Song?
            if result.numberOfItems > 0 {
                for (index, item) in spotifyKeys.enumerated() {
                    spotifyInfo[item] = result.atIndex(index + 1)?.stringValue
                }
                guard let name = spotifyInfo["name"], let artist = spotifyInfo["artist"], let artworkURL = spotifyInfo["artwork"], let songURL = spotifyInfo["songURL"] else {
                    os_log(.error, "Some of components is nil")
                    return
                }
                song = Song(name: name, artist: artist, artworkURL: artworkURL, songURL: songURL)
            }
            DispatchQueue.main.async {
                if self.representedObject == nil || song == nil {
                    self.representedObject = song
                } else if let representedObject = self.representedObject as? Song, let songNotNil = song, representedObject != songNotNil {
                    self.representedObject = song
                    self.songModel.addSongToHistory(song: representedObject)
                }
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
                self?.getPlayButtonState()
            }
        }
    }
    
    @IBAction func previousButtonClicked(_ sender: Any) {
        runAppleScript(withName: tellToPlayPrevious) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self?.renewInformation()
                self?.getPlayButtonState()
            }
        }
    }
    
    @IBAction func runApplicationButtonPushed(_ sender: Any) {
        isApplicationLaunching = true
        DispatchQueue.global(qos: .default).async {
            runAppleScript(withName: runApplication, successBlock: nil)
        }
    }
    
    @IBAction func buttonForDropDownMenuPushed(_ sender: NSButton) {
        if let event = NSApplication.shared.currentEvent {
            NSMenu.popUpContextMenu(sender.menu!, with: event, for: sender)
        }
    }
    
    @IBAction func nameOrAuthorPushed(_ sender: Any) {
        guard let song = representedObject as? Song else {
            os_log("Represented Object is bad", log: .default, type: .fault)
            return
        }
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("\(song.name) - \(song.artist)", forType: .string)
        
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        guard let viewController = storyboard.instantiateController(withIdentifier: "CopiedPopover") as? NSViewController else {
            os_log("Copied popover view controller is nil", log: .default, type: .fault)
            return
        }
        viewController.representedObject = ["title": NSLocalizedString("Copied", comment: "Copy label")]

        let popoverCopied = NSPopover()
        popoverCopied.behavior = .semitransient
        popoverCopied.contentViewController = viewController
        popoverCopied.show(relativeTo: .zero, of: viewToPlacePopover, preferredEdge: .maxX)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if popoverCopied.isShown {
                popoverCopied.close()
            }
        }
    }
    @IBAction func showHistoryPushed(_ sender: Any) {
        isHistoryShown.toggle()
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

