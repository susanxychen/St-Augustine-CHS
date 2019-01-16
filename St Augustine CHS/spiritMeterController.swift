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
    
    @IBOutlet weak var nineBar: UIProgressView!
    @IBOutlet weak var tenBar: UIProgressView!
    @IBOutlet weak var elevenBar: UIProgressView!
    @IBOutlet weak var twelveBar: UIProgressView!
    
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
        
        nineBar.tintColor = Defaults.accentColor
        tenBar.tintColor = Defaults.accentColor
        elevenBar.tintColor = Defaults.accentColor
        twelveBar.tintColor = Defaults.accentColor
        
        //Format the progress bars
        let transform = CGAffineTransform(scaleX: 1.0, y: 10.0)
        
        self.nineBar.transform = transform
        self.tenBar.transform = transform
        self.elevenBar.transform = transform
        self.twelveBar.transform = transform
        
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
                let data = snapshot.data()!
                
                //Set the values
                let nine = data["nine"] as! Double
                let ten = data["ten"] as! Double
                let eleven = data["eleven"] as! Double
                let twelve = data["twelve"] as! Double
                
                let points = [nine,ten,eleven,twelve]
                
                let max:Double = Double(points.max() ?? 1)
                
                self.nineBar.progress = Float(nine/max)
                self.tenBar.progress = Float(ten/max)
                self.elevenBar.progress = Float(eleven/max)
                self.twelveBar.progress = Float(twelve/max)
                
                //Update the labels
                self.nineLabel.text = "Grade 9 - \(data["nine"] ?? "error") Points"
                self.tenLabel.text = "Grade 10 - \(data["ten"] ?? "error") Points"
                self.elevenLabel.text = "Grade 11 - \(data["eleven"] ?? "error") Points"
                self.twelveLabel.text = "Grade 12 - \(data["twelve"] ?? "error") Points"
            }
        }
    }
}
