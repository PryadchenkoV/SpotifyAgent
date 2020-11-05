//
//  LyricsViewController.swift
//  SpotifyAgent
//
//  Created by Work on 02/11/2020.
//  Copyright © 2020 Work. All rights reserved.
//

import Cocoa

class LyricsViewController: NSViewController {

    @IBOutlet var lyricsTextView: NSTextView!
    private var isObserverAdded: Bool = false
    private var isRepresentedObjectChanged: Bool = false
    @objc dynamic var lyrics: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lyricsTextView.alignment = .center
        lyricsTextView.isEditable = false
        
//        guard let representedObject = self.representedObject as? Song, representedObject.lyrics != nil else {
//            isObserverAdded = true
//            addObserver(self, forKeyPath: "representedObject.lyrics", options: [], context: nil)
//            return
//        }
//        lyrics = representedObject.lyrics
        // Do view setup here.
    }
    
//    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//        if keyPath == "representedObject.lyrics" {
//            if let song = self.representedObject as? Song {
//                if let lyrics = song.lyrics {
//                    self.lyrics = lyrics
//                    isRepresentedObjectChanged = false
////                    isObserverAdded = false
////                    self.removeObserver(self, forKeyPath: "representedObject.lyrics")
//                } else {
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//                        if self.isRepresentedObjectChanged {
//                            self.lyrics = nil
//                        }
//                    }
//                }
//
//            }
//        } else {
//            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
//        }
//    }
//
//    deinit {
//        removeObserver(self, forKeyPath: "representedObject.lyrics")
//    }
//
//    override var representedObject: Any? {
//        didSet {
//            if let representedObject = self.representedObject as? Song, representedObject.lyrics != nil {
//                lyrics = representedObject.lyrics
//                isRepresentedObjectChanged = true
//            }
//        }
//    }
    
}
