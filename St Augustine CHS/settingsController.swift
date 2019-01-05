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
    
    var stupidButtonPressedCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if allUserFirebaseData.data["status"] as! Int == 2 {
            clearKeys.isHidden = false
        }
        //create a new button
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "info"), for: .normal)
        //add function for button
        button.addTarget(self, action: #selector(stupidButtonPressed), for: .touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        
        let barButton = UIBarButtonItem(customView: button)
        //assign button to navigationbar
        self.navigationItem.rightBarButtonItem = barButton
        
        changePrivacySettingsButton.setTitleColor(DefaultColours.primaryColor, for: .normal)
        clearCacheButton.setTitleColor(DefaultColours.primaryColor, for: .normal)
        LogOutButton.setTitleColor(DefaultColours.primaryColor, for: .normal)
        clearKeys.setTitleColor(DefaultColours.primaryColor, for: .normal)
        
        cacheSizeLabel.text = sizeOfDocumentDirectory()
    }
    
    @objc func stupidButtonPressed(){
        stupidButtonPressedCount += 1
        //print(stupidButtonPressedCount)
        
        var specialCase = true
        var title = ""
        var message = ""
        
        switch (stupidButtonPressedCount){
        case 20:
            title = "Um why"
            message = "why are you still pressing this button?"
            break
        case 25:
            title = "??"
            message = "What are you doing?"
            break
        case 30:
            title = "Button is confused"
            message = "Why do you keep pressing me? I'm just a button doing my job no one else presses me this much please be normal"
            break
        case 40:
            title = "Why do this"
            message = "My name is Chumbus the Button, we can be friends. I took this job voluntarily and it's been chill up until now but now you keep poking me in the belly button"
        case 50:
            title = "i appreciate you here"
            message = "thanks for staying with me...but can you please stop pushing me?"
            break
        case 60:
            title = "maybe?"
            message = "maybe you are bored? There's a lot to do on the internet....and your homework"
            break
        case 70:
            title = "hmmm"
            message = "maybe you don't have anything better to do. sometimes there is no homework to do"
            break
        case 75:
            title = "hmmm"
            message = "Some courses just don't have a lot of homework. Or maybe you finished it all"
            break
        case 80:
            title = "welp"
            message = "Im bored. Want to hear a cool quote?"
            break
        case 85:
            title = "Kierkegarrd"
            message = "The individual particular is paradoxically superior to the universal because of the teleological suspension of the ethical or Abraham is lost"
            break
        case 90:
            title = "Heh"
            message = "If you don't get that ask Mr Hoffman. He will tell you what it means."
            break
        case 100:
            title = "Yawn"
            message = "im getting tired. im going to sleep now"
            break
        case 110:
            title = "*rolls over*"
            message = "no stop im sleeping. please go away ZZZZZZZZ"
            break
        case 125:
            title = "COME ON"
            message = "I was in the middle of the best dream! ughhh im going to see if I can recreate it"
            break
        case 130:
            title = "Oh I'm angry"
            message = "I'm awake now and I'm going to ignore you now"
            break
        case 155:
            title = "Hey stop"
            message = "a little red mark is starting to form where you keep poking me"
            break
        case 200:
            title = "Hehe"
            message = "it tickeles a little, but i might just be going numb."
            break
        case 260:
            title = "Ow"
            message = "yeah thats definetly a bruise forming"
            break
        case 300:
            title = "That's it"
            message = "You've reach the end of my story. Nothing more as I need to go now. Thanks."
            break
        case 600:
            title = "Hm."
            message = "You are persistent"
            break
        case 1000:
            title = "OK OK FINE YOU WIN"
            message = "HERE TAKE THIS JUST LEAVE ME ALONE PLEASE"
            //give points and/or badge?
            break
        default:
            specialCase = false
            break
        }
        
        //Just the beginning bits to hide the fact there is an easter egg
        if stupidButtonPressedCount < 5 {
            title = "Info"
            message = "Find any bugs? Sorry! Report it to the app dev team!"
            specialCase = true
        } else if stupidButtonPressedCount < 13 {
            title = "Info?"
            message = "Find any bugs?? Sorry!? Report it to the app dev team!?"
            specialCase = true
        } else if stupidButtonPressedCount < 19 {
            title = "Info???"
            message = "Did you find any bugs?? Please report it!"
            specialCase = true
        }
        
        if specialCase {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.view.tintColor = UIColor.black
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
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

