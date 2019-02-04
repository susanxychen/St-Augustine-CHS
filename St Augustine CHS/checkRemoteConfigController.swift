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
        /*
         static var darkerPrimary:UIColor = UIColor(hex: "#460817")
         static var primaryColor:UIColor = UIColor(hex: "#8D1230")
         static var accentColor:UIColor = UIColor(hex: "#D8AF1C")
         static var statusTwoPrimary:UIColor = UIColor(hex: "#040405")
         
         static var joiningClub: Int = 300
         static var attendingEvent: Int = 100
         static var startingPoints: Int = 100
         
         static var picCosts: [Int] = [30,50,100,200,500]
         
         static var maxSongs: Int = 20
         static var requestSong: Int = 20
         static var supervoteMin: Int = 10
         static var supervoteRatio: CGFloat = 1.0
        */
        
        //Quick Debug Output all RC Values
        var allData:String = "Starting Points " + String(Defaults.startingPoints) + " Attending Event: " + String(Defaults.attendingEvent)
        allData += "\nJoining Club: " + String(Defaults.joiningClub) + " Max Songs: " + String(Defaults.maxSongs) + " Request Song: " + String(Defaults.requestSong)
        allData += "\nPic Costs: "
        for cost in Defaults.picCosts {
            allData += String(cost) + " "
        }
        allData += "\nSupervote Min: " + String(Defaults.supervoteMin) + " Supervote Ratio " + String(Double(Defaults.supervoteRatio))
        dataTextArea.text = allData
    }
    
}
