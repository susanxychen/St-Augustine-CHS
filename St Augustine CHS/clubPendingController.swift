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
    var pendingListNames = [String]()
    var pendingListEmails = [String]()
    var pendingListMsgTokens = [String]()
    var pendingListPics = [UIImage]()
    
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
        settings.areTimestampsInSnapshotsEnabled = true
        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
        pendingListCollectionView.alwaysBounceVertical = true
        
        let lpgr: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(gestureRecognizer:)))
        lpgr.minimumPressDuration = 0.5
        //lpgr.delegate = self as? UIGestureRecognizerDelegate
        lpgr.delaysTouchesBegan = true
        self.pendingListCollectionView.addGestureRecognizer(lpgr)
        
        getPendingListNames()
    }
    
    @objc func handleLongPress(gestureRecognizer : UILongPressGestureRecognizer){
        if (gestureRecognizer.state != UIGestureRecognizer.State.began){
            return
        }
        let p = gestureRecognizer.location(in: self.pendingListCollectionView)
        if let indexPath : NSIndexPath = (self.pendingListCollectionView.indexPathForItem(at: p) as NSIndexPath?){
            let actionSheet = UIAlertController(title: "Choose an Option for \(pendingListNames[indexPath.item])", message: nil, preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Accept", style: .default, handler: { (action:UIAlertAction) in
                self.changedPendingList!(true)
                
                let msgToken = self.pendingListMsgTokens[indexPath.item]
                self.functions.httpsCallable("manageSubscriptions").call(["registrationTokens": [msgToken], "isSubscribing": true, "clubID": self.clubID]) { (result, error) in
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
                
                self.functions.httpsCallable("sendToUser").call(["token": msgToken, "title": "You've been accepted into \(self.clubName ?? "a club")", "body": "Congrats!"]) { (result, error) in
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
                    "pending": FieldValue.arrayUnion([self.pendingList[indexPath.item]])
                ])
                
                //update user data
                let userRef = self.db.collection("users").document(self.pendingList[indexPath.item])
                
                if self.clubBadge as String != "" {
                    userRef.updateData([
                        "badges": FieldValue.arrayUnion([self.clubBadge])
                    ])
                }
                
                userRef.updateData([
                    "clubs": FieldValue.arrayUnion([self.clubID]),
                    "notifications": FieldValue.arrayUnion([self.clubID]),
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
                    } else {
                        print("Transaction successfully committed!")
                        
                        //Give the grade points
                        let gradYear = Int(self.pendingListEmails[indexPath.item].suffix(14).prefix(2)) ?? 0
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
                            } else {
                                print("Transaction successfully committed!")
                                print("successfuly gave badge")
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                                    self.getClubData()
                                })
                            }
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
                self.getPendingListNames()
            }
        }
    }
    
    func getPendingListNames(){
        pendingListNames.removeAll()
        pendingListEmails.removeAll()
        pendingListMsgTokens.removeAll()
        pendingListPics.removeAll()
        
        self.showActivityIndicatory(container: self.container, actInd: self.actInd)
        for _ in pendingList {
            pendingListNames.append("")
            pendingListEmails.append("")
            pendingListMsgTokens.append("")
            pendingListPics.append(UIImage())
        }
        for user in 0..<pendingList.count {
            db.collection("users").document(pendingList[user]).getDocument { (snap, err) in
                if let err = err {
                    let alert = UIAlertController(title: "Error in getting list", message: "Please Try Again later. Error: \(err.localizedDescription)", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                }
                if let snap = snap {
                    let data = snap.data() ?? ["name":"error", "email":"error", "profilePic": -1, "msgToken":"error"]
                    self.pendingListNames[user] = data["name"] as? String ?? "error"
                    self.pendingListEmails[user] = data["email"] as? String ?? "error"
                    self.pendingListMsgTokens[user] = data["msgToken"] as? String ?? "error"
                    
                    //Get the image
                    self.getPicture(profPic: data["profilePic"] as? Int ?? -1, user: user)
                }
            }
        }
        removeBrokenUsers()
    }
    
    func getPicture(profPic: Int, user: Int) {
        if profPic < 0 {
            pendingListPics[user] = UIImage()
            return
        }
        
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
                        if let savedImage = self.getSavedImage(named: "\(profPic)-\(updated)"){
                            print("already saved \(profPic)-\(updated)")
                                self.pendingListPics[user] = savedImage
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
                                        self.pendingListPics[user] = image!
                                        self.clearImageFolder(imageName: "\(profPic)-\(updated)")
                                        self.saveImageDocumentDirectory(image: image!, imageName: "\(profPic)-\(updated)")
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
            var foundAnErrorUser = true
            while foundAnErrorUser {
                if let index = self.pendingListNames.index(of: "error") {
                    foundAnErrorUser = true
                    self.pendingListNames.remove(at: index)
                    self.pendingListEmails.remove(at: index)
                    self.pendingListMsgTokens.remove(at: index)
                    self.pendingListPics.remove(at: index)
                    self.pendingList.remove(at: index)
                } else {
                    // not found
                    foundAnErrorUser = false
                }
            }
            
            self.hideActivityIndicator(container: self.container, actInd: self.actInd)
            self.pendingListCollectionView.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pendingListNames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "name", for: indexPath) as! pendingListCell
        cell.nameLabel.text = pendingListNames[indexPath.item]
        cell.emailLabel.text = pendingListEmails[indexPath.item]
        cell.profilePic.image = pendingListPics[indexPath.item]
        cell.profilePic.clipsToBounds = true
        cell.profilePic.layer.cornerRadius = 64/2
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(indexPath.item)
    }
    
}
