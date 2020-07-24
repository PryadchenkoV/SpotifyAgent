//
//  VisualEffectViewWithRoundCorners.swift
//  SpotifyAgent
//
//  Created by Work on 23/07/2020.
//  Copyright © 2020 Work. All rights reserved.
//

import Cocoa

class VisualEffectViewWithRoundCorners: NSVisualEffectView {
    
    @IBInspectable var cornerRadius: Double = 10
    
    override func awakeFromNib() {
        super.awakeFromNib()
        wantsLayer = true
        layer?.cornerRadius = CGFloat(cornerRadius)
        layer?.masksToBounds = true
    }
    
}
