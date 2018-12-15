//
//  spiritMeterController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-12-05.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit
import Firebase

class spiritMeterController: UIViewController {
    
    @IBOutlet weak var nineLabel: UILabel!
    @IBOutlet weak var tenLabel: UILabel!
    @IBOutlet weak var elevenLabel: UILabel!
    @IBOutlet weak var twelveLabel: UILabel!
    
    //The Database
    var db: Firestore!
    var docRef: DocumentReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //***************INTERNET CONNECTION**************
        var iAmConneted = false
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if let connected = snapshot.value as? Bool, connected {
                print("Connected")
                iAmConneted = true
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0){
                    print(iAmConneted)
                    if !iAmConneted{
                        print("Not connected")
                        let alert = UIAlertController(title: "Error", message: "You are not connected to the internet", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        })
        
        //Set Up
        // [START setup]
        let settings = FirestoreSettings()
        settings.areTimestampsInSnapshotsEnabled = true
        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
        //Get the points
        getSpiritPoints()
    }
    
    func getSpiritPoints() {
        db.collection("info").document("spiritPoints").getDocument { (snapshot, err) in
            if let err = err {
                let alert = UIAlertController(title: "Unable to get spirit data", message: "Error: \(err.localizedDescription)", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            }
            if let snapshot = snapshot {
                let data = snapshot.data()
                
                self.nineLabel.text = "Nine: \(data?["nine"] ?? "error")"
                self.tenLabel.text = "Ten: \(data?["ten"] ?? "error")"
                self.elevenLabel.text = "Eleven: \(data?["eleven"] ?? "error")"
                self.twelveLabel.text = "Twelve: \(data?["twelve"] ?? "error")"
            }
        }
    }
}
