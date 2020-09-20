//
//  ModelDataSource.swift
//  SpotifyAgent
//
//  Created by Work on 20/09/2020.
//  Copyright © 2020 Work. All rights reserved.
//

import Cocoa

class ModelDataSource: NSObject {

    @objc dynamic var songModel: SongModel {
        return SongModel.shared
    }
    
}
