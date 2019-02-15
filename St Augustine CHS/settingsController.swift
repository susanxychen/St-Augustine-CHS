//
//  settingsController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-10-15.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import MessageUI

class settingsController: UIViewController, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var classesSwitch: UISwitch!
    @IBOutlet weak var clubsSwitch: UISwitch!
    @IBOutlet weak var classesPrivateLabel: UILabel!
    @IBOutlet weak var clubsPrivateLabel: UILabel!
    @IBOutlet weak var signUpFlowButton: UIButton!
    @IBOutlet weak var generalAnnouncementNotificationLabel: UILabel!
    @IBOutlet weak var sendFeedbackButton: UIButton!
    @IBOutlet weak var cacheSizeLabel: UILabel!
    @IBOutlet weak var clearKeysButton: UIButton!
    @IBOutlet weak var subscribeDebugButton: UIButton!
    @IBOutlet weak var checkRemoteConfigButton: UIButton!
    @IBOutlet weak var clearCacheButton: UIButton!
    @IBOutlet weak var LogOutButton: UIButton!
    @IBOutlet weak var subscribedToGeneralSwitch: UISwitch!
    var subscribedToGeneral = false
    
    //The Database
    var db: Firestore!
    var docRef: DocumentReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Set Up
        // [START setup]
        let settings = FirestoreSettings()
        settings.areTimestampsInSnapshotsEnabled = true
        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
        //If status 2, show debug
        if allUserFirebaseData.data["status"] as? Int ?? 0 == 2 {
            clearKeysButton.isHidden = false
            subscribeDebugButton.isHidden = false
            checkRemoteConfigButton.isHidden = false
            signUpFlowButton.isHidden = false
        }
        
        //Colours
        classesPrivateLabel.textColor = Defaults.primaryColor
        clubsPrivateLabel.textColor = Defaults.primaryColor
        clearCacheButton.setTitleColor(Defaults.primaryColor, for: .normal)
        LogOutButton.setTitleColor(Defaults.primaryColor, for: .normal)
        sendFeedbackButton.setTitleColor(Defaults.primaryColor, for: .normal)
        generalAnnouncementNotificationLabel.textColor = Defaults.primaryColor
        
        clearKeysButton.setTitleColor(Defaults.primaryColor, for: .normal)
        subscribeDebugButton.setTitleColor(Defaults.primaryColor, for: .normal)
        checkRemoteConfigButton.setTitleColor(Defaults.primaryColor, for: .normal)
        
        cacheSizeLabel.text = sizeOfDocumentDirectory()
        
        //Toggle the switch state depending on whether user has subscribed to general
        if (allUserFirebaseData.data["notifications"] as? [String] ?? []).contains("general") {
            subscribedToGeneral = true
        } else {
            subscribedToGeneral = false
        }
        subscribedToGeneralSwitch.setOn(subscribedToGeneral, animated: true)
        
        classesSwitch.setOn(allUserFirebaseData.data["showClasses"] as? Bool ?? false, animated: true)
        clubsSwitch.setOn(allUserFirebaseData.data["showClubs"] as? Bool ?? false, animated: true)
    }
    
    @IBAction func privacySwitchPressed(_ sender: UISwitch) {
        //Disable the switch until update to prevent spam
        let uid = Auth.auth().currentUser?.uid
        if sender == classesSwitch {
            classesSwitch.isUserInteractionEnabled = false
            if sender.isOn {
                db.collection("users").document(uid ?? "error").setData(["showClasses":false], merge: true) { (error) in
                    if let error = error {
                        let ac = UIAlertController(title: "Cannot update preference", message: "Error: \(error.localizedDescription)", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(ac, animated: true)
                    } else {
                        allUserFirebaseData.data["showClasses"] = false
                        self.classesSwitch.isUserInteractionEnabled = true
                    }
                }
            } else {
                db.collection("users").document(uid ?? "error").setData(["showClasses":true], merge: true) { (error) in
                    if let error = error {
                        let ac = UIAlertController(title: "Cannot update preference", message: "Error: \(error.localizedDescription)", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(ac, animated: true)
                    } else {
                        allUserFirebaseData.data["showClasses"] = true
                        self.classesSwitch.isUserInteractionEnabled = true
                    }
                }
            }
        } else {
            clubsSwitch.isUserInteractionEnabled = false
            if sender.isOn {
                db.collection("users").document(uid ?? "error").setData(["showClubs":false], merge: true) { (error) in
                    if let error = error {
                        let ac = UIAlertController(title: "Cannot update preference", message: "Error: \(error.localizedDescription)", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(ac, animated: true)
                    } else {
                        allUserFirebaseData.data["showClasses"] = false
                        self.clubsSwitch.isUserInteractionEnabled = true
                    }
                }
            } else {
                db.collection("users").document(uid ?? "error").setData(["showClubs":true], merge: true) { (error) in
                    if let error = error {
                        let ac = UIAlertController(title: "Cannot update preference", message: "Error: \(error.localizedDescription)", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(ac, animated: true)
                    } else {
                        allUserFirebaseData.data["showClubs"] = true
                        self.clubsSwitch.isUserInteractionEnabled = true
                    }
                }
            }
        }
    }
    
    //****************************FEEDBACK AND MAIL****************************
    @IBAction func sendFeedbackPressed(_ sender: Any) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["sachsappteam@gmail.com"])
            mail.setSubject("[FEEDBACK]")
            
            self.present(mail, animated: true)
        } else {
            let ac = UIAlertController(title: "Cannot open mail app", message: "Note: MFMailComposeVC requires at least one email address to be signed into the mail app", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(ac, animated: true)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    //****************************DEBUGGING****************************
    @IBAction func subscribedToGeneralPressed(_ sender: UISwitch) {
        if sender.isOn {
            Messaging.messaging().subscribe(toTopic: "general") { error in
                print("Subscribed to general topic")
            }
            
            let userRef = self.db.collection("users").document((Auth.auth().currentUser?.uid)!)
            userRef.updateData(["notifications": FieldValue.arrayUnion(["general"])])
            
            let user = Auth.auth().currentUser
            self.db.collection("users").document((user?.uid)!).getDocument { (docSnapshot, err) in
                if let docSnapshot = docSnapshot {
                    allUserFirebaseData.data = docSnapshot.data()!
                }
            }
            
            //Show alert for around 2 seconds
            let alert = UIAlertController(title: "", message: "Subscribed!", preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5){
                alert.dismiss(animated: true, completion: nil)
            }
            
        } else {
            //Create the alert controller.
            let alert = UIAlertController(title: "Confirmation", message: "Are you sure you don't want to receive general announcements? You may miss out on important information", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { (alert) in
                self.subscribedToGeneralSwitch.setOn(true, animated: true)
            }
            let confirmAction = UIAlertAction(title: "Confirm", style: UIAlertAction.Style.destructive) { (action:UIAlertAction) in
                Messaging.messaging().unsubscribe(fromTopic: "general") { error in
                    print("Unsubscribed to general topic")
                    
                    if let error = error {
                        let alert = UIAlertController(title: "Error", message: "Cannot unsubscribe: \(error.localizedDescription)", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        let userRef = self.db.collection("users").document((Auth.auth().currentUser?.uid)!)
                        userRef.updateData(["notifications": FieldValue.arrayRemove(["general"])])
                        
                        let user = Auth.auth().currentUser
                        self.db.collection("users").document((user?.uid)!).getDocument { (docSnapshot, err) in
                            if let docSnapshot = docSnapshot {
                                allUserFirebaseData.data = docSnapshot.data()!
                            }
                        }
                        
                        //Show alert for around 2 seconds
                        let alert = UIAlertController(title: "", message: "Unsubscribed", preferredStyle: .alert)
                        self.present(alert, animated: true, completion: nil)
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5){
                            alert.dismiss(animated: true, completion: nil)
                        }
                    }
                }
                
            }
            alert.addAction(confirmAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    //Alert to subscribe/unsubscribe to a topic
    @IBAction func pressedSubscribeTopic(_ sender: Any) {
        let confirm = UIAlertController(title: "Subscription to a Topic", message: nil, preferredStyle: .alert)
        confirm.addTextField { (tf) in
            tf.placeholder = "Topic"
        }
        confirm.addAction(UIAlertAction(title: "Unsubscribe", style: UIAlertAction.Style.default) { (action:UIAlertAction) in
            let tf = confirm.textFields?[0]
            let topic = tf?.text ?? "error"
            Messaging.messaging().unsubscribe(fromTopic: topic) { error in
                if let error = error {
                    let alert = UIAlertController(title: "Error", message: "Cannot unsubscribe: \(error.localizedDescription)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    let userRef = self.db.collection("users").document((Auth.auth().currentUser?.uid)!)
                    userRef.updateData(["notifications": FieldValue.arrayRemove([topic])])
                    let user = Auth.auth().currentUser
                    self.db.collection("users").document((user?.uid)!).getDocument { (docSnapshot, err) in
                        if let docSnapshot = docSnapshot {
                            allUserFirebaseData.data = docSnapshot.data()!
                        }
                    }
                    let alert = UIAlertController(title: "", message: "Unsubscribed from \(topic)", preferredStyle: .alert)
                    self.present(alert, animated: true, completion: nil)
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5){
                        alert.dismiss(animated: true, completion: nil)
                    }
                }
            }
        })
        confirm.addAction(UIAlertAction(title: "Subscribe", style: UIAlertAction.Style.default) { (action:UIAlertAction) in
            let tf = confirm.textFields?[0]
            let topic = tf?.text ?? "error"
            Messaging.messaging().subscribe(toTopic: topic) { error in
                if let error = error {
                    let alert = UIAlertController(title: "Error", message: "Cannot subscribe: \(error.localizedDescription)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    let userRef = self.db.collection("users").document((Auth.auth().currentUser?.uid)!)
                    userRef.updateData(["notifications": FieldValue.arrayUnion([topic])])
                    let user = Auth.auth().currentUser
                    self.db.collection("users").document((user?.uid)!).getDocument { (docSnapshot, err) in
                        if let docSnapshot = docSnapshot {
                            allUserFirebaseData.data = docSnapshot.data()!
                        }
                    }
                    let alert = UIAlertController(title: "", message: "Subscribed to \(topic)", preferredStyle: .alert)
                    self.present(alert, animated: true, completion: nil)
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5){
                        alert.dismiss(animated: true, completion: nil)
                    }
                }
            }
        })
        confirm.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        self.present(confirm, animated: true, completion: nil)
    }
    
    //Remove all keys (.plists). For resetting votes on songs, any user defaults
    @IBAction func clearKeys(_ sender: Any) {
        let confirm = UIAlertController(title: "Clear Keys?", message: nil, preferredStyle: .alert)
        confirm.addAction(UIAlertAction(title: "Confirm", style: UIAlertAction.Style.default) { (action:UIAlertAction) in
            print("Before: \(Array(UserDefaults.standard.dictionaryRepresentation().keys).count) keys")
            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
            print("After: \(Array(UserDefaults.standard.dictionaryRepresentation().keys).count) keys")
            
            let alert = UIAlertController(title: "", message: "Cleared", preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1){
                alert.dismiss(animated: true, completion: nil)
            }
            
        })
        confirm.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        self.present(confirm, animated: true, completion: nil)
    }
    
    //********************************CACHE********************************
    @IBAction func removeCache(_ sender: Any) {
        //Create the alert controller.
        let alert = UIAlertController(title: "Clearing cache frees up space on your device's storage", message: "However, you will need to redownload all pictures again. Are you sure you want to clear cache?", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { (action:UIAlertAction) in
            print("You've pressed cancel");
        }
        
        let confirmAction = UIAlertAction(title: "Confirm", style: UIAlertAction.Style.default) { (action:UIAlertAction) in
            print("Clearing cache");
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            guard let items = try? FileManager.default.contentsOfDirectory(atPath: path) else { return }
            
            for item in items {
                // This can be made better by using pathComponent
                let completePath = path.appending("/").appending(item)
                try? FileManager.default.removeItem(atPath: completePath)
            }
            
            self.cacheSizeLabel.text = self.sizeOfDocumentDirectory()
        }
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    //****************************LOGGING OUT****************************
    @IBAction func pressedLogOut(_ sender: Any) {
        //Log out Google
        GIDSignIn.sharedInstance()?.signOut()
        //Log out Firebase
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    //********************************DOCUMENT DIRECTORY********************************
    func sizeOfDocumentDirectory() -> String {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        guard let items = try? FileManager.default.contentsOfDirectory(atPath: path) else { return "Error in getting Size" }
        
        var size:Int64 = 0
        for item in items {
            // This can be made better by using pathComponent
            let completePath = path.appending("/").appending(item)
            size += sizeOfFolder(completePath) ?? 0
        }
        
        let fileSizeStr = ByteCountFormatter.string(fromByteCount: size, countStyle: ByteCountFormatter.CountStyle.file)
        return fileSizeStr
    }
    
    func sizeOfFolder(_ folderPath: String) -> Int64? {
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: folderPath)
            var folderSize: Int64 = 0
            for content in contents {
                do {
                    let fullContentPath = folderPath + "/" + content
                    let fileAttributes = try FileManager.default.attributesOfItem(atPath: fullContentPath)
                    folderSize += fileAttributes[FileAttributeKey.size] as? Int64 ?? 0
                } catch _ {
                    continue
                }
            }
            
            /// This line will give you formatted size from bytes ....
           
            return folderSize
            
        } catch let error {
            print(error.localizedDescription)
            return nil
        }
    }
}

