//
//  Song.swift
//  SpotifyAgent
//
//  Created by Work on 24/07/2020.
//  Copyright © 2020 Work. All rights reserved.
//

import Cocoa
import os.log

class Song: NSObject {

    @objc dynamic var name: String
    @objc dynamic var artist: String
    var artworkURL: String
    @objc dynamic var artwork: NSImage?
    @objc dynamic var isImageLoading = true
    @objc dynamic var isImageLoadingMoreThanTwoSeconds = false
    @objc dynamic var songURL: String
    @objc dynamic var isLastSongPlayedSong: Bool
    
    init(name: String, artist: String, artworkURL: String, songURL: String) {
        self.name = name
        self.artist = artist
        self.artworkURL = artworkURL
        self.songURL = songURL
        self.isLastSongPlayedSong = false
        super.init()
        self.downloadArtwork()
    }
    
    required init?(coder decoder: NSCoder)
    {
        guard let name = decoder.decodeObject(forKey: "name") as? String, let artist = decoder.decodeObject(forKey: "artist") as? String, let artworkURL = decoder.decodeObject(forKey: "artworkURL") as? String, let songURL = decoder.decodeObject(forKey: "songURL") as? String, let isLastSongPlayedSong = decoder.decodeBool(forKey: "isLastSongPlayedSong") as? Bool else {
            fatalError()
        }
        self.name = name
        self.artist = artist
        self.artworkURL = artworkURL
        self.songURL = songURL
        self.isLastSongPlayedSong = isLastSongPlayedSong
        super.init()
        self.downloadArtwork()
    }
    
    func downloadArtwork() {
        guard let url = URL(string: artworkURL) else {
            os_log("URL is nil", type: .error)
            return
        }
        URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            if let error = error {
                os_log("Error while downloading: ", type: .error, error.localizedDescription)
                return
            }
            guard let data = data else {
                os_log("Data is nil", type: .fault)
                return
            }
            let image = NSImage(data: data)
            DispatchQueue.main.async {
                self?.artwork = image
                self?.isImageLoading = false
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            if let isLoading = self?.isImageLoading, isLoading {
                self?.isImageLoadingMoreThanTwoSeconds = true
            }
        }
    }
    
    static func != (lhs: Song, rhs: Song) -> Bool {
        return lhs.artist != rhs.artist || lhs.name != rhs.name || lhs.songURL != rhs.songURL
    }
}

extension Song: NSCoding {
    func encode(with coder: NSCoder) {
        coder.encode(self.name, forKey: "name")
        coder.encode(self.artist, forKey: "artist")
        coder.encode(self.artworkURL, forKey: "artworkURL")
        coder.encode(self.isLastSongPlayedSong, forKey: "isLastSongPlayedSong")
        coder.encode(self.songURL, forKey: "songURL")
    }
    
    
}

//extension Song: Equatable {
//    static func == (lhs: Song, rhs: Song) -> Bool {
//        return lhs.artist == rhs.artist && lhs.name == rhs.name && lhs.songURL == rhs.songURL
//    }
//}
