//
//  updatePrivacyController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-12-18.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit
import Firebase

class updatePrivacyController: UIViewController {

    //Database Variables
    var db: Firestore!
    var docRef: DocumentReference!
    
    //Refresh Vars
    let actInd: UIActivityIndicatorView = UIActivityIndicatorView()
    let container: UIView = UIView()
    
    
    @IBOutlet weak var showCoursesSwitch: UISwitch!
    @IBOutlet weak var showClubsSwitch: UISwitch!
    
    //Colurs
    @IBOutlet weak var statusBarView: UIView!
    @IBOutlet weak var topBarView: UIView!
    
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
                        //self.updateButton.isEnabled = false
                    }
                }
            }
        })
        
        //Set Up Firebase
        // [START setup]
        let settings = FirestoreSettings()
        settings.areTimestampsInSnapshotsEnabled = true
        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
        statusBarView.backgroundColor = Defaults.darkerPrimary
        topBarView.backgroundColor = Defaults.primaryColor
        
        showClubsSwitch.setOn(allUserFirebaseData.data["showClubs"] as! Bool, animated: true)
        showCoursesSwitch.setOn(allUserFirebaseData.data["showClasses"] as! Bool, animated: true)
    }
    
    @IBAction func switchTapped(_ sender: UISwitch) {
        if sender == showCoursesSwitch {
            if sender.isOn {
                print("yeah wanna show courses")
                allUserFirebaseData.data["showClasses"] = true
            } else {
                print("no dont wanna show courses")
                allUserFirebaseData.data["showClasses"] = false
            }
        } else {
            if sender.isOn {
                print("yeah wanna show clubs")
                allUserFirebaseData.data["showClubs"] = true
            } else {
                print("no dont wanna show club")
                allUserFirebaseData.data["showClubs"] = false
            }
        }
    }
    
    @IBAction func cancelPrivacy(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func updatePrivacy(_ sender: Any) {
        showActivityIndicatory(container: self.container, actInd: self.actInd)
        
        //Update the picsOwned array
        let userRef = self.db.collection("users").document((Auth.auth().currentUser?.uid)!)
        //Subtact the points
        userRef.setData([
            "showClubs" : allUserFirebaseData.data["showClasses"] as Any,
            "showClasses" : allUserFirebaseData.data["showClubs"] as Any
        ], mergeFields: ["showClubs", "showClasses"]) { (err) in
            if let err = err {
                let alert = UIAlertController(title: "Error in updating profile picture", message: "Error: \(err.localizedDescription)", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
                self.hideActivityIndicator(container: self.container, actInd: self.actInd)
            } else {
                print("Document successfully updated")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                    self.hideActivityIndicator(container: self.container, actInd: self.actInd)
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
}
