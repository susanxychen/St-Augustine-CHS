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

class settingsController: UIViewController {

    @IBOutlet weak var cacheSizeLabel: UILabel!
    @IBOutlet weak var clearKeys: UIButton!
    
    @IBOutlet weak var changePrivacySettingsButton: UIButton!
    @IBOutlet weak var clearCacheButton: UIButton!
    @IBOutlet weak var LogOutButton: UIButton!
    @IBOutlet weak var clearKeysButton: UIButton!
    @IBOutlet weak var subscribedToGeneralSwitch: UISwitch!
    var subscribedToGeneral = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if allUserFirebaseData.data["status"] as! Int == 2 {
            clearKeys.isHidden = false
        }
        
        changePrivacySettingsButton.setTitleColor(Defaults.primaryColor, for: .normal)
        clearCacheButton.setTitleColor(Defaults.primaryColor, for: .normal)
        LogOutButton.setTitleColor(Defaults.primaryColor, for: .normal)
        clearKeys.setTitleColor(Defaults.primaryColor, for: .normal)
        
        cacheSizeLabel.text = sizeOfDocumentDirectory()
        
        if let x = UserDefaults.standard.object(forKey: "subscribedToGeneral") as? Bool {
            subscribedToGeneral = x
        } else {
            subscribedToGeneral = false
        }
        subscribedToGeneralSwitch.setOn(subscribedToGeneral, animated: true)
    }
    
    @IBAction func subscribedToGeneralPressed(_ sender: UISwitch) {
        if sender.isOn {
            Messaging.messaging().subscribe(toTopic: "general") { error in
                print("Subscribed to general topic")
                UserDefaults.standard.set(true, forKey: "subscribedToGeneral")
            }
        } else {
            //Create the alert controller.
            let alert = UIAlertController(title: "Confirmation", message: "Are you sure you don't want to receive general announcements??", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil)
            let confirmAction = UIAlertAction(title: "Confirm", style: UIAlertAction.Style.destructive) { (action:UIAlertAction) in
                Messaging.messaging().unsubscribe(fromTopic: "general") { error in
                    print("Unsubscribed to general topic")
                    UserDefaults.standard.set(false, forKey: "subscribedToGeneral")
                }
            }
            alert.addAction(confirmAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
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
    
    //For debugging
    @IBAction func clearKeys(_ sender: Any) {
        print("Before: \(Array(UserDefaults.standard.dictionaryRepresentation().keys).count) keys")
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        print("After: \(Array(UserDefaults.standard.dictionaryRepresentation().keys).count) keys")
    }
    
    //********************************CACHE********************************
    @IBAction func removeCache(_ sender: Any) {
        //Create the alert controller.
        let alert = UIAlertController(title: "Confirmation", message: "Are you sure you want to clear cache? You will need to redownload all pictures again.", preferredStyle: .alert)
        
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
    
    //********************************DOC DIRECT********************************
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

