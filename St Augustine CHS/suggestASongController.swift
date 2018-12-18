//
//  suggestASongController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-12-03.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit
import Firebase

class suggestASongController: UIViewController {

    @IBOutlet weak var therequestbutton: UIButton!
    @IBOutlet weak var songName: UITextField!
    @IBOutlet weak var artistName: UITextField!
    
    var db: Firestore!
    var docRef: DocumentReference!
    
    let actInd: UIActivityIndicatorView = UIActivityIndicatorView()
    let container: UIView = UIView()
    let overlayView = UIView(frame: UIScreen.main.bounds)
    
    //Allows refreshing the song req controller when done adding song
    var onDoneBlock : ((Bool) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
                        self.therequestbutton.isEnabled = false
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
        
        hideKeyboardWhenTappedAround()
    }
    
    //**********Dismiss**********
    @IBAction func cancelPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //**********Suggest the song**********
    @IBAction func suggestPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Confirmation", message: "Are you sure you want to spend 10 points to request a song? (You currently have \(allUserFirebaseData.data["points"] ?? "error occured") points)? Administration will be able to see who requested what song and have the power to bann those who request inappropriate or irrelevant content", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { (action:UIAlertAction) in
            print("You've pressed cancel");
        }
        
        let confirmAction = UIAlertAction(title: "Confirm", style: UIAlertAction.Style.default) { (action:UIAlertAction) in
            var iAmConneted = false
            let connectedRef = Database.database().reference(withPath: ".info/connected")
            connectedRef.observe(.value, with: { snapshot in
                if let connected = snapshot.value as? Bool, connected {
                    print("Connected")
                    iAmConneted = true
                    
                    let artist = self.artistName.text
                    let song = self.songName.text
                    let id = self.randomString(length: 20)
                    
                    var valid = true
                    
                    //Disallow empty strings
                    if artist == "" || song == "" {
                        valid = false
                        let alert = UIAlertController(title: "Error", message: "Fill in both artist name and song name", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                    }
                    
                    if valid {
                        self.showActivityIndicatory(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                        
                        let user = Auth.auth().currentUser
                        
                        //Take away your points and only upload the song if taken away points
                        self.db.collection("users").document((user?.uid)!).setData([
                            "points": (allUserFirebaseData.data["points"] as! Int) - 10
                        ], mergeFields: ["points"]) { (err) in
                            if let err = err {
                                print("Error writing document: \(err)")
                                let alert = UIAlertController(title: "Error in retrieveing songs", message: "Please Try Again later. Error: \(err.localizedDescription)", preferredStyle: .alert)
                                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                alert.addAction(okAction)
                                self.present(alert, animated: true, completion: nil)
                                self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                            }
                            
                            self.db.collection("users").document((user?.uid)!).getDocument { (docSnapshot, err) in
                                if let err = err {
                                    print("Error writing document: \(err)")
                                    let alert = UIAlertController(title: "Error in retrieveing users", message: "Please Try Again later. Error: \(err.localizedDescription)", preferredStyle: .alert)
                                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                    alert.addAction(okAction)
                                    self.present(alert, animated: true, completion: nil)
                                    self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                                }
                                
                                if let docSnapshot = docSnapshot {
                                    allUserFirebaseData.data = docSnapshot.data()!
                                    
                                    //Add the song
                                    self.db.collection("songs").document(id).setData([
                                        "artist": artist as Any,
                                        "date": Date(),
                                        "name": song as Any,
                                        "suggestor": Auth.auth().currentUser?.uid as Any,
                                        "upvotes": 0
                                    ]) { (err) in
                                        if let err = err {
                                            print("Error writing document: \(err)")
                                            let alert = UIAlertController(title: "Error in retrieveing songs", message: "Please Try Again later. Error: \(err.localizedDescription)", preferredStyle: .alert)
                                            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                            alert.addAction(okAction)
                                            self.present(alert, animated: true, completion: nil)
                                            self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                                        } else {
                                            print("Document successfully written!")
                                            self.onDoneBlock!(true)
                                            self.dismiss(animated: true, completion: nil)
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0){
                        print(iAmConneted)
                        if !iAmConneted{
                            print("Not connected")
                            let alert = UIAlertController(title: "Error", message: "You are not connected to the internet", preferredStyle: .alert)
                            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                            alert.addAction(okAction)
                            self.present(alert, animated: true, completion: nil)
                            self.therequestbutton.isEnabled = false
                        }
                    }
                }
            })
        }
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func randomString(length: Int) -> String {
        //announcements are 20 long
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        return randomString
    }
}
