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
    
    //Cloud Functions
    lazy var functions = Functions.functions()
    
    var clubName = "a club"
    var clubID: String!
    var clubBadge: String!
    var isClubAdmin: Bool!
    
    var adminsList = [String]()
    var membersList = [String]()
    
    var adminsNamesList = [String]()
    var membersNamesList = [String]()
    
    var adminsEmailsList = [String]()
    var membersEmailsList = [String]()
    
    var adminsMsgList = [String]()
    var membersMsgList = [String]()
    
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
    
    
    //Returning to club controller
    var promotedAMember : ((Bool) -> Void)?
    
    //Colours
    @IBOutlet weak var adminLabel: UILabel!
    @IBOutlet weak var memberLabel: UILabel!
    
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
        
        adminLabel.textColor = Defaults.primaryColor
        memberLabel.textColor = Defaults.primaryColor
        
        getNames()
    }
    
    func getClubData(){
        adminsList.removeAll()
        membersList.removeAll()
        self.showActivityIndicatory(container: self.container, actInd: self.actInd)
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
        self.showActivityIndicatory(container: self.container, actInd: self.actInd)
        adminsNamesList.removeAll()
        membersNamesList.removeAll()
        adminsEmailsList.removeAll()
        membersEmailsList.removeAll()
        adminsPics.removeAll()
        membersPics.removeAll()
        
        for _ in adminsList {
            adminsNamesList.append("")
            adminsEmailsList.append("")
            adminsMsgList.append("")
            adminsPics.append(UIImage())
        }
        
        for _ in membersList {
            membersNamesList.append("")
            membersEmailsList.append("")
            membersMsgList.append("")
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
                    let data = snap.data() ?? ["name":"error", "email":"error", "profilePic": 0, "msgToken":"error"]
                    self.adminsNamesList[user] = data["name"] as? String ?? "error"
                    self.adminsEmailsList[user] = data["email"] as? String ?? "error"
                    self.adminsMsgList[user] = data["msgToken"] as? String ?? "error"
                    
                    //Get the image
                    self.getPicture(profPic: data["profilePic"] as? Int ?? 0, user: user, isAdmin: true)
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
                    let data = snap.data() ?? ["name":"error", "email":"error", "profilePic": 0, "msgToken":"error"]
                    self.membersNamesList[user] = data["name"] as? String ?? "error"
                    self.membersEmailsList[user] = data["email"] as? String ?? "error"
                    self.membersMsgList[user] = data["msgToken"] as? String ?? "error"
                    
                    //Get the image
                    self.getPicture(profPic: data["profilePic"] as? Int ?? 0, user: user, isAdmin: false)
                }
            }
        }
        removeBrokenUsers()
    }
    
    func removeBrokenUsers(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            //Filter out all the broken users
            var foundAnErrorUser = true
            while foundAnErrorUser {
                if let index = self.membersNamesList.index(of: "error") {
                    foundAnErrorUser = true
                    self.membersNamesList.remove(at: index)
                    self.membersEmailsList.remove(at: index)
                    self.membersMsgList.remove(at: index)
                    self.membersPics.remove(at: index)
                    self.membersList.remove(at: index)
                } else {
                    // not found
                    foundAnErrorUser = false
                }
            }
            
            foundAnErrorUser = true
            while foundAnErrorUser {
                if let index = self.adminsNamesList.index(of: "error") {
                    foundAnErrorUser = true
                    self.adminsNamesList.remove(at: index)
                    self.adminsEmailsList.remove(at: index)
                    self.adminsMsgList.remove(at: index)
                    self.adminsPics.remove(at: index)
                    self.adminsList.remove(at: index)
                } else {
                    // not found
                    foundAnErrorUser = false
                }
            }
            self.sortAlpha()
        }
    }
    
    func sortAlpha(){
        //Bubble Sort (easy to write)
        if membersList.count != 0 {
            var thereWasASwap = true
            while thereWasASwap {
                thereWasASwap = false
                for i in 0..<membersList.count-1 {
                    let name1: String = membersNamesList[i]
                    let name2: String = membersNamesList[i+1]
                    
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
                            let temp = membersNamesList[i]
                            membersNamesList[i] = membersNamesList[i+1]
                            membersNamesList[i+1] = temp
                            
                            let temp2 = membersList[i]
                            membersList[i] = membersList[i+1]
                            membersList[i+1] = temp2
                            
                            let temp3 = membersPics[i]
                            membersPics[i] = membersPics[i+1]
                            membersPics[i+1] = temp3
                            
                            let temp4 = membersEmailsList[i]
                            membersEmailsList[i] = membersEmailsList[i+1]
                            membersEmailsList[i+1] = temp4
                            
                            let temp5 = membersMsgList[i]
                            membersMsgList[i] = membersMsgList[i+1]
                            membersMsgList[i+1] = temp5
                            
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
        
        if adminsList.count != 0 {
            var thereWasASwap = true
            while thereWasASwap {
                thereWasASwap = false
                for i in 0..<adminsList.count-1 {
                    let name1: String = adminsNamesList[i]
                    let name2: String = adminsNamesList[i+1]
                    
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
                            let temp = adminsNamesList[i]
                            adminsNamesList[i] = adminsNamesList[i+1]
                            adminsNamesList[i+1] = temp
                            
                            let temp2 = adminsList[i]
                            adminsList[i] = adminsList[i+1]
                            adminsList[i+1] = temp2
                            
                            let temp3 = adminsPics[i]
                            adminsPics[i] = adminsPics[i+1]
                            adminsPics[i+1] = temp3
                            
                            let temp4 = adminsEmailsList[i]
                            adminsEmailsList[i] = adminsEmailsList[i+1]
                            adminsEmailsList[i+1] = temp4
                            
                            let temp5 = adminsMsgList[i]
                            adminsMsgList[i] = adminsMsgList[i+1]
                            adminsMsgList[i+1] = temp5
                            
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
        self.adminsCollectionView.reloadData()
        self.membersCollectionView.reloadData()
    }
    
    //***********************THE ADMIN LIST*********************
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
                    clubRef.updateData(["admins": FieldValue.arrayRemove([self.adminsList[indexPath.item]])])
                    
                    //Update user stuff
                    let userRef = self.db.collection("users").document(self.adminsList[indexPath.item])
                    userRef.updateData([
                        "clubs": FieldValue.arrayRemove([self.clubID]),
                        "notifications": FieldValue.arrayRemove([self.clubID]),
                        "badges": FieldValue.arrayRemove([self.clubBadge])
                    ])
                    
                    let msgToken = self.adminsMsgList[indexPath.item]
                    self.functions.httpsCallable("manageSubscriptions").call(["registrationTokens": [msgToken], "isSubscribing": false, "clubID": self.clubID]) { (result, error) in
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
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                        self.getClubData()
                    })
                }
                alert.addAction(confirmAction)
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            }))
            actionSheet.addAction(UIAlertAction(title: "Demote to Member", style: .default, handler: { (action:UIAlertAction) in
                //Create the alert controller.
                let alert = UIAlertController(title: "Confirmation", message: "Are you sure you want to demote \(self.adminsNamesList[indexPath.item])?", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil)
                let confirmAction = UIAlertAction(title: "Confirm", style: UIAlertAction.Style.destructive) { (action:UIAlertAction) in
                    self.promotedAMember!(true)
                    let clubRef = self.db.collection("clubs").document(self.clubID)
                    clubRef.updateData(["members": FieldValue.arrayUnion([self.adminsList[indexPath.item]])])
                    clubRef.updateData(["admins": FieldValue.arrayRemove([self.adminsList[indexPath.item]])])
                    
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
    
    
    //**********************THE MEMBER LIST*********************
    @objc func handleLongPress(gestureRecognizer : UILongPressGestureRecognizer){
        if (gestureRecognizer.state != UIGestureRecognizer.State.began){
            return
        }
        let p = gestureRecognizer.location(in: self.membersCollectionView)
        if let indexPath : NSIndexPath = (self.membersCollectionView.indexPathForItem(at: p) as NSIndexPath?){
            let actionSheet = UIAlertController(title: "Choose an Option for \(membersNamesList[indexPath.item])", message: nil, preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Promote to Admin", style: .default, handler: { (action:UIAlertAction) in
                //Create the alert controller.
                let alert = UIAlertController(title: "Confirmation", message: "Are you sure you want to promote \(self.membersNamesList[indexPath.item])? (They will have as much power as you do right now!)", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil)
                let confirmAction = UIAlertAction(title: "Confirm", style: UIAlertAction.Style.default) { (action:UIAlertAction) in
                    self.promotedAMember!(true)
                    let clubRef = self.db.collection("clubs").document(self.clubID)
                    clubRef.updateData(["members": FieldValue.arrayRemove([self.membersList[indexPath.item]])])
                    clubRef.updateData(["admins": FieldValue.arrayUnion([self.membersList[indexPath.item]])])
                    
                    let msgToken = self.membersMsgList[indexPath.item]
                    self.functions.httpsCallable("sendToUser").call(["token": msgToken, "title": "You're Now An Admin!", "body": "Congratulations, you're now an Admin of \(self.clubName)!"]) { (result, error) in
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
                    clubRef.updateData(["members": FieldValue.arrayRemove([self.membersList[indexPath.item]])])
                    
                    //update the user
                    let userRef = self.db.collection("users").document(self.membersList[indexPath.item])
                    userRef.updateData([
                        "clubs": FieldValue.arrayRemove([self.clubID]),
                        "notifications": FieldValue.arrayRemove([self.clubID]),
                        "badges": FieldValue.arrayRemove([self.clubBadge])
                    ])
                    
                    self.functions.httpsCallable("manageSubscriptions").call(["registrationTokens": [self.membersMsgList[indexPath.item]], "isSubscribing": false, "clubID": self.clubID]) { (result, error) in
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
                        print("Email sent to admins")
                        print("Result is: \(String(describing: result?.data))")
                    }
                    
                    //take them points
//                    self.db.runTransaction({ (transaction, errorPointer) -> Any? in
//                        let uDoc: DocumentSnapshot
//                        do {
//                            try uDoc = transaction.getDocument(userRef)
//                        } catch let fetchError as NSError {
//                            errorPointer?.pointee = fetchError
//                            return nil
//                        }
//
//                        guard let oldPoints = uDoc.data()?["points"] as? Int else {
//                            let error = NSError(
//                                domain: "AppErrorDomain",
//                                code: -1,
//                                userInfo: [
//                                    NSLocalizedDescriptionKey: "Unable to retrieve points from snapshot \(uDoc)"
//                                ]
//                            )
//                            errorPointer?.pointee = error
//                            return nil
//                        }
//                        transaction.updateData(["points": oldPoints - Defaults.joiningClub], forDocument: userRef)
//                        return nil
//                    }, completion: { (object, err) in
//                        if let error = err {
//                            print("Transaction failed: \(error)")
//                            let ac = UIAlertController(title: "Could not give points to user", message: "Error: \(error.localizedDescription)", preferredStyle: .alert)
//                            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//                            self.present(ac, animated: true)
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
//                                self.getClubData()
//                            })
//                        } else {
//                            print("Transaction successfully committed!")
//
//                            //Take the grade points
//                            let gradYear = Int(self.membersEmailsList[indexPath.item].suffix(14).prefix(2)) ?? 0
//                            let pointRef = self.db.collection("info").document("spiritPoints")
//                            self.db.runTransaction({ (transaction, errorPointer) -> Any? in
//                                let pDoc: DocumentSnapshot
//                                do {
//                                    try pDoc = transaction.getDocument(pointRef)
//                                } catch let fetchError as NSError {
//                                    errorPointer?.pointee = fetchError
//                                    return nil
//                                }
//                                guard let oldPoints = pDoc.data()?[String(gradYear)] as? Int else {
//                                    let error = NSError(
//                                        domain: "AppErrorDomain",
//                                        code: -1,
//                                        userInfo: [
//                                            NSLocalizedDescriptionKey: "Unable to retrieve points from snapshot \(pDoc)"
//                                        ]
//                                    )
//                                    errorPointer?.pointee = error
//                                    return nil
//                                }
//                                transaction.updateData([String(gradYear): oldPoints - Defaults.joiningClub], forDocument: pointRef)
//                                return nil
//                            }, completion: { (object, err) in
//                                if let error = err {
//                                    print("Transaction failed: \(error)")
//                                    let ac = UIAlertController(title: "Transaction Error: Grad - \(gradYear)", message: "Error: \(error.localizedDescription)", preferredStyle: .alert)
//                                    ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//                                    self.present(ac, animated: true)
//                                } else {
//                                    print("Transaction successfully committed!")
//                                    print("successfuly gave badge")
//                                }
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
//                                    self.getClubData()
//                                })
//                            })
//                        }
//                    })
                    
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
        print(adminsNamesList)
        print(membersNamesList)
        if collectionView == adminsCollectionView {
            return adminsNamesList.count
        } else {
            return membersNamesList.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let height = self.adminsCollectionView.contentSize.height + self.membersCollectionView.contentSize.height + 150
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
        var userToSegTo = ""
        if collectionView == adminsCollectionView {
            userToSegTo = adminsList[indexPath.item]
        } else {
            userToSegTo = membersList[indexPath.item]
        }
        print(userToSegTo)
        
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
                        if let savedImage = self.getSavedImage(named: "\(profPic)=\(updated)"){
                            print("already saved \(profPic)=\(updated)")
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
}
