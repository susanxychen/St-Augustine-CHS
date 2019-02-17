//
//  checkRemoteConfigController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2019-02-03.
//  Copyright © 2019 St Augustine CHS. All rights reserved.
//

import UIKit

class checkRemoteConfigController: UIViewController {

    @IBOutlet weak var dataTextArea: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Quick Debug Output all RC Values
        var allData:String = "Starting Points " + String(Defaults.startingPoints) + " Attending Event: " + String(Defaults.attendingEvent)
        allData += "\nJoining Club: " + String(Defaults.joiningClub) + " Max Songs: " + String(Defaults.maxSongs) + " Request Song: " + String(Defaults.requestSong)
        allData += "\nPic Costs: "
        for cost in Defaults.picCosts {
            allData += String(cost) + " "
        }
        allData += "\nSupervote Min: " + String(Defaults.supervoteMin) + " Supervote Ratio " + String(Double(Defaults.supervoteRatio))
        allData += "\nSong Theme: " + Defaults.songRequestTheme
        dataTextArea.text = allData
    }
    
}
