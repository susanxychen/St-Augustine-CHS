//
//  clubPendingController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-12-27.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit
import Firebase

class clubPendingController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    //The Database
    var db: Firestore!
    var docRef: DocumentReference!
    
    //Cloud Functions
    lazy var functions = Functions.functions()
    
    var clubID: String!
    var clubName: String!
    var clubBadge: String!
    var pendingList = [String]()
    var pendingNamesList = [String]()
    var pendingEmailsList = [String]()
    var pendingMsgList = [String]()
    var pendingPics = [UIImage]()
    
    @IBOutlet weak var pendingListCollectionView: UICollectionView!
    
    //Refresh Variables
    var refreshControl: UIRefreshControl?
    let actInd: UIActivityIndicatorView = UIActivityIndicatorView()
    let container: UIView = UIView()
    
    
    //Returning to club controller
    var changedPendingList : ((Bool) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set Up
        // [START setup]
        let settings = FirestoreSettings()
        //settings.areTimestampsInSnapshotsEnabled = true
        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
        pendingListCollectionView.alwaysBounceVertical = true
        
        let lpgr: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(gestureRecognizer:)))
        lpgr.minimumPressDuration = 0.5
        //lpgr.delegate = self as? UIGestureRecognizerDelegate
        lpgr.delaysTouchesBegan = true
        self.pendingListCollectionView.addGestureRecognizer(lpgr)
        
        getpendingNamesList()
    }
    
    @objc func handleLongPress(gestureRecognizer : UILongPressGestureRecognizer){
        if (gestureRecognizer.state != UIGestureRecognizer.State.began){
            return
        }
        let p = gestureRecognizer.location(in: self.pendingListCollectionView)
        if let indexPath : NSIndexPath = (self.pendingListCollectionView.indexPathForItem(at: p) as NSIndexPath?){
            let actionSheet = UIAlertController(title: "Choose an Option for \(pendingNamesList[indexPath.item])", message: nil, preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Accept", style: .default, handler: { (action:UIAlertAction) in
                self.changedPendingList!(true)
                
                let msgToken = self.pendingMsgList[indexPath.item]
                self.functions.httpsCallable("manageSubscriptions").call(["registrationTokens": [msgToken], "isSubscribing": true, "clubID": self.clubID as Any]) { (result, error) in
                    if let error = error as NSError? {
                        if error.domain == FunctionsErrorDomain {
                            let code = FunctionsErrorCode(rawValue: error.code)
                            let message = error.localizedDescription
                            let details = error.userInfo[FunctionsErrorDetailsKey]
                            print(code as Any)
                            print(message)
                            print(details as Any)
                        }
                    }
                    print("Result is: \(String(describing: result?.data))")
                }
                
                self.functions.httpsCallable("sendToUser").call(["token": msgToken, "title": "Welcome To The Club!", "body": "You've been accepted into \(self.clubName ?? "a club")! Yay!"]) { (result, error) in
                    if let error = error as NSError? {
                        if error.domain == FunctionsErrorDomain {
                            let code = FunctionsErrorCode(rawValue: error.code)
                            let message = error.localizedDescription
                            let details = error.userInfo[FunctionsErrorDetailsKey]
                            print(code as Any)
                            print(message)
                            print(details as Any)
                        }
                    }
                }
                
                //Update club data
                let clubRef = self.db.collection("clubs").document(self.clubID)
                clubRef.updateData([
                    "pending": FieldValue.arrayRemove([self.pendingList[indexPath.item]]),
                    "members": FieldValue.arrayUnion([self.pendingList[indexPath.item]])
                ])
                
                //update user data
                let userRef = self.db.collection("users").document(self.pendingList[indexPath.item])
                
                //Give club badge if there is one
                if self.clubBadge as String != "" {
                    userRef.updateData([
                        "badges": FieldValue.arrayUnion([self.clubBadge as Any])
                    ])
                }
                
                userRef.updateData([
                    "clubs": FieldValue.arrayUnion([self.clubID as Any]),
                    "notifications": FieldValue.arrayUnion([self.clubID as Any]),
                ])
                
                //give em points
                self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                    let uDoc: DocumentSnapshot
                    do {
                        try uDoc = transaction.getDocument(userRef)
                    } catch let fetchError as NSError {
                        errorPointer?.pointee = fetchError
                        return nil
                    }
                    
                    guard let oldPoints = uDoc.data()?["points"] as? Int else {
                        let error = NSError(
                            domain: "AppErrorDomain",
                            code: -1,
                            userInfo: [
                                NSLocalizedDescriptionKey: "Unable to retrieve points from snapshot \(uDoc)"
                            ]
                        )
                        errorPointer?.pointee = error
                        return nil
                    }
                    transaction.updateData(["points": oldPoints + Defaults.joiningClub], forDocument: userRef)
                    return nil
                }, completion: { (object, err) in
                    if let error = err {
                        print("Transaction failed: \(error)")
                        let ac = UIAlertController(title: "Could not give points to user", message: "Error: \(error.localizedDescription)", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(ac, animated: true)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                            self.getClubData()
                        })
                    } else {
                        print("Transaction successfully committed!")
                        
                        //Give the grade points
                        let gradYear = Int(self.pendingEmailsList[indexPath.item].suffix(14).prefix(2)) ?? 0
                        let pointRef = self.db.collection("info").document("spiritPoints")
                        self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                            let pDoc: DocumentSnapshot
                            do {
                                try pDoc = transaction.getDocument(pointRef)
                            } catch let fetchError as NSError {
                                errorPointer?.pointee = fetchError
                                return nil
                            }
                            guard let oldPoints = pDoc.data()?[String(gradYear)] as? Int else {
                                let error = NSError(
                                    domain: "AppErrorDomain",
                                    code: -1,
                                    userInfo: [
                                        NSLocalizedDescriptionKey: "Unable to retrieve points from snapshot \(pDoc)"
                                    ]
                                )
                                errorPointer?.pointee = error
                                return nil
                            }
                            transaction.updateData([String(gradYear): oldPoints + Defaults.joiningClub], forDocument: pointRef)
                            return nil
                        }, completion: { (object, err) in
                            if let error = err {
                                print("Transaction failed: \(error)")
                                let ac = UIAlertController(title: "Transaction Error: Grad - \(gradYear)", message: "Error: \(error.localizedDescription)", preferredStyle: .alert)
                                ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                                self.present(ac, animated: true)
                            } else {
                                print("Transaction successfully committed!")
                                print("successfuly gave badge")
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                                self.getClubData()
                            })
                        })
                    }
                })
            }))
            actionSheet.addAction(UIAlertAction(title: "Reject", style: .default, handler: { (action:UIAlertAction) in
                self.changedPendingList!(true)
                let clubRef = self.db.collection("clubs").document(self.clubID)
                clubRef.updateData([
                    "pending": FieldValue.arrayRemove([self.pendingList[indexPath.item]])
                ])
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                    self.getClubData()
                })
            }))
            
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            self.present(actionSheet, animated: true, completion: nil)
        }
    }
    
    func getClubData() {
        pendingList.removeAll()
        self.showActivityIndicatory(container: self.container, actInd: self.actInd)
        db.collection("clubs").document(clubID).getDocument { (snap, err) in
            if let err = err {
                let alert = UIAlertController(title: "Error in updating Club", message: "Please Try Again later. Error: \(err.localizedDescription)", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            }
            if let snap = snap {
                self.pendingList = snap.data()!["pending"] as! [String]
                self.getpendingNamesList()
            }
        }
    }
    
    func getpendingNamesList(){
        pendingNamesList.removeAll()
        pendingEmailsList.removeAll()
        pendingMsgList.removeAll()
        pendingPics.removeAll()
        
        self.showActivityIndicatory(container: self.container, actInd: self.actInd)
        for _ in pendingList {
            pendingNamesList.append("")
            pendingEmailsList.append("")
            pendingMsgList.append("")
            pendingPics.append(UIImage(named: "safeProfilePic")!)
        }
        
        for user in 0..<pendingList.count {
            db.collection("users").document(pendingList[user]).collection("info").document("vital").getDocument { (snap, err) in
                if let err = err {
                    let alert = UIAlertController(title: "Error in getting list", message: "Please Try Again later. Error: \(err.localizedDescription)", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                }
                if let snap = snap {
                    let data = snap.data() ?? ["name":"error", "email":"error", "profilePic": 0, "msgToken":"error"]
                    self.pendingNamesList[user] = data["name"] as? String ?? "error"
                    self.pendingEmailsList[user] = data["email"] as? String ?? "error"
                    self.pendingMsgList[user] = data["msgToken"] as? String ?? "error"
                    
                    //Get the image
                    self.getPicture(profPic: data["profilePic"] as? Int ?? 0, user: user)
                }
            }
        }
        removeBrokenUsers()
    }
    
    func getPicture(profPic: Int, user: Int) {        
        //Image
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        // Create a reference to the file you want to download
        let imgRef = storageRef.child("profilePictures/\(profPic).png")
        
        imgRef.getMetadata { (metadata, error) in
            if let error = error {
                // Uh-oh, an error occurred!
                print("cant find image \(profPic)")
                print(error)
            } else {
                // Metadata now contains the metadata for 'images/forest.jpg'
                if let metadata = metadata {
                    let theMetaData = metadata.dictionaryRepresentation()
                    let updated = theMetaData["updated"]
                    
                    if let updated = updated {
                        if let savedImage = self.getSavedImage(named: "\(profPic)=\(updated)"){
                            print("already saved \(profPic)=\(updated)")
                                self.pendingPics[user] = savedImage
                        } else {
                            // Create a reference to the file you want to download
                            imgRef.downloadURL { url, error in
                                if error != nil {
                                    print("cant find image \(profPic)")
                                } else {
                                    // Get the download URL
                                    var image: UIImage?
                                    let data = try? Data(contentsOf: url!)
                                    if let imageData = data {
                                        image = UIImage(data: imageData)!
                                        self.pendingPics[user] = image!
                                        self.clearImageFolder(imageName: "\(profPic)=\(updated)")
                                        self.saveImageDocumentDirectory(image: image!, imageName: "\(profPic)=\(updated)")
                                    }
                                    print("i success now")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func removeBrokenUsers(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            //Filter out all the broken users
            print(self.pendingNamesList)
            var foundAnErrorUser = true
            while foundAnErrorUser {
                if let index = self.pendingNamesList.firstIndex(of: "error") {
                    foundAnErrorUser = true
                    self.pendingNamesList.remove(at: index)
                    self.pendingEmailsList.remove(at: index)
                    self.pendingMsgList.remove(at: index)
                    self.pendingPics.remove(at: index)
                    self.pendingList.remove(at: index)
                } else {
                    // not found
                    foundAnErrorUser = false
                }
            }
            self.sortAlpha()
        }
    }
    
    func sortAlpha(){
        if pendingList.count != 0 {
            var thereWasASwap = true
            while thereWasASwap {
                thereWasASwap = false
                for i in 0..<pendingList.count-1 {
                    let name1: String = pendingNamesList[i]
                    let name2: String = pendingNamesList[i+1]
                    
                    let shortestLength: Int
                    if name1.count < name2.count {
                        //print("\(name1) is shorter")
                        shortestLength = name1.count
                    } else {
                        //print("\(name2) is shorter")
                        shortestLength = name2.count
                    }
                    
                    //Because there is no easy string comparison (that i havent found)
                    //Compare letter by letter against both strings
                    for j in 0...shortestLength-1 {
                        //Compare Alphabetically by character (without caring about case)
                        let index1 = name1.index(name1.startIndex, offsetBy: j)
                        let index2 = name2.index(name2.startIndex, offsetBy: j)
                        let character1 = Character((String(name1[index1]).lowercased()))
                        let character2 = Character((String(name2[index2]).lowercased()))
                        
                        if character2 < character1 {
                            //Swap all related things
                            thereWasASwap = true
                            let temp = pendingNamesList[i]
                            pendingNamesList[i] = pendingNamesList[i+1]
                            pendingNamesList[i+1] = temp
                            
                            let temp2 = pendingList[i]
                            pendingList[i] = pendingList[i+1]
                            pendingList[i+1] = temp2
                            
                            let temp3 = pendingPics[i]
                            pendingPics[i] = pendingPics[i+1]
                            pendingPics[i+1] = temp3
                            
                            let temp4 = pendingEmailsList[i]
                            pendingEmailsList[i] = pendingEmailsList[i+1]
                            pendingEmailsList[i+1] = temp4
                            
                            let temp5 = pendingMsgList[i]
                            pendingMsgList[i] = pendingMsgList[i+1]
                            pendingMsgList[i+1] = temp5
                            
                            break
                        } else if character1 == character2 {
                            //If the letters are equal, check the next letter
                        } else {
                            //Not equal so we can just end the loop here
                            break
                        }
                    }
                }
            }
        }
        self.hideActivityIndicator(container: self.container, actInd: self.actInd)
        self.pendingListCollectionView.reloadData()
    }
    
    
    //For some odd reason iPhone SE requires this
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (self.pendingListCollectionView.frame.width), height: 64)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pendingNamesList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "name", for: indexPath) as! pendingListCell
        cell.nameLabel.text = pendingNamesList[indexPath.item]
        cell.emailLabel.text = pendingEmailsList[indexPath.item]
        cell.profilePic.image = pendingPics[indexPath.item]
        cell.profilePic.clipsToBounds = true
        cell.profilePic.layer.cornerRadius = 64/2
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(indexPath.item)
    }
    
}
