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
    
    var clubID: String!
    var pendingList = [String]()
    var pendingListNames = [String]()
    
    @IBOutlet weak var pendingListCollectionView: UICollectionView!
    
    //Refresh Variables
    var refreshControl: UIRefreshControl?
    let actInd: UIActivityIndicatorView = UIActivityIndicatorView()
    let container: UIView = UIView()
    let overlayView = UIView(frame: UIApplication.shared.keyWindow!.frame)
    
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
                let clubRef = self.db.collection("clubs").document(self.clubID)
                clubRef.updateData([
                    "pending": FieldValue.arrayRemove([self.pendingList[indexPath.item]])
                ])
                clubRef.updateData([
                    "members": FieldValue.arrayUnion([self.pendingList[indexPath.item]])
                ])
                let userRef = self.db.collection("users").document(self.pendingList[indexPath.item])
                userRef.updateData([
                    "clubs": FieldValue.arrayUnion([self.clubID])
                ])
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                    self.getClubData()
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
        pendingListNames.removeAll()
        self.showActivityIndicatory(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
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
        self.showActivityIndicatory(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
        for _ in pendingList {
            pendingListNames.append("")
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
                    let data = snap.data()!
                    //self.pendingListNames.append(data?["name"] as? String ?? "Error")
                    self.pendingListNames[user] = data["name"] as? String ?? "error"
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
            self.pendingListCollectionView.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pendingListNames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "name", for: indexPath) as! pendingListCell
        cell.nameLabel.text = pendingListNames[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(indexPath.item)
    }
    
}
