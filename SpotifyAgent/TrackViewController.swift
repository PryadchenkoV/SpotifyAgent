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
    @IBOutlet weak var historyViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var historyView: NSView!
    @IBOutlet weak var lyricsView: NSView!
    @IBOutlet weak var lyricsViewWidthConstraint: NSLayoutConstraint!
    
    @objc dynamic var isTrackPaused = true
    @objc dynamic var isApplicationInstalled = false
    @objc dynamic var isApplicationRunning = false
    @objc dynamic var isApplicationLaunching = false
    @objc dynamic var isHistoryShown = false
    @objc dynamic var isLyricsShown = false
    
    @objc dynamic var artworkImage: NSImage?
    
    let songModel = SongModel.shared
    private let historyViewWidth: CGFloat = 150
    private let lyricsViewWidth: CGFloat = 250
    
    private var lyricsViewController: LyricsViewController?
    
    var timerApplicationInstalled: Timer?
    var timerRenewInformation: Timer?
    var timerApplicationRunning: Timer?
    
    var observer: NSKeyValueObservation?
    var imageObserver: NSKeyValueObservation?
    var lyricsObserver: NSKeyValueObservation?
    
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
                os_log("Self is nil")
                return
            }
            self.renewApplicationState()
            if self.isApplicationRunning {
                self.renewInformation()
            }
        })
        
        historyViewWidthConstraint.constant = 0
        historyView.isHidden = !isHistoryShown
        
        lyricsViewWidthConstraint.constant = 0
        lyricsView.isHidden = !isLyricsShown
        
        NSApp.mainWindow?.initialFirstResponder = viewToPlacePopover
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
    
    override func viewDidAppear() {
        super.viewDidAppear()
        NSApp.mainWindow?.makeFirstResponder(viewToPlacePopover)
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        isHistoryShown = false
        isLyricsShown = false
        historyViewWidthConstraint.constant = 0
        lyricsViewWidthConstraint.constant = 0
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        observer?.invalidate()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "LyricsViewControllerSegue" {
            lyricsViewController = segue.destinationController as? LyricsViewController
        }
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
                
                if let lastPlayedLyrics = self.songModel.lastPlayedLyrics, lastPlayedLyrics.songURL == songURL {
                    song = Song(name: name, artist: artist, artworkURL: artworkURL, songURL: songURL, lyrics: lastPlayedLyrics.lyrics)
                } else {
                    song = Song(name: name, artist: artist, artworkURL: artworkURL, songURL: songURL)
                }
            }
            DispatchQueue.main.async {
                if self.representedObject == nil || song == nil {
                    if let song = song {
                        self.imageObserver = song.observe(\.isImageLoading, changeHandler: { [weak self] (song, _) in
                            if !song.isImageLoading {
                                self?.artworkImage = song.artwork
                                SongModel.shared.currentPlayingSong = song
                                self?.imageObserver?.invalidate()
                            }
                        })
                        if song.lyrics?.count == 0 || song.lyrics == nil {
                            self.lyricsObserver = song.observe(\.isLyricsLoading, changeHandler: { [weak self] (song, _) in
                                if !song.isLyricsLoading {
                                    self?.lyricsViewController?.lyrics = song.lyrics
                                    SongModel.shared.currentPlayingSong = song
                                    if song.lyrics != nil {
                                        self?.lyricsObserver?.invalidate()
                                    }
                                }
                            })
                        } else {
                            self.lyricsViewController?.lyrics = song.lyrics
                        }
                    }
                    self.representedObject = song
                } else if let representedObject = self.representedObject as? Song, let songNotNil = song, representedObject != songNotNil {
                    self.representedObject = song
                    self.imageObserver = song?.observe(\.isImageLoading, changeHandler: { [weak self] (song, _) in
                        if !song.isImageLoading {
                            self?.artworkImage = song.artwork
                            self?.imageObserver?.invalidate()
                        }
                    })
                    if song?.lyrics?.count == 0 || song?.lyrics == nil {
                        self.lyricsObserver = song?.observe(\.isLyricsLoading, changeHandler: { [weak self] (song, _) in
                            if !song.isLyricsLoading {
                                self?.lyricsViewController?.lyrics = song.lyrics
                                if let lyrics = song.lyrics {
                                    SongModel.shared.lastPlayedLyrics = LastPlayedLyrics(withLyrics: lyrics, forSongURL: song.songURL)
                                    self?.lyricsObserver?.invalidate()
                                }
                            }
                        })
                    } else {
                        self.lyricsViewController?.lyrics = song?.lyrics
                    }
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
        
        var copyText = "\(song.name) - \(song.artist)"
        let componentsOfURL = song.songURL.split(separator: ":")
        if let trackID = componentsOfURL.last {
            let songURL = "https://open.spotify.com/track/\(trackID)"
            copyText += " \(songURL)"
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(copyText, forType: .string)
        
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
        if isLyricsShown {
            isLyricsShown.toggle()
            NSAnimationContext.runAnimationGroup({ (context) in
                context.duration = 0.2
                lyricsViewWidthConstraint.animator().constant = isLyricsShown ? self.lyricsViewWidth : 0.0
            }) {
                self.lyricsView.isHidden = !self.isLyricsShown
                self.showHistoryPushed(sender)
            }
        } else {
            
            if !isHistoryShown {
                historyView.isHidden = false
                historyViewWidthConstraint.constant = 0
            }
            isHistoryShown.toggle()
            NSAnimationContext.runAnimationGroup({ (context) in
                context.duration = 0.3
                historyViewWidthConstraint.animator().constant = isHistoryShown ? self.historyViewWidth : 0.0
            }) {
                self.historyView.isHidden = !self.isHistoryShown
            }
        }
    }
    
    @IBAction func showLyricsPushed(_ sender: Any) {
        
        if isHistoryShown {
            isHistoryShown.toggle()
            NSAnimationContext.runAnimationGroup({ (context) in
                context.duration = 0.2
                historyViewWidthConstraint.animator().constant = isHistoryShown ? self.historyViewWidth : 0.0
            }) {
                self.historyView.isHidden = !self.isHistoryShown
                self.showLyricsPushed(sender)
            }
        } else {
            if !isLyricsShown {
                lyricsView.isHidden = false
                lyricsViewWidthConstraint.constant = 0
                lyricsViewController?.representedObject = self.representedObject
            }
            isLyricsShown.toggle()
            NSAnimationContext.runAnimationGroup({ (context) in
                context.duration = 0.3
                lyricsViewWidthConstraint.animator().constant = isLyricsShown ? self.lyricsViewWidth : 0.0
            }) {
                self.lyricsView.isHidden = !self.isLyricsShown
            }
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

