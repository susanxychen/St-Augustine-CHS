//
//  clubMembersController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-12-27.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit
import Firebase

class clubMembersController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    //The Database
    var db: Firestore!
    var docRef: DocumentReference!
    
    var clubID: String!
    var isClubAdmin: Bool!
    
    var adminsList = [String]()
    var membersList = [String]()
    
    var adminsNamesList = [String]()
    var membersNamesList = [String]()
    
    var adminsEmailsList = [String]()
    var membersEmailsList = [String]()
    
    var adminsPics = [UIImage]()
    var membersPics = [UIImage]()
    
    @IBOutlet weak var adminsCollectionView: UICollectionView!
    @IBOutlet weak var adminsCollectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var membersCollectionView: UICollectionView!
    @IBOutlet weak var membersCollectionViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var membersEntireHeight: NSLayoutConstraint!
    
    //Refresh Variables
    var refreshControl: UIRefreshControl?
    let actInd: UIActivityIndicatorView = UIActivityIndicatorView()
    let container: UIView = UIView()
    let overlayView = UIView(frame: UIApplication.shared.keyWindow!.frame)
    
    //Returning to club controller
    var promotedAMember : ((Bool) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set Up
        // [START setup]
        let settings = FirestoreSettings()
        settings.areTimestampsInSnapshotsEnabled = true
        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
        if isClubAdmin {
            print("is an admin")
            let lpgr: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(gestureRecognizer:)))
            lpgr.minimumPressDuration = 0.5
            lpgr.delaysTouchesBegan = true
            self.membersCollectionView.addGestureRecognizer(lpgr)
        }
        if allUserFirebaseData.data["status"] as? Int ?? 0 > 0 {
            print("Is a teacher")
            let lpgr: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPressAdmin(gestureRecognizer:)))
            lpgr.minimumPressDuration = 0.5
            lpgr.delaysTouchesBegan = true
            self.adminsCollectionView.addGestureRecognizer(lpgr)
        }
        
        getNames()
    }
    
    func getClubData(){
        adminsList.removeAll()
        membersList.removeAll()
        self.showActivityIndicatory(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
        db.collection("clubs").document(clubID).getDocument { (snap, err) in
            if let err = err {
                let alert = UIAlertController(title: "Error in updating Club", message: "Please Try Again later. Error: \(err.localizedDescription)", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            }
            if let snap = snap {
                self.adminsList = snap.data()!["admins"] as! [String]
                self.membersList = snap.data()!["members"] as! [String]
                self.getNames()
            }
        }
    }
    
    func getNames() {
        self.showActivityIndicatory(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
        adminsNamesList.removeAll()
        membersNamesList.removeAll()
        adminsEmailsList.removeAll()
        membersEmailsList.removeAll()
        adminsPics.removeAll()
        membersPics.removeAll()
        
        for _ in adminsList {
            adminsNamesList.append("")
            adminsEmailsList.append("")
            adminsPics.append(UIImage())
        }
        
        for _ in membersList {
            membersNamesList.append("")
            membersEmailsList.append("")
            membersPics.append(UIImage())
        }
        
        for user in 0..<adminsList.count {
            db.collection("users").document(adminsList[user]).getDocument { (snap, err) in
                if let err = err {
                    let alert = UIAlertController(title: "Error in getting list", message: "Please Try Again later. Error: \(err.localizedDescription)", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                }
                if let snap = snap {
                    let data = snap.data()!
                    self.adminsNamesList[user] = data["name"] as? String ?? "error"
                    self.adminsEmailsList[user] = data["email"] as? String ?? "error"
                    
                    //Get the image
                    self.getPicture(profPic: data["profilePic"] as! Int, user: user, isAdmin: true)
                }
            }
        }
        
        for user in 0..<membersList.count {
            db.collection("users").document(membersList[user]).getDocument { (snap, err) in
                if let err = err {
                    let alert = UIAlertController(title: "Error in getting list", message: "Please Try Again later. Error: \(err.localizedDescription)", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                }
                if let snap = snap {
                    let data = snap.data()!
                    self.membersNamesList[user] = data["name"] as? String ?? "error"
                    self.membersEmailsList[user] = data["email"] as? String ?? "error"
                    
                    //Get the image
                    self.getPicture(profPic: data["profilePic"] as! Int, user: user, isAdmin: false)
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
            self.adminsCollectionView.reloadData()
            self.membersCollectionView.reloadData()
        }
    }
    
    @objc func handleLongPressAdmin(gestureRecognizer : UILongPressGestureRecognizer){
        if (gestureRecognizer.state != UIGestureRecognizer.State.began){
            return
        }
        let p = gestureRecognizer.location(in: self.adminsCollectionView)
        if let indexPath : NSIndexPath = (self.adminsCollectionView.indexPathForItem(at: p) as NSIndexPath?){
            let actionSheet = UIAlertController(title: "Choose an Option for \(adminsNamesList[indexPath.item])", message: nil, preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Remove from Club", style: .default, handler: { (action:UIAlertAction) in
                //Create the alert controller.
                let alert = UIAlertController(title: "Confirmation", message: "Are you sure you want to remove \(self.adminsNamesList[indexPath.item])?", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil)
                let confirmAction = UIAlertAction(title: "Confirm", style: UIAlertAction.Style.destructive) { (action:UIAlertAction) in
                    self.promotedAMember!(true)
                    let clubRef = self.db.collection("clubs").document(self.clubID)
                    clubRef.updateData([
                        "admins": FieldValue.arrayRemove([self.adminsList[indexPath.item]])
                    ])
                    let userRef = self.db.collection("users").document(self.adminsList[indexPath.item])
                    userRef.updateData([
                        "clubs": FieldValue.arrayRemove([self.clubID])
                    ])
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                        self.getClubData()
                    })
                }
                alert.addAction(confirmAction)
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            }))
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(actionSheet, animated: true, completion: nil)
        }
    }
    
    @objc func handleLongPress(gestureRecognizer : UILongPressGestureRecognizer){
        if (gestureRecognizer.state != UIGestureRecognizer.State.began){
            return
        }
        let p = gestureRecognizer.location(in: self.membersCollectionView)
        if let indexPath : NSIndexPath = (self.membersCollectionView.indexPathForItem(at: p) as NSIndexPath?){
            let actionSheet = UIAlertController(title: "Choose an Option for \(membersNamesList[indexPath.item])", message: nil, preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Promote to Admin", style: .default, handler: { (action:UIAlertAction) in
                //Create the alert controller.
                let alert = UIAlertController(title: "Confirmation", message: "Are you sure you want to promote \(self.membersNamesList[indexPath.item])?", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil)
                let confirmAction = UIAlertAction(title: "Confirm", style: UIAlertAction.Style.default) { (action:UIAlertAction) in
                    self.promotedAMember!(true)
                    let clubRef = self.db.collection("clubs").document(self.clubID)
                    clubRef.updateData([
                        "members": FieldValue.arrayRemove([self.membersList[indexPath.item]])
                        ])
                    clubRef.updateData([
                        "admins": FieldValue.arrayUnion([self.membersList[indexPath.item]])
                        ])
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                        self.getClubData()
                    })
                }
                alert.addAction(confirmAction)
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            }))
            actionSheet.addAction(UIAlertAction(title: "Remove from Club", style: .default, handler: { (action:UIAlertAction) in
                //Create the alert controller.
                let alert = UIAlertController(title: "Confirmation", message: "Are you sure you want to remove \(self.membersNamesList[indexPath.item])?", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil)
                let confirmAction = UIAlertAction(title: "Confirm", style: UIAlertAction.Style.destructive) { (action:UIAlertAction) in
                    self.promotedAMember!(true)
                    let clubRef = self.db.collection("clubs").document(self.clubID)
                    clubRef.updateData([
                        "members": FieldValue.arrayRemove([self.membersList[indexPath.item]])
                    ])
                    let userRef = self.db.collection("users").document(self.membersList[indexPath.item])
                    userRef.updateData([
                        "clubs": FieldValue.arrayRemove([self.clubID])
                    ])
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                        self.getClubData()
                    })
                }
                alert.addAction(confirmAction)
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            }))
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(actionSheet, animated: true, completion: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == adminsCollectionView {
            return adminsNamesList.count
        } else {
            return membersNamesList.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let height = self.adminsCollectionView.contentSize.height + self.membersCollectionView.contentSize.height + 50
        self.adminsCollectionViewHeight.constant = self.adminsCollectionView.contentSize.height + 10
        self.membersCollectionViewHeight.constant = self.membersCollectionView.contentSize.height + 10
        
        //If the screen is too small to fit all announcements, just change the height to whatever it is
        if height > UIScreen.main.bounds.height {
            self.membersEntireHeight.constant = height
        } else {
            self.membersEntireHeight.constant = UIScreen.main.bounds.height
        }
        
        if collectionView == adminsCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "admin", for: indexPath) as! adminCell
            cell.adminName.text = adminsNamesList[indexPath.item]
            cell.adminEmail.text = adminsEmailsList[indexPath.item]
            cell.adminPic.image = adminsPics[indexPath.item]
            cell.adminPic.clipsToBounds = true
            cell.adminPic.layer.cornerRadius = 64/2
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "member", for: indexPath) as! memberCell
            cell.memberName.text = membersNamesList[indexPath.item]
            cell.memberEmail.text = membersEmailsList[indexPath.item]
            cell.memberPic.image = membersPics[indexPath.item]
            cell.memberPic.clipsToBounds = true
            cell.memberPic.layer.cornerRadius = 64/2
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(indexPath.item)
    }
    
    func getPicture(profPic: Int, user: Int, isAdmin: Bool) {
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
                            if isAdmin {
                                self.adminsPics[user] = savedImage
                            } else {
                                self.membersPics[user] = savedImage
                            }
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
                                        if isAdmin {
                                            self.adminsPics[user] = image!
                                        } else {
                                            self.membersPics[user] = image!
                                        }
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
}
