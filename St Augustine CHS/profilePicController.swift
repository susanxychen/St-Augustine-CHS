//
//  profilePicController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-12-02.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit
import Firebase

class profilePicController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    //Database Variables
    var db: Firestore!
    var docRef: DocumentReference!
    
    //UI Elements
    @IBOutlet weak var updateButton: UIButton!
    
    @IBOutlet weak var theProfilePic: UIImageView!
    @IBOutlet weak var pointsLabel: UILabel!
    
    @IBOutlet weak var ownedCollectionView: UICollectionView!
    @IBOutlet weak var notOwnedCollectionView: UICollectionView!
    
    var fillerImage = UIImage(named: "blankUser")!
    
    //Data vars
    var thePicImage: UIImage!
    var picsCosts = [Int]()
    
    var picsOwned = [UIImage]()
    var picsOwnedNums = [Int]()
    
    var picsNotOwned = [UIImage]()
    var picsNotOwnedNums = [Int]()
    
    var newPicChosen = allUserFirebaseData.data["profilePic"] as! Int
    
    //Refresh Vars
    let actInd: UIActivityIndicatorView = UIActivityIndicatorView()
    let container: UIView = UIView()
    let overlayView = UIView(frame: UIScreen.main.bounds)
    
    var choseNewPic = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overlayView.frame = UIApplication.shared.keyWindow!.frame
        
        //***************INTERNET CONNECTION**************
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
                        self.updateButton.isEnabled = false
                    }
                }
            }
        })
        
        //Set Up Firebase
        // [START setup]
        let settings = FirestoreSettings()
        settings.areTimestampsInSnapshotsEnabled = true
        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
        //Set up the current profile image
        theProfilePic.image = thePicImage
        theProfilePic.layer.borderWidth = 3.0
        theProfilePic.layer.masksToBounds = false
        theProfilePic.layer.borderColor = UIColor.white.cgColor
        theProfilePic.layer.cornerRadius = 200/2
        theProfilePic.clipsToBounds = true
        
        //Always bounce
        ownedCollectionView.alwaysBounceHorizontal = true
        notOwnedCollectionView.alwaysBounceHorizontal = true
        
        getPicsCost()
    }
    
    func getPicsCost() {
        picsNotOwnedNums.removeAll()
        picsNotOwned.removeAll()
        picsOwnedNums.removeAll()
        picsOwned.removeAll()
        
        showActivityIndicatory(uiView: self.view, container: container, actInd: actInd, overlayView: overlayView)
        db.collection("info").document("profilePics").getDocument { (snapshot, error) in
            if let error = error {
                print(error)
                let alert = UIAlertController(title: "Error in getting profile pictures", message: "Error: \(error.localizedDescription)", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
                self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
            }
            if let data = snapshot?.data() {
                self.picsCosts = data["costs"] as! [Int]
                self.getAllPics()
            }
        }
    }
    
    func getAllPics() {
        //Get the profile pictures
        self.picsNotOwned = [UIImage](repeating: self.fillerImage, count: picsCosts.count)
        
        //Just for safety get out of here to prevent going from 0 to -1
        if picsNotOwned.count == 0 {
            let alert = UIAlertController(title: "Error in getting profile pictures", message: "Try again later", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
            return
        }
        
        for i in 0...self.picsCosts.count-1 {
            //Set up the pics not owned num array
            picsNotOwnedNums.append(i)
            
            let storage = Storage.storage()
            let storageRef = storage.reference()
            
            // Create a reference to the file you want to download
            let imgRef = storageRef.child("profilePictures/\(i).png")
            
            imgRef.getMetadata { (metadata, error) in
                if let error = error {
                    // Uh-oh, an error occurred!
                    print("cant find image \(i)")
                    print(error)
                } else {
                    if let metadata = metadata {
                        let theMetaData = metadata.dictionaryRepresentation()
                        let updated = theMetaData["updated"]
                        
                        if let updated = updated {
                            if let savedImage = self.getSavedImage(named: "\(i)-\(updated)"){
                                print("already saved \(i)-\(updated)")
                                self.picsNotOwned[i] = savedImage
                                //print(self.picsNotOwned)
                            } else {
                                // Create a reference to the file you want to download
                                imgRef.downloadURL { url, error in
                                    if error != nil {
                                        //print(error)
                                        print("cant find image \(i) + \(self.picsNotOwned[i])")
                                        self.picsNotOwned[i] = self.fillerImage
                                    } else {
                                        // Get the download URL
                                        var image: UIImage?
                                        let data = try? Data(contentsOf: url!)
                                        if let imageData = data {
                                            image = UIImage(data: imageData)!
                                            self.picsNotOwned[i] = image!
                                            self.clearImageFolder(imageName: "\(i)-\(updated)")
                                            self.saveImageDocumentDirectory(image: image!, imageName: "\(i)-\(updated)")
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            print("hey i am done getting imgs now format them")
            self.formatThePics()
        }
    }
    
    func formatThePics() {
        //Split the pics between owned and not owned
        let user = Auth.auth().currentUser
        db.collection("users").document((user?.uid)!).getDocument { (snapshot, error) in
            if let error = error {
                print(error)
                let alert = UIAlertController(title: "Error in getting profile pictures", message: "Error: \(error.localizedDescription)", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
                self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
            }
            if let data = snapshot?.data() {
                allUserFirebaseData.data = data
                self.picsOwnedNums = allUserFirebaseData.data["picsOwned"] as! [Int]
                self.pointsLabel.text = "Points: \(allUserFirebaseData.data["points"]!)"
                
                self.picsOwnedNums.sort()
                print(self.picsOwnedNums)
                
                var counter = 0
                //Get all profile pics owned
                for i in 0...self.picsNotOwned.count-1 {
                    //If the current pic number matches a value in the pics owned Nums array, then append an image to the picsOwned UIImage Array
                    if i == self.picsOwnedNums[counter] {
                        self.picsOwned.append(self.picsNotOwned[i])
                        
                        //Check to see if we have reached the end of picsOwnedNums
                        if counter < self.picsOwnedNums.count-1 {
                            counter += 1
                        } else {
                            break
                        }
                    }
                }
                
                //Findally remove the pics that you already own from picsNotOwned
                self.picsNotOwned.remove(at: self.picsOwnedNums)
                self.picsNotOwnedNums.remove(at: self.picsOwnedNums)
                
                //Finish up
                print("done formatting")
                self.ownedCollectionView.reloadData()
                self.notOwnedCollectionView.reloadData()
                self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
            }
        }
    }
    
    //************TOP BAR STUFF************
    @IBAction func cancelAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func updateAction(_ sender: Any) {
        //***************INTERNET CONNECTION**************
        var iAmConneted = false
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if let connected = snapshot.value as? Bool, connected {
                print("Connected")
                iAmConneted = true
                
                print("wow update: \(self.newPicChosen)")
                if self.choseNewPic {
                    self.showActivityIndicatory(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                    let userRef = self.db.collection("users").document((Auth.auth().currentUser?.uid)!)
                    userRef.setData([
                        "profilePic" : self.newPicChosen,
                    ], mergeFields: ["profilePic"]) { (err) in
                        if let err = err {
                            let alert = UIAlertController(title: "Error in updating profile picture", message: "Error: \(err.localizedDescription)", preferredStyle: .alert)
                            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                            alert.addAction(okAction)
                            self.present(alert, animated: true, completion: nil)
                            self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                        } else {
                            print("Document successfully updated")
                            allUserFirebaseData.profilePic = self.theProfilePic.image!
                            let user = Auth.auth().currentUser
                            self.db.collection("users").document((user?.uid)!).getDocument { (docSnapshot, err) in
                                if let docSnapshot = docSnapshot {
                                    allUserFirebaseData.data = docSnapshot.data()!
                                    self.dismiss(animated: true, completion: nil)
                                }
                                if let err = err {
                                    let alert = UIAlertController(title: "Error in updating profile picture", message: "Error: \(err.localizedDescription)", preferredStyle: .alert)
                                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                    alert.addAction(okAction)
                                    self.present(alert, animated: true, completion: nil)
                                    self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                                }
                            }
                        }
                    }
                } else {
                    self.dismiss(animated: true, completion: nil)
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
                        self.updateButton.isEnabled = false
                    }
                }
            }
        })
    }
    
    //*************************************FORMATTING THE PROFILES*************************************
    //RETURN CLUB COUNT announcement
    //Make sure when you add collection view you add data source and delegate connections on storyboard
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //print("i do get run club list")
        if collectionView == ownedCollectionView {
            return picsOwned.count
        } else {
            return picsNotOwned.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == ownedCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "profilePic", for: indexPath) as! picsOwnedViewCell
            
            //Round the image
            cell.pic.layer.cornerRadius = 100/2
            cell.pic.clipsToBounds = true
            cell.pic.image = nil
            cell.pic.image = picsOwned[indexPath.item]
            
            return cell
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "profilePicNot", for: indexPath) as! picsNotOwnedViewCell
            
            //Round the image
            cell.pic.layer.cornerRadius = 100/2
            cell.pic.clipsToBounds = true
            cell.pic.image = nil
            cell.pic.image = picsNotOwned[indexPath.item]
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == ownedCollectionView {
            choseNewPic = true
            theProfilePic.image = picsOwned[indexPath.item]
            newPicChosen = picsOwnedNums[indexPath.item]
            print("you switched to \(newPicChosen)")
        }
        else {
            print("\(indexPath.item) you want to buy \(picsNotOwnedNums[indexPath.item])")
            if allUserFirebaseData.data["points"] as! Int >= picsCosts[picsNotOwnedNums[indexPath.item]] {
                //Set up the alert controller
                let alertController = UIAlertController(title: "Confirmation", message: "Are you sure you want to purchase this picture for \(picsCosts[picsNotOwnedNums[indexPath.item]]) points?", preferredStyle: .alert)
                
                //Add the image
                let image = picsNotOwned[indexPath.item]
                alertController.addImage(image: image)
                
                //Add the cancel
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                //Add the confirm button
                alertController.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
                    print("wow u confirmed")
                    
                    self.choseNewPic = true
                    self.newPicChosen = self.picsNotOwnedNums[indexPath.item]
                    self.theProfilePic.image = self.picsNotOwned[indexPath.item]
                    
                    //Reload all data
                    self.showActivityIndicatory(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                    
                    //Update the picsOwned array
                    let userRef = self.db.collection("users").document((Auth.auth().currentUser?.uid)!)
                    userRef.updateData(["picsOwned": FieldValue.arrayUnion([self.newPicChosen])])
                    
                    //Subtact the points
                    allUserFirebaseData.data["points"] = allUserFirebaseData.data["points"] as! Int - self.picsCosts[self.picsNotOwnedNums[indexPath.item]]
                    userRef.setData([
                        "profilePic" : self.newPicChosen,
                        "points" : allUserFirebaseData.data["points"] as! Int
                    ], mergeFields: ["profilePic", "points"]) { (err) in
                        if let err = err {
                            let alert = UIAlertController(title: "Error in updating profile picture", message: "Error: \(err.localizedDescription)", preferredStyle: .alert)
                            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                            alert.addAction(okAction)
                            self.present(alert, animated: true, completion: nil)
                            self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                        } else {
                            print("Document successfully updated")
                            allUserFirebaseData.profilePic = self.theProfilePic.image!
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
                                //self.dismiss(animated: true, completion: nil)
                                self.getPicsCost() //why tf is the images out of order
                            }
                        }
                    }
                }))
                
                self.present(alertController, animated: true, completion: nil)
            } else {
                //Set up the alert controller
                let alertController = UIAlertController(title: "Error", message: "You do not have enough points for this picture. Cost: \(picsCosts[picsNotOwnedNums[indexPath.item]]) points", preferredStyle: .alert)
                
                //Add the image
                let image = picsNotOwned[indexPath.item]
                alertController.addImage(image: image)
                
                //Add the cancel
                alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
}
