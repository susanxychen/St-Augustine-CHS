//
//  SignInPrefController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-11-17.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit
import Firebase

class SignInPrefController: UIViewController {

    @IBOutlet weak var nextButtonHidden: UIButton!
    
    //User Details
    var picChosen: Int!
    var courses: [String]!
    var showCourses = false
    var showClubs = false
    
    //Database Variables
    var db: Firestore!
    var docRef: DocumentReference!
    
    //Preferences
    @IBOutlet weak var showCoursesSwitch: UISwitch!
    @IBOutlet weak var showClassesSwitch: UISwitch!
    
    //Colours
    @IBOutlet weak var statusBarView: UIView!
    @IBOutlet weak var topBarView: UIView!
    
    @IBOutlet weak var privacyPolicyButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set Up
        // [START setup]
        let settings = FirestoreSettings()
        settings.areTimestampsInSnapshotsEnabled = true
        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
        statusBarView.backgroundColor = Defaults.darkerPrimary
        topBarView.backgroundColor = Defaults.primaryColor
        
        print(picChosen)
        print(courses)
        
    }
    
    @IBAction func switchTapped(_ sender: UISwitch) {
        if sender == showCoursesSwitch {
            if sender.isOn {
                print("yeah wanna show courses")
                showCourses = true
            } else {
                print("no dont wanna show courses")
                showCourses = false
            }
        } else {
            if sender.isOn {
                print("yeah wanna show clubs")
                showClubs = true
            } else {
                print("no dont wanna show club")
                showClubs = false
            }
        }
    }
    
    @IBAction func pressedPrivacyPolicy(_ sender: Any) {
        if let url = URL(string: "https://app.staugustinechs.ca/privacy/") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }

    }
    
    
    @IBAction func pressedFinishedButton(_ sender: Any) {
        print("wow u finished sign in")
        
        Messaging.messaging().subscribe(toTopic: "general") { error in
            print("Subscribed to general topic")
        }
        
        Messaging.messaging().subscribe(toTopic: "alerts") { error in
            print("Subscribed to alerts topic")
        }
        
        //CREATE THE USER IN THE DATABASE WITH GIVEN PREFERENCES
        print(picChosen)
        print(courses)
        print(showCourses)
        
        let user = Auth.auth().currentUser
        
        //To get grad year, get the XX@ycdsbk12.ca suffix. Then get the prefix XX of that suffix.
        //Parse it as a string and finally to Int
        let possibleGradYear = String((user?.email?.suffix(14).prefix(2))!)
        var gradYear = Int(possibleGradYear)
        
        var status = 0
        
        //If u cant cast to int then it means ur a teacher
        if gradYear == nil {
            status = 1
            gradYear = 0
        }
        
        db.collection("users").document((user?.uid)!).setData([
            "badges": [],
            "classes": courses,
            "clubs": [],
            "email": user?.email as Any,
            "gradYear": gradYear!,
            "name": user?.displayName as Any,
            "notifications": ["general"],
            "picsOwned": [picChosen],
            "points": Defaults.startingPoints,
            "profilePic": picChosen,
            "showClasses": showCourses,
            "showClubs": showClubs,
            "status": status
        ]) { err in
            if let err = err {
                print("Error writing document: \(err)")
                let alert = UIAlertController(title: "There was an error creating you in the database...well isnt that awkward", message: "Error: \(err.localizedDescription)", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            } else {
                print("Document successfully written!")
                self.performSegue(withIdentifier: "doneSeg", sender: self.nextButtonHidden)
                UserDefaults.standard.set(true, forKey: "didSignInBefore")
            }
        }
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        let nav = segue.destination as! UINavigationController
//        let vc = nav.topViewController as! menuController
//        vc.cameFromSignUpFlow = true
//    }
}
