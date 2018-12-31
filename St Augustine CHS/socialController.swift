//
//  socialController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-11-05.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit
import Firebase
import Crashlytics

class socialController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    //User Data
    var userData = [String:Any]()
    var userCourses = [String]()
    var userClubNames = [String]()
    var userClubData = [[String:Any]]()
    var userClubIDs = [String]()
    var chosenToShareClasses = false
    var chosenToShareClubs = false
    var theOtherPersonsClasses = [String]()
    
    //Other Person's Data
    var numOfSameCourses = 0
    var lookingAtOtherUserInGeneral = false
    
    //Database Variables
    var db: Firestore!
    var docRef: DocumentReference!
    
    //Search Controls
    @IBOutlet weak var searchBarView: UIView!
    @IBOutlet weak var searchBar: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    
    //Profile and User Data
    @IBOutlet weak var profileViewBackground: UIView!
    @IBOutlet weak var profilePictureView: UIView!
    @IBOutlet weak var profilePictureButton: UIButton!
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var usersFullName: UILabel!
    @IBOutlet weak var classesInCommon: UIButton!
    
    //Badges
    @IBOutlet weak var badgesCollectionView: UICollectionView!
    @IBOutlet weak var badgeCollectionViewHeight: NSLayoutConstraint!
    let badgeCollectionIdentifier = "badge"
    var badgeData = [[String: Any]]()
    var badgeImgs = [UIImage]()
    
    //Clubs
    @IBOutlet weak var clubsCollectionView: UICollectionView!
    @IBOutlet weak var clubCollectionViewHeight: NSLayoutConstraint!
    let clubCollectionIdentifier = "club"
    
    //Segue Data
    @IBOutlet weak var showClassesButton: UIButton!
    @IBOutlet weak var showClubButton: UIButton!
    @IBOutlet weak var showProfilePics: UIButton!
    var segDest = 0
    
    //Refresh Vars
    let actInd: UIActivityIndicatorView = UIActivityIndicatorView()
    let container: UIView = UIView()
    let overlayView = UIView(frame: UIScreen.main.bounds)
    var forceRefresh = false
    
    //Filler Data
    var fillerImage = UIImage(named: "blankUser")
    
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
                        let alert = UIAlertController(title: "Error", message: "You are not connected to the internet. Any data will be loaded from cache.", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
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
        
        let user = Auth.auth().currentUser
        //Profile Pic
        //let url = user?.photoURL
        //let data = try? Data(contentsOf: url!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
        
        //Hide the keyboard when the user taps away from the keyboard
        hideKeyboardWhenTappedAround()
        
        //*************************SET UP THE USER PROFILE DATA*************************
        if allUserFirebaseData.data["status"] as! Int == 2 {
            self.profileViewBackground.backgroundColor = UIColor(red: 25/255.0, green: 2/255.0, blue: 6/255.0, alpha: 1.0)
            self.usersFullName.textColor = UIColor(red: 216/255.0, green: 175/255.0, blue: 28/255.0, alpha: 1.0)
        } else {
            self.profileViewBackground.backgroundColor = UIColor(red: 141/255.0, green: 18/255.0, blue: 48/255.0, alpha: 1.0)
        }
        
        //Background Shadow
        profileViewBackground.layer.shadowOpacity = 1
        profileViewBackground.layer.shadowRadius = 2
        
        profilePictureView.bringSubviewToFront(profilePictureButton)
        
        //Profile Picture
        profilePicture.layer.borderWidth = 1.0
        profilePicture.layer.masksToBounds = false
        profilePicture.layer.borderColor = UIColor.white.cgColor
        profilePicture.layer.cornerRadius = 130/2
        profilePicture.clipsToBounds = true
        
        //Person's Name
        usersFullName.text = user?.displayName
        
        lookingAtOtherUserInGeneral = false
        
        //**********Classes in Common**********
        //Check if the user wants to display classes
        classesInCommon.setTitle("View Your Schedule", for: .normal)
        getCurrentUsersData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !lookingAtOtherUserInGeneral {
            profilePicture.image = allUserFirebaseData.profilePic
        }
    }
    
    func getCurrentUsersData(){
        profilePicture.image = allUserFirebaseData.profilePic
        //Get the preexisting data from the menu controller
        if allUserFirebaseData.data.count != 0 && !forceRefresh {
            self.userData = allUserFirebaseData.data
            self.getBadgeDocs(theData: allUserFirebaseData.data)
            self.userCourses = allUserFirebaseData.data["classes"] as! [String]
            let clubIDRefs = allUserFirebaseData.data["clubs"] as! [String]
            self.getClubData(clubIDRefs: clubIDRefs)
        } else {
            //Get new current user data (not ever needed for now)
            let user = Auth.auth().currentUser
            db.collection("users").document((user?.uid)!).getDocument { (docSnapshot, err) in
                if let docSnapshot = docSnapshot {
                    self.userData = docSnapshot.data()!
                    self.getBadgeDocs(theData: allUserFirebaseData.data)
                    self.userCourses = self.userData["classes"] as! [String]
                    let clubIDRefs = self.userData["clubs"] as! [String]
                    self.getClubData(clubIDRefs: clubIDRefs)
                } else {
                    print("wow u dont exist")
                }
            }
        }
    }
    
    func getBadgeDocs(theData: [String:Any]){
        badgeData.removeAll()
        badgeImgs.removeAll()
        if (theData["badges"] as! [String]).count == 0 {
            badgeCollectionViewHeight.constant = 0
            badgesCollectionView.reloadData()
            return
        } else {
            badgeCollectionViewHeight.constant = 133
        }
        for _ in theData["badges"] as! [String] {
            badgeData.append(["err":"err"])
        }
        for x in 0...(theData["badges"] as! [String]).count - 1 {
            let id = (theData["badges"] as! [String])[x]
            db.collection("badges").document(id).getDocument { (snap, err) in
                if let err = err {
                    let alert = UIAlertController(title: "Error in retrieveing some club images", message: "Please try again later. \(err.localizedDescription)", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                }
                if let snap = snap {
                    self.badgeData[x] = snap.data()!
                }
                
                if x == (theData["badges"] as! [String]).count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
                        self.getBadgesImages()
                    }
                }
            }
        }
    }
    
    func getBadgesImages() {
        for _ in badgeData {
            badgeImgs.append(UIImage())
        }
        for i in 0...badgeImgs.count - 1 {
            let name = badgeData[i]["img"] as? String ?? "Error"
            //Image
            let storage = Storage.storage()
            let storageRef = storage.reference()
            
            // Create a reference to the file you want to download
            let imgRef = storageRef.child("badges/\(name)")
            
            imgRef.getMetadata { (metadata, error) in
                if let error = error {
                    // Uh-oh, an error occurred!
                    print("cant find image \(name)")
                    print(error)
                } else {
                    // Metadata now contains the metadata for 'images/forest.jpg'
                    if let metadata = metadata {
                        let theMetaData = metadata.dictionaryRepresentation()
                        let updated = theMetaData["updated"]
                        
                        if let updated = updated {
                            if let savedImage = self.getSavedImage(named: "\(name)-\(updated)"){
                                print("already saved \(name)-\(updated)")
                                self.badgeImgs[i] = savedImage
                            } else {
                                // Create a reference to the file you want to download
                                imgRef.downloadURL { url, error in
                                    if error != nil {
                                        //print(error)
                                        print("cant find image \(name)")
                                    } else {
                                        // Get the download URL
                                        var image: UIImage?
                                        let data = try? Data(contentsOf: url!)
                                        if let imageData = data {
                                            image = UIImage(data: imageData)!
                                            self.badgeImgs[i] = image!
                                            self.clearImageFolder(imageName: "\(name)-\(updated)")
                                            self.saveImageDocumentDirectory(image: image!, imageName: "\(name)-\(updated)")
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
            self.badgesCollectionView.reloadData()
        }
    }
    
    func getPicture(i: Int) {
        //Image
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
                // Metadata now contains the metadata for 'images/forest.jpg'
                if let metadata = metadata {
                    let theMetaData = metadata.dictionaryRepresentation()
                    let updated = theMetaData["updated"]
                    
                    if let updated = updated {
                        if let savedImage = self.getSavedImage(named: "\(i)-\(updated)"){
                            print("already saved \(i)-\(updated)")
                            self.profilePicture.image = savedImage
                        } else {
                            // Create a reference to the file you want to download
                            imgRef.downloadURL { url, error in
                                if error != nil {
                                    //print(error)
                                    print("cant find image \(i)")
                                    self.profilePicture.image = self.fillerImage
                                } else {
                                    // Get the download URL
                                    var image: UIImage?
                                    let data = try? Data(contentsOf: url!)
                                    if let imageData = data {
                                        image = UIImage(data: imageData)!
                                        self.profilePicture.image = image!
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
    
    //************************************GET CLUB DATA FUNCTION************************************
    func getClubData(clubIDRefs: [String]) {
        userClubData.removeAll()
        userClubIDs.removeAll()
        userClubNames.removeAll()
        print("The club IDs: \(clubIDRefs)")
        
        //Show the Club labels
        if clubIDRefs.count != 0 {
            for i in 0...clubIDRefs.count-1 {
                let docRef = self.db.collection("clubs").document(clubIDRefs[i])
                docRef.getDocument { (document, error) in
                    //There was an error somewhere
                    if let error = error {
                        print("Oh noes error getting club data: \(error)")
                        let alert = UIAlertController(title: "Error in retrieveing Clubs", message: "Please Try Again later. Error: \(error.localizedDescription)", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                        self.clubsCollectionView.reloadData()
                    }
                    
                    //Get the Club
                    if let document = document, document.exists {
                        self.userClubData.append(document.data()!)
                        //Also keep all the doucment ids
                        self.userClubIDs.append(document.documentID)
                        
                        //Set the names of clubs
                        let clubData = document.data()
                        let clubName = clubData!["name"]
                        print(clubName as Any)
                        self.userClubNames.append(clubName as! String)
                    } else {
                        print("Document does not exist")
                    }
                    
                    //Reload the Data when done
                    if i == clubIDRefs.count-1{
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                            print(self.userClubIDs)
                            self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                            self.clubCollectionViewHeight.constant = 275
                            self.clubsCollectionView.reloadData()
                        }
                    }
                }
            }
        } else {
            clubCollectionViewHeight.constant = 0
            self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
            clubsCollectionView.reloadData()
        }
    }
    
    //**********************************SEARCHING FOR A USER**********************************
    @IBAction func userHitSearchButton(_ sender: Any) {
        searchForUser()
    }
    @IBAction func userHitEnterOnSearchBar(_ sender: Any) {
        searchForUser()
    }
    
    func searchForUser(){
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
                    }
                }
            }
        })
        
        //***************SEARCH FOR USER**************
        if var userInput = searchBar.text{
            //Nothing is entered
            if userInput == "" {
                return
            }
            
            //Turn all cases to lower
            userInput = userInput.lowercased()
                
            if userInput == "theclearingwantsyou" {
                print("The clearing")
                Crashlytics.sharedInstance().crash()
            }
            
            //*****If the user did not add @ycdsbk12 just add it for them******
            if !userInput.hasSuffix("@ycdsbk12.ca") {
                userInput = userInput + "@ycdsbk12.ca"
            }
            
            //If the user input themselves...silly user
            if userInput == Auth.auth().currentUser?.email {
                let alert = UIAlertController(title: "Well", message: "You just searched for yourself?", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Yes I did", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            } else {
                self.showActivityIndicatory(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                //Search the database
                db.collection("users").whereField("email", isEqualTo: userInput).getDocuments { (querySnapshot, err) in
                    if let err = err {
                        let alert = UIAlertController(title: "Error finding user", message: "Error: \(err.localizedDescription)", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                        print("error in getting doucments: \(err)")
                        self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                    } else {
                        //Query Snapshot [] is empty if nothing in the database matches what the user typed in
                        if querySnapshot!.documents.count == 0 {
                            let alert = UIAlertController(title: "No user found named \(userInput)", message: "Check spelling!", preferredStyle: .alert)
                            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                            alert.addAction(okAction)
                            self.present(alert, animated: true, completion: nil)
                            self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                        }
                        for document in querySnapshot!.documents{
                            //Check if there is no possible user
                            if document.exists{
                                self.lookingAtOtherUserInGeneral = true
                                
                                let requestedStudentData = document.data()
                                
                                if requestedStudentData["status"] as! Int == 2 {
                                    self.profileViewBackground.backgroundColor = UIColor(red: 25/255.0, green: 2/255.0, blue: 6/255.0, alpha: 1.0)
                                    self.usersFullName.textColor = UIColor(red: 216/255.0, green: 175/255.0, blue: 28/255.0, alpha: 1.0)
                                } else {
                                    self.profileViewBackground.backgroundColor = UIColor(red: 141/255.0, green: 18/255.0, blue: 48/255.0, alpha: 1.0)
                                }
                                
                                //Get the requested stuends information
                                //Image
                                self.getPicture(i: requestedStudentData["profilePic"] as? Int ?? 0)
                                
                                //Name
                                self.usersFullName.text = requestedStudentData["name"] as? String ?? "Error Occured"
                                
                                //Badges
                                self.getBadgeDocs(theData: requestedStudentData)
                                
                                //Classes
                                if requestedStudentData["showClasses"] as! Bool {
                                    self.chosenToShareClasses = true
                                    
                                    //Classes in common
                                    self.theOtherPersonsClasses = requestedStudentData["classes"] as! [String]

                                    //Fail safe just incase the courses aren't 8
                                    if self.theOtherPersonsClasses.count != 8{
                                        print("oh shit we have to fix")
                                        self.theOtherPersonsClasses = ["hey","something","went","wrong","here","courses","got","error"]
                                    }
                                    
                                    //Fail safe just incase the courses aren't 8
                                    if self.userCourses.count != 8{
                                        print("oh shit we have to fix")
                                        self.userCourses = ["hey","something","went","wrong","here","courses","got","error"]
                                    }
                                    
                                    //Day 1 Only uploaded
                                    self.numOfSameCourses = 0
                                    for i in 0...self.userCourses.count - 1 {
                                        if self.theOtherPersonsClasses[i] == self.userCourses[i] {
                                            self.numOfSameCourses += 1
                                        }
                                    }
                                    
                                    self.classesInCommon.setTitle("\(self.numOfSameCourses) classes in common", for: .normal)
                                    self.classesInCommon.isUserInteractionEnabled = true
                                } else {
                                    self.classesInCommon.isUserInteractionEnabled = false
                                    self.classesInCommon.setTitle("Student has chosen not to share classes", for: .normal)
                                    self.chosenToShareClasses = false
                                }
                                
                                //Clubs
                                if requestedStudentData["showClubs"] as! Bool {
                                    let clubIDRefs = requestedStudentData["clubs"] as! [String]
                                    self.clubsCollectionView.isUserInteractionEnabled = true
                                    self.getClubData(clubIDRefs: clubIDRefs)
                                } else {
                                    self.clubsCollectionView.isUserInteractionEnabled = false
                                    self.userClubNames = ["Student has chosen not to share clubs"]
                                    self.userClubIDs = ["nice"]
                                    self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                                    self.clubsCollectionView.reloadData()
                                }
                                
                            } else {
                                let alert = UIAlertController(title: "This user cannot be found", message: "Try again later", preferredStyle: .alert)
                                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                alert.addAction(okAction)
                                self.present(alert, animated: true, completion: nil)
                                self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func coursesInCommonPressed(_ sender: Any) {
        print("u want to look at other persons courses \(self.theOtherPersonsClasses)")
        segDest = 0
        if !lookingAtOtherUserInGeneral {
            theOtherPersonsClasses = userCourses
        }
        performSegue(withIdentifier: "showClasses", sender: showClassesButton)
    }
    
    var counterBecauseOnlyRunOnce = 0
    //****************************FORMATTING THE COLLECTION VIEWS****************************
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == badgesCollectionView {
            return badgeImgs.count
        } else {
            return userClubNames.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //**********************FORMAT THE BADGES**********************
        if collectionView == badgesCollectionView {
            let badgesCell = collectionView.dequeueReusableCell(withReuseIdentifier: badgeCollectionIdentifier, for: indexPath) as! badgesViewCell
            
            //Round the badge image
            badgesCell.theBadge.layer.cornerRadius = 130/2
            badgesCell.theBadge.clipsToBounds = true
            
            badgesCell.theBadge.image = badgeImgs[indexPath.item]
            
            return badgesCell
        }
        
        //**********************FORMAT THE CLUBS**********************
        else {
            let clubsCell = collectionView.dequeueReusableCell(withReuseIdentifier: clubCollectionIdentifier, for: indexPath) as! socialClubsViewCell
            //This if is just to ENSURE that there will NEVER be an array out of bounds exception
            clubsCell.clubName.text = userClubNames[indexPath.item]
            
            //Makes it look prettier
            if clubsCollectionView.contentSize.height < 275 {
                clubCollectionViewHeight.constant = clubsCollectionView.contentSize.height
            } else {
                clubCollectionViewHeight.constant = 275
            }
            
            return clubsCell
        }
    }
    
    var clubData = [String:Any]()
    var clubID: String!
    var clubImage: UIImage!
    var partOfClub: Bool!
    //**********************SELECTING A BADGE OR CLUB**********************
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == badgesCollectionView {
            print("badges \(badgeData[indexPath.item])")
        } else {
            print("clubs \(indexPath.item) \(userClubNames[indexPath.item])")
            self.segDest = 1
            showActivityIndicatory(uiView: self.view, container: container, actInd: actInd, overlayView: self.overlayView)
            
            //Check if the user is part of club
            if (allUserFirebaseData.data["clubs"] as! [String]).contains(userClubIDs[indexPath.item]) || allUserFirebaseData.data["status"] as! Int == 2 {
                print("yeah part of club")
                partOfClub = true
            } else {
                partOfClub = false
            }
            
            //Get all required data for the club
            db.collection("clubs").document(userClubIDs[indexPath.item]).getDocument { (document, error) in
                if let document = document, document.exists {
                    let theData = document.data()!
                    self.clubData = theData
                    self.clubID = self.userClubIDs[indexPath.item]
                    
                    //Get the image
                    let storage = Storage.storage()
                    let storageRef = storage.reference()
                    
                    //Go through each picture for each club
                    //Set up the image
                    let imageName = theData["img"] as! String
                    let bannerRef = storageRef.child("clubBanners/\(imageName)")
                    
                    bannerRef.getMetadata { (metadata, error) in
                        if let error = error {
                            // Uh-oh, an error occurred!
                            let alert = UIAlertController(title: "Error in retrieveing club images", message: "Error: \(error.localizedDescription)", preferredStyle: .alert)
                            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                            alert.addAction(okAction)
                            self.present(alert, animated: true, completion: nil)
                            print(error)
                            self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                        } else {
                            // Metadata now contains the metadata for 'images/forest.jpg'
                            if let metadata = metadata {
                                let theMetaData = metadata.dictionaryRepresentation()
                                let updated = theMetaData["updated"]
                                
                                if let updated = updated {
                                    if let savedImage = self.getSavedImage(named: "\(imageName)-\(updated)"){
                                        print("already saved \(imageName)-\(updated)")
                                        self.clubImage = savedImage
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                                            self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                                            self.performSegue(withIdentifier: "showClub", sender: self.showClubButton)
                                        }
                                    } else {
                                        // Create a reference to the file you want to download
                                        bannerRef.downloadURL { url, error in
                                            if let error = error {
                                                // Handle any errors
                                                let alert = UIAlertController(title: "Error in retrieveing club images", message: "Error: \(error.localizedDescription)", preferredStyle: .alert)
                                                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                                alert.addAction(okAction)
                                                self.present(alert, animated: true, completion: nil)
                                                print(error)
                                                self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                                            } else {
                                                print("img gonna get new image \(imageName)")
                                                // Get the download URL
                                                var image: UIImage?
                                                let data = try? Data(contentsOf: url!)
                                                if let imageData = data {
                                                    image = UIImage(data: imageData)!
                                                    self.clubImage = image
                                                    self.clearImageFolder(imageName: "\(imageName)-\(updated)")
                                                    self.saveImageDocumentDirectory(image: image!, imageName: "\(imageName)-\(updated)")
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                                                        self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                                                        self.performSegue(withIdentifier: "showClub", sender: self.showClubButton)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    print("Document does not exist")
                    let alert = UIAlertController(title: "Error", message: "Requested club could not be found in Database", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                    self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                }
            }
        }
    }
    
    //*************CHANGING PROFILE PIC*************
    @IBAction func changeProfilePic(_ sender: Any) {
        print("wow change profile pic")
        segDest = 3
        performSegue(withIdentifier: "showProfilePics", sender: showProfilePics)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //If the segue is the showing classes segue
        switch segDest {
        case 0:
            //Classes List
            let vc = segue.destination as! classesDetailsController
            vc.classes = theOtherPersonsClasses
            vc.yourClasses = allUserFirebaseData.data["classes"] as! [String]
            
            if lookingAtOtherUserInGeneral {
                vc.viewingYourself = false
            }
            
            break
        case 1:
            //Get all information for the club
            let vc = segue.destination as! clubGoodController
            vc.clubData = clubData
            vc.partOfClub = partOfClub
            vc.banImage = clubImage
            vc.clubID = clubID
            vc.cameFromSocialPage = true
            vc.joinedANewClubBlock = { result in
                self.getClubData(clubIDRefs: allUserFirebaseData.data["clubs"] as! [String])
            }
            break
        case 3:
            //Profile pics
            let vc = segue.destination as! profilePicController
            vc.thePicImage = allUserFirebaseData.profilePic
            break
        default:
            print("welp")
        }
    }
}
