//
//  SpotifyScripts.swift
//  SpotifyAgent
//
//  Created by Work on 22/07/2020.
//  Copyright © 2020 Work. All rights reserved.
//

import Foundation

let spotifyKeys = ["name", "artist", "artwork", "songURL"]

let getSpotifyInstalled = """
    try
        tell application "Finder" to get application file id "com.spotify.client"
        set appExists to true
    on error
        set appExists to false
    end try
"""

let getApplicationRunning = """
    if application "Spotify" is running then
        return true
    else
        return false
    end if
"""

let runApplication = """
    tell application "Spotify"
       activate
    end tell
"""

let getPlayerStatus = """
    tell application "Spotify"
        if player state is playing then
            return true
        else
            return false
        end if
    end tell
"""

let getTrackScript = """
      tell application "Spotify"
        set c to the current track
        return { name:name of c, artist:artist of c, artwork:artwork url of c, url:spotify url of c }
      end tell
"""

let tellToPlayPause = """
    tell application "Spotify" to playpause
"""

let tellToPlayNext = """
    tell application "Spotify" to next track
"""

let tellToPlayPrevious = """
    tell application "Spotify" to previous track
"""

func tellToPlaySong(with url: String) -> String {
    return """
    tell application "Spotify" to play track "\(url)"
"""
}
