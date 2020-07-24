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

    var name: String
    var artist: String
    var artworkURL: String
    var artwork: NSImage?
    var songURL: String
    
    init(name: String, artist: String, artworkURL: String, songURL: String) {
        self.name = name
        self.artist = artist
        self.artworkURL = artworkURL
        self.songURL = songURL
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
            self?.artwork = image
        }.resume()
    }
}
