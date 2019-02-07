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
    
    //Allows refreshing the song req controller when done adding song
    var onDoneBlock : ((Bool) -> Void)?
    
    //Colours
    @IBOutlet weak var statusBarView: UIView!
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    
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
        
        //colours
        statusBarView.backgroundColor = Defaults.darkerPrimary
        topBarView.backgroundColor = Defaults.primaryColor
        songNameLabel.textColor = Defaults.primaryColor
        songName.tintColor = Defaults.accentColor
        artistNameLabel.textColor = Defaults.primaryColor
        artistName.tintColor = Defaults.accentColor
        
        hideKeyboardWhenTappedAround()
        
        getTimeFromServer { (serverDate) in
            self.theDate = serverDate
        }
    }
    
    //**********Dismiss**********
    @IBAction func cancelPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //**********Suggest the song**********
    @IBAction func suggestPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Are you sure you want to spend \(Defaults.requestSong) points to request a song? (You currently have \(allUserFirebaseData.data["points"] ?? "error") points)", message: "Songs will be removed after 2 days from the date they were requested. No refunds.\n\nAdministration will be able to see who requested what song and have the power to ban those who request inappropriate or irrelevant content. Do not spam request songs.", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { (action:UIAlertAction) in
            print("You've pressed cancel");
        }
        
        let confirmAction = UIAlertAction(title: "Confirm", style: UIAlertAction.Style.default) { (action:UIAlertAction) in
            //Check to see if user is broke
            if allUserFirebaseData.data["points"] as? Int ?? 0 >= Defaults.requestSong {
                let artist = self.artistName.text
                let song = self.songName.text
                let id = self.randomString(length: 20)
                
                //Disallow empty strings
                if artist == "" || song == "" {
                    let alert = UIAlertController(title: "Error", message: "Fill in both artist name and song name", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                } else {
                    self.showActivityIndicatory(container: self.container, actInd: self.actInd)
                    
                    let user = Auth.auth().currentUser
                    
                    //Take away your points and only upload the song if taken away points
                    self.db.collection("users").document((user?.uid)!).setData([
                        "points": (allUserFirebaseData.data["points"] as! Int) - Defaults.requestSong
                    ], mergeFields: ["points"]) { (err) in
                        if let err = err {
                            print("Error writing document: \(err)")
                            let alert = UIAlertController(title: "Error in retrieveing songs", message: "Please Try Again later. Error: \(err.localizedDescription)", preferredStyle: .alert)
                            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                            alert.addAction(okAction)
                            self.present(alert, animated: true, completion: nil)
                            self.hideActivityIndicator(container: self.container, actInd: self.actInd)
                        }
                        
                        self.db.collection("users").document((user?.uid)!).getDocument { (docSnapshot, err) in
                            if let err = err {
                                print("Error writing document: \(err)")
                                let alert = UIAlertController(title: "Error in retrieveing users", message: "Please Try Again later. Error: \(err.localizedDescription)", preferredStyle: .alert)
                                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                alert.addAction(okAction)
                                self.present(alert, animated: true, completion: nil)
                                self.hideActivityIndicator(container: self.container, actInd: self.actInd)
                            }
                            
                            if let docSnapshot = docSnapshot {
                                allUserFirebaseData.data = docSnapshot.data()!
                                
                                //Add the song
                                self.db.collection("songs").document(id).setData([
                                    "artist": artist as Any,
                                    "date": self.theDate,
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
                                        self.hideActivityIndicator(container: self.container, actInd: self.actInd)
                                    } else {
                                        print("Document successfully written!")
                                        self.onDoneBlock!(true)
                                        self.hideActivityIndicator(container: self.container, actInd: self.actInd)
                                        self.dismiss(animated: true, completion: nil)
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                let alert = UIAlertController(title: "Error", message: "You don't have enough points to request a song :(", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK...", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
        
    }
    
    var theDate: Date! = Date()
    func getTimeFromServer(completionHandler:@escaping (_ getResDate: Date?) -> Void){
        let url = URL(string: "https://www.apple.com")
        let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
            let httpResponse = response as? HTTPURLResponse
            if let contentType = httpResponse!.allHeaderFields["Date"] as? String {
                //print(httpResponse)
                let dFormatter = DateFormatter()
                dFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
                let serverTime = dFormatter.date(from: contentType)
                completionHandler(serverTime)
            }
        }
        task.resume()
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
