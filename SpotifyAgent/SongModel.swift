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
    static var shared: SongModel = SongModel()
    
    private override init() {
        if let savedData = UserDefaults.standard.object(forKey: kUserDefaultSongHistoryKey) as? Data, let savedHistory = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(savedData) as? [Song] {
            historySongs = savedHistory
        }
    }
    
    @objc dynamic private var historySongs = [Song]() {
        didSet {
            if self.historySongs.count > songToStoreInHistory {
                self.historySongs.removeLast()
            }
        }
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
