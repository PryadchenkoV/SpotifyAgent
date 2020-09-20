//
//  HistoryViewController.swift
//  SpotifyAgent
//
//  Created by Work on 20/09/2020.
//  Copyright © 2020 Work. All rights reserved.
//

import Cocoa

class HistoryViewController: NSViewController, NSTableViewDelegate {

    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet weak var tableView: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.target = self
        tableView.doubleAction = #selector(tableViewDoubleClick(_:))
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
    }
    
    @IBAction func tableViewDoubleClick(_ sender: AnyObject) {
        guard tableView.selectedRow >= 0,
            let arrangedObjects = arrayController.arrangedObjects as? [Song] else {
          return
        }
        let selectedSong = arrangedObjects[tableView.selectedRow]
        runAppleScript(withName: tellToPlaySong(with: selectedSong.songURL), successBlock: { (_) in
            NotificationCenter.default.post(name: kNeedRefreshNotificationName, object: nil)
        })
        
    }
}
