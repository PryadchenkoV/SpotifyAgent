//
//  SongModel.swift
//  SpotifyAgent
//
//  Created by Work on 29/07/2020.
//  Copyright © 2020 Work. All rights reserved.
//

import Foundation
import os.log

class SongModel: NSObject {
    
    private let songToStoreInHistory = 10
    private let kUserDefaultSongHistoryKey = "SongHistoryArray"
    private let kUserDefaultCurrentSong = "CurrentPlayedSong"
    private let kUserDefaultLastLyrics = "LastPlayedLyrics"
    static var shared: SongModel = SongModel()
    
    @objc dynamic var lastPlayedLyrics: LastPlayedLyrics? {
        didSet {
            DispatchQueue.global(qos: .utility).async { [weak self] in
                guard let self = self else {
                    os_log(.error, "Self is nil")
                    return
                }
                guard let lastPlayedLyrics = self.lastPlayedLyrics else {
                    os_log("Current song is nil")
                    return
                }
                do {
                    let savedData = try NSKeyedArchiver.archivedData(withRootObject: lastPlayedLyrics, requiringSecureCoding: false)
                    UserDefaults.standard.set(savedData, forKey: self.kUserDefaultLastLyrics)
                } catch {
                    os_log(.error, "Cannot archive data from last Played Lyrics")
                }
            }
        }
    }
    
    @objc dynamic var currentPlayingSong: Song? {
        didSet {
            DispatchQueue.global(qos: .utility).async { [weak self] in
                guard let self = self else {
                    os_log(.error, "Self is nil")
                    return
                }
                guard let currentSong = self.currentPlayingSong else {
                    os_log("Current song is nil")
                    return
                }
                do {
                    let savedData = try NSKeyedArchiver.archivedData(withRootObject: currentSong, requiringSecureCoding: false)
                    UserDefaults.standard.set(savedData, forKey: self.kUserDefaultCurrentSong)
                } catch {
                    os_log(.error, "Cannot archive data from current Song")
                }
            }
        }
    }
    
    private override init() {
        if let savedData = UserDefaults.standard.object(forKey: kUserDefaultSongHistoryKey) as? Data, let savedHistory = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(savedData) as? [Song] {
            historySongs = savedHistory
        }
        if let savedData = UserDefaults.standard.object(forKey: kUserDefaultLastLyrics) as? Data, let savedLastLyrics = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(savedData) as? LastPlayedLyrics {
            lastPlayedLyrics = savedLastLyrics
        }
    }
    
    @objc dynamic private var historySongs = [Song]() {
        didSet {
            if self.historySongs.count > songToStoreInHistory {
                self.historySongs.removeLast()
            }
        }
    }
    
    func setCurrentPlayingSong(_ song: Song) {
        if let currentPlayingSong = currentPlayingSong, currentPlayingSong == song {
            os_log("Song and current Song are equal, skip")
            return
        }
        willChangeValue(forKey: "currentPlayingSong")
        currentPlayingSong = song
        didChangeValue(forKey: "currentPlayingSong")
    }
    
    func addSongToHistory(song: Song) {
        song.isLastSongPlayedSong = true
        if historySongs.count > 0 {
            historySongs[0].isLastSongPlayedSong = false
        }
        willChangeValue(forKey: "historySongs")
        historySongs.insert(song, at: 0)
        didChangeValue(forKey: "historySongs")
        
        saveToUserDefaults()
    }
    
    func clearHistory() {
        willChangeValue(forKey: "historySongs")
        historySongs.removeAll()
        didChangeValue(forKey: "historySongs")
        
        saveToUserDefaults()
    }
    
    private func saveToUserDefaults() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else {
                os_log(.error, "Self is nil")
                return
            }
            do {
                let savedData = try NSKeyedArchiver.archivedData(withRootObject: self.historySongs, requiringSecureCoding: false)
                UserDefaults.standard.set(savedData, forKey: self.kUserDefaultSongHistoryKey)
            } catch {
                os_log(.error, "Cannot archive data from historySongs")
            }
        }
    }
    
    @objc dynamic func getSongHistory() -> [Song] {
        return historySongs
    }
}
