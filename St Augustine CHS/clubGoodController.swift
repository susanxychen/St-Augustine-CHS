//
//  clubListGoodController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-10-31.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit
import Firebase

class clubGoodController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    //Filler
    var fillerBanImage = UIImage(named: "space")
    
    //The Database
    var db: Firestore!
    var docRef: DocumentReference!
    
    //The Club Data
    var clubData = [String:Any]()
    var banImage: UIImage?
    var anncRef = [String]()
    var anncData = [[String:Any]]()
    var clubID = String()
    
    var anncImgs = [UIImage]()
    
    //Error Handling Vars
    var snooImgFiller = UIImage(named: "snoo")
    
    @IBOutlet weak var clubContoller: UICollectionView!
    @IBOutlet weak var addAnncButton: UIButton!
    
    var noAnnouncments = false
    
    //Refresh Variables
    var refreshControl: UIRefreshControl?
    let actInd: UIActivityIndicatorView = UIActivityIndicatorView()
    let container: UIView = UIView()
    let overlayView = UIView(frame: UIScreen.main.bounds)
    
    //Part of Club or not Variables
    var partOfClub = true
    var acceptingJoinRequests = true
    
    //Admin edit var
    @IBOutlet weak var editClubDetailsButton: UIButton!
    var isClubAdmin = false
    
    //Segue vars
    var segueNum = 0
    var comingFromTheSocialPage = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        clubListDidUpdateClubDetails.clubAdminUpdatedData = false
        
        //Check join status
        if clubData["canJoin"] as! Int == 0 {
            acceptingJoinRequests = false
        } else {
            acceptingJoinRequests = true
        }
        
        //Set the view controller title to the club's name
        self.navigationItem.title = clubData["name"] as? String
        
        //Allow refreshing anytime
        clubContoller.alwaysBounceVertical = true
        
        //Set Up
        // [START setup]
        let settings = FirestoreSettings()
        settings.areTimestampsInSnapshotsEnabled = true
        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
        //Add Refresh Control
        addRefreshControl()
        
        //The announcements
        //anncRef = clubData["announcements"] as? [String] ?? []
        
        let user = Auth.auth().currentUser
        //********CHECK IF USER IS ADMIN*******
        if (clubData["admins"] as! [String]).contains((user?.uid)!){
            isClubAdmin = true
        } else {
            isClubAdmin = false
        }
        
        //*********************CLUB ADMIN PERMS********************
        if isClubAdmin {
            //Long Press Gesture Recognizer
            //let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(clubGoodController.handleLongPress))
            let lpgr: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(clubGoodController.handleLongPress(gestureRecognizer:)))
            lpgr.minimumPressDuration = 0.5
            //lpgr.delegate = self as? UIGestureRecognizerDelegate
            lpgr.delaysTouchesBegan = true
            self.clubContoller.addGestureRecognizer(lpgr)
            
            //*****************EDIT CLUB DETAILS BUTTON******************
            let editClubDeailsButton = UIButton(type: .custom)
            editClubDeailsButton.setImage(UIImage(named: "3Dots"), for: .normal)
            //add function for button
            editClubDeailsButton.addTarget(self, action: #selector(clubSettings), for: .touchUpInside)
            editClubDeailsButton.frame = CGRect(x: 0, y: 0, width: 48, height: 48)
            
            let editDetailsBarbutton = UIBarButtonItem(customView: editClubDeailsButton)
            
            //Assign Buttons to Navigation Bar
            self.navigationItem.rightBarButtonItem = editDetailsBarbutton
        }
               
        //Get club announcements if part of club
        if partOfClub {
            getClubAnnc()
        }
    }
    
    //**********************JOINING CLUBS***********************
    @objc func joinButtonTapped(sender: UIButton){
        let joinStatus = clubData["canJoin"] as! Int
        print("wow u want to join the best club. Join status \(joinStatus)")
        
    }
    
    @objc func clubSettings(sender: Any) {
        //Set up the action sheet options
        let actionSheet = UIAlertController(title: "Choose an Option", message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Edit Club Details", style: .default, handler: { (action:UIAlertAction) in
            print("edit")
            self.segueNum = 0
            self.performSegue(withIdentifier: "editClubDetails", sender: self.editClubDetailsButton)
        }))
        actionSheet.addAction(UIAlertAction(title: "Add Announcement", style: .default, handler: { (action:UIAlertAction) in
            print("add")
            self.isEditingAnnc = false
            self.segueNum = 1
            self.performSegue(withIdentifier: "addAnnc", sender: self.addAnncButton)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    //*********************************EDITING ANNOUNCEMENT*********************************
    var isEditingAnnc = false
    var theCurrentAnncTitle = String()
    var theCurrentAnncDesc = String()
    var theCurrentAnncImg = UIImage()
    var theCurrentAnncImgName = String()
    var theCurrentAnncID = String()
    
    @objc func handleLongPress(gestureRecognizer : UILongPressGestureRecognizer){
        if (gestureRecognizer.state != UIGestureRecognizer.State.began){
            return
        }
        let p = gestureRecognizer.location(in: self.clubContoller)
        if let indexPath : NSIndexPath = (self.clubContoller.indexPathForItem(at: p) as NSIndexPath?){
            if !noAnnouncments {
                //Show options to delete the announcement or edit it
                let anncTitle = anncData[indexPath.item]["title"] as? String ?? ""
                
                //Set up the action sheet options
                let actionSheet = UIAlertController(title: anncTitle, message: "Choose an Option", preferredStyle: .actionSheet)
                actionSheet.addAction(UIAlertAction(title: "Edit", style: .default, handler: { (action:UIAlertAction) in
                    //Segue to the addAnnc controller and give the current announcment details
                    self.isEditingAnnc = true
                    self.theCurrentAnncTitle = self.anncData[indexPath.item]["title"] as! String
                    self.theCurrentAnncDesc = self.anncData[indexPath.item]["content"] as? String ?? ""
                    self.theCurrentAnncImg = self.anncImgs[indexPath.item]
                    self.theCurrentAnncImgName = self.anncData[indexPath.item]["img"] as? String ?? ""
                    self.theCurrentAnncID = self.anncRef[indexPath.item]
                    
                    self.segueNum = 1
                    
                    self.performSegue(withIdentifier: "addAnnc", sender: self.addAnncButton)
                }))
                actionSheet.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (action:UIAlertAction) in
                    //Create the confirmation alert controller.
                    let alert = UIAlertController(title: "Confirmation", message: "Are you sure you want to delete \"\(anncTitle)\"? This cannot be undone.", preferredStyle: .alert)
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { (action:UIAlertAction) in
                        //print("You've pressed cancel");
                    }
                    
                    let confirmAction = UIAlertAction(title: "Delete", style: UIAlertAction.Style.destructive) { (action:UIAlertAction) in
                        print("Deleted the annc");
                        self.showActivityIndicatory(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                        let theDeleteAnncID = self.anncRef[indexPath.item]
                        
//                        //Remove the Announcement from the club annc array
//                        let anncRef = self.db.collection("clubs").document(self.clubID)
//                        anncRef.updateData([
//                            "announcements" : FieldValue.arrayRemove([theDeleteAnncID])
//                        ])
                        
                        //Remove the announcement document
                        self.db.collection("announcements").document(theDeleteAnncID).delete() { err in
                            if let err = err {
                                print("Error in removing document: \(err.localizedDescription)")
                                let alert = UIAlertController(title: "Error in deleting announcement", message: "Please Try Again later. Error: \(err.localizedDescription)", preferredStyle: .alert)
                                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                alert.addAction(okAction)
                                self.present(alert, animated: true, completion: nil)
                            } else {
                                print("Document removed!")
                            }
                        }
                        
                        //Delete the image from the database
                        let imageName = self.anncData[indexPath.item]["img"] as? String ?? ""
                        if imageName != "" {
                            let storageRef = Storage.storage().reference(withPath: "announcements").child(imageName)
                            storageRef.delete(completion: { err in
                                if let err = err {
                                    print("Error deleteing anncImg \(err.localizedDescription)")
                                } else {
                                    print("Annc Img successfully deleted")
                                }
                            })
                        }
                        
                        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                        guard let items = try? FileManager.default.contentsOfDirectory(atPath: path) else { return }
                        
                        for item in items {
                            // This can be made better by using pathComponent
                            let completePath = path.appending("/").appending(item)
                            if completePath.hasSuffix(imageName) {
                                print("removing \(imageName)")
                                try? FileManager.default.removeItem(atPath: completePath)
                            }
                        }
                        
                        self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                        self.refreshList()
                    }
                    alert.addAction(confirmAction)
                    alert.addAction(cancelAction)
                    
                    // 4. Present the alert.
                    self.present(alert, animated: true, completion: nil)
                }))
                actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                self.present(actionSheet, animated: true, completion: nil)
            }
        }
        
    }
    
    //***********************************GET CLUB ANNOUNCEMENTS*************************************
    func getClubAnnc() {
        showActivityIndicatory(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
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
                        let alert = UIAlertController(title: "Error", message: "You are not connected to the internet. Any presented data will be loaded from cache.", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                        self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                    }
                }
            }
        })
        
        anncData.removeAll()
        anncRef.removeAll()
        anncImgs.removeAll()
        
        db.collection("announcements").whereField("club", isEqualTo: clubID).getDocuments { (snap, err) in
            if let error = err {
                let alert = UIAlertController(title: "Error in retrieveing Club Data", message: "Error \(error.localizedDescription)", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            }
            if let snap = snap {
                if snap.count <= 0 {
                    print("there is no announcements")
                    self.anncData = [["content": "", "date": Timestamp.init(), "img": "","title": "There are no announcements"]]
                    self.noAnnouncments = true
                    self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                    self.clubContoller.reloadData()
                    self.refreshControl?.endRefreshing()
                } else {
                    let document = snap.documents
                    for i in 0...document.count-1 {
                        self.anncData.append(document[i].data())
                        self.anncRef.append(document[i].documentID)
                        
                        if i == document.count - 1 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                print("finished getting getting anncData first time")
                                //print("After all appends \(self.anncData)")
                                self.sortAnncByDate()
                            }
                        }
                    }
                }
            }
        }
    }

    func sortAnncByDate () {
        for _ in anncRef {
            anncImgs.append(snooImgFiller!)
        }
        //print(anncData)
        if anncData.count > 2 {
            var thereWasASwap = true
            while thereWasASwap {
                thereWasASwap = false
                for i in 0...anncData.count-2 {
                    let timestamp1: Timestamp = anncData[i]["date"] as! Timestamp
                    let date1: Date = timestamp1.dateValue()
                    let timestamp2: Timestamp = anncData[i + 1]["date"] as! Timestamp
                    let date2: Date = timestamp2.dateValue()
                    
                    //Swap values
                    if date2 > date1 {
                        thereWasASwap = true
                        let temp = anncData[i]
                        anncData[i] = anncData[i+1]
                        anncData[i+1] = temp
                        
                        //also swap the anncRef array for edit mode so we can use it otherwise its out of order
                        let temp2 = anncRef[i]
                        anncRef[i] = anncRef[i+1]
                        anncRef[i+1] = temp2
                    }
                }
            }
        } else if anncData.count == 2 {
            let i = 0
            let timestamp1: Timestamp = anncData[i]["date"] as! Timestamp
            let date1: Date = timestamp1.dateValue()
            let timestamp2: Timestamp = anncData[i + 1]["date"] as! Timestamp
            let date2: Date = timestamp2.dateValue()
            
            //Swap values
            if date2 > date1 {
                let temp = anncData[i]
                anncData[i] = anncData[i+1]
                anncData[i+1] = temp
                
                //also swap the anncRef array for edit mode so we can use it otherwise its out of order
                let temp2 = anncRef[i]
                anncRef[i] = anncRef[i+1]
                anncRef[i+1] = temp2
            }
        }
        getImages()
    }
    
    func getImages() {
        //print(anncData)
        if anncData.count <= 0 {
            self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
            self.clubContoller.reloadData()
            self.refreshControl?.endRefreshing()
        }
        
        var hasImageSomewhere = false
        for i in 0...anncData.count-1{
            if anncData[i]["img"] as? String != nil && anncData[i]["img"] as? String != "" {
                hasImageSomewhere = true
                let storage = Storage.storage()
                let storageRef = storage.reference()
                //Set up the image
                let imageName = anncData[i]["img"] as! String
                // Create a reference to the file you want to download
                let imgRef = storageRef.child("announcements/\(imageName)")
                
                imgRef.getMetadata { (metadata, error) in
                    if let error = error {
                        // Uh-oh, an error occurred!
                        self.anncData[i]["img"] = ""
                        self.anncImgs[i] = self.snooImgFiller!
                        print(error)
                    } else {
                        // Metadata now contains the metadata for 'images/forest.jpg'
                        if let metadata = metadata {
                            let theMetaData = metadata.dictionaryRepresentation()
                            let updated = theMetaData["updated"]
                            
                            if let updated = updated {
                                if let savedImage = self.getSavedImage(named: "\(imageName)-\(updated)"){
                                    print("already saved \(imageName)-\(updated)")
                                    self.anncImgs[i] = savedImage
                                } else {
                                    // Create a reference to the file you want to download
                                    imgRef.downloadURL { url, error in
                                        if error != nil {
                                            //print(error)
                                            print("cant find image \(imageName) + \(self.anncData[i])")
                                            self.anncData[i]["img"] = ""
                                            self.anncImgs[i] = self.snooImgFiller!
                                        } else {
                                            // Get the download URL
                                            var image: UIImage?
                                            let data = try? Data(contentsOf: url!)
                                            if let imageData = data {
                                                image = UIImage(data: imageData)!
                                                self.anncImgs[i] = image!
                                                self.clearImageFolder(imageName: "\(imageName)-\(updated)")
                                                self.saveImageDocumentDirectory(image: image!, imageName: "\(imageName)-\(updated)")
                                            }
                                            print("i success now")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                self.anncImgs[i] = self.snooImgFiller!
            }
        }
        
        //Reload announcements
        if hasImageSomewhere {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                print("i reload data")
                self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                self.clubContoller.reloadData()
                self.refreshControl?.endRefreshing()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("i reload data")
                self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                self.clubContoller.reloadData()
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
    //********************CLUB ANNOUNCEMENTS********************
    //Set up the header/Club details
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as! clubHeaderViewCell
            
            //Put banner on bottom
            view.bringSubviewToFront(view.name)
            view.sendSubviewToBack(view.banner)
            
            //print(clubData["name"])
            //Set the title's height
            let size = CGSize(width: view.frame.width, height: 1000)
            let attributesTitle = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 23)]
            let estimatedFrameTitle = NSString(string: clubData["name"] as! String).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributesTitle, context: nil)
            view.nameHeight.constant = estimatedFrameTitle.height + 20
            //print(estimatedFrameTitle.height)
            
            //Set the content's height
            let attributesContent = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)]
            let estimatedFrameContent = NSString(string: clubData["desc"] as! String).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributesContent, context: nil)
            view.descHeight.constant = estimatedFrameContent.height + 40
            //print(estimatedFrameContent.height)
            
            view.banner.image = banImage ?? fillerBanImage
            view.name.text = clubData["name"] as? String
            view.desc.text = clubData["desc"] as? String
            view.name.centerVertically()
            view.desc.centerVertically()
            
            view.bringSubviewToFront(view.badgesCollectionView)
            
            if partOfClub {
                view.joinClubButton.isHidden = true
            } else {
                view.announcmentLabel.isHidden = true
                view.bringSubviewToFront(view.joinClubButton)
                
                if acceptingJoinRequests {
                    //Set up the join button
                    view.joinClubButton.isEnabled = true
                    view.joinClubButton.addTarget(self, action: #selector(self.joinButtonTapped), for: .touchUpInside)
                } else {
                    //disable the join button
                    view.joinClubButton.isEnabled = false
                }
                
            }
            
            return view
        }
        fatalError("Unexpected kind")
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize{
        //Dynamically change the cell size depending on the announcement length
        let size = CGSize(width: view.frame.width, height: 1000)
        
        //Get an approximation of the title size
        let attributesTitle = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 23)]
        let estimatedFrameTitle = NSString(string: clubData["name"] as! String).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributesTitle, context: nil)
        
        //Get an approximation of the description size
        let attributesContent = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)]
        let estimatedFrameContent = NSString(string: clubData["desc"] as! String).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributesContent, context: nil)
        
        var joinButtonSizeOrAnnouncmentTextSize: CGFloat
        
        if partOfClub {
            //Add size of the join club button
            joinButtonSizeOrAnnouncmentTextSize = 0
        } else {
            //Add size of the announcment label
            joinButtonSizeOrAnnouncmentTextSize = 55
        }
        
        //Also add the height of the picture and the announcements and the space inbetween
        return CGSize(width: view.frame.width, height: estimatedFrameContent.height + estimatedFrameTitle.height + 150 + joinButtonSizeOrAnnouncmentTextSize + 100 + 30 + 130)
        
    }
    
    //************************************************************Set up the announcements************************************************
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return anncData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        //Dynamically change the cell size depending on the announcement length 
        let size = CGSize(width: view.frame.width, height: 1000)
        
        //Get an approximation of the title size
        let attributesTitle = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 19)]
        let estimatedFrameTitle = NSString(string: anncData[indexPath.row]["title"] as! String).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributesTitle, context: nil)
        
        //Get an approximation of the content size
        let attributesContent = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)]
        let estimatedFrameContent = NSString(string: anncData[indexPath.row]["content"] as! String).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributesContent, context: nil)
        
        var imgHeight:CGFloat = 0
        if anncData[indexPath.row]["img"] as? String != "" {
            imgHeight = 260
        }
        
        //Check if there is content for the announcment
        if anncData[indexPath.row]["content"] as? String == "" {
            return CGSize(width: view.frame.width, height: estimatedFrameTitle.height + imgHeight + 33 + 40)
        } else {
            return CGSize(width: view.frame.width, height: estimatedFrameTitle.height + estimatedFrameContent.height + imgHeight + 33 + 40)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "announcement", for: indexPath) as! clubNewsViewCell
        
        //Clear the old image as the cell gets reused. Good chance you need to clear all data. set to nil
        cell.anncImg.image = UIImage()
        
        //print(anncData)
        if anncData.count != 0 {
            //Set the title's height
            let size = CGSize(width: view.frame.width, height: 1000)
            let attributesTitle = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 19)]
            let estimatedFrameTitle = NSString(string: anncData[indexPath.row]["title"] as! String).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributesTitle, context: nil)
            cell.anncTitleHeight.constant = estimatedFrameTitle.height + 20
            
            //Set the content's height
            let attributesContent = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)]
            let estimatedFrameContent = NSString(string: anncData[indexPath.row]["content"] as! String).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributesContent, context: nil)
            if anncData[indexPath.row]["content"] as? String == "" {
                cell.anncTextHeight.constant = 1
            } else {
                cell.anncTextHeight.constant = estimatedFrameContent.height + 20
            }
            
            //Get the date the announcement was made
            let timestamp: Timestamp = anncData[indexPath.row]["date"] as! Timestamp
            let date: Date = timestamp.dateValue()
            
            //Set up title and content
            cell.anncDate.text = DateFormatter.localizedString(from: date, dateStyle: DateFormatter.Style.full, timeStyle: DateFormatter.Style.none)
            cell.anncTitle.text = anncData[indexPath.row]["title"] as? String
            cell.anncText.text = anncData[indexPath.row]["content"] as? String
            cell.anncTitle.centerVertically()
            cell.anncText.centerVertically()
            
            //Set up images
            //Use already downloaded images
            //Note. The Collection View Cells become deallocated as it goes off the screen. Redownloading the same images over and over is inefficent.
            //Instead. I have saved the images and load images from the memory
            //print("index is \(indexPath.row) and anncImgs.count is \(anncImgs.count)")
            if indexPath.row < anncImgs.count {
                if anncImgs[indexPath.row] != snooImgFiller {
                    //print("\(indexPath.row) Has images")
                    cell.anncImg.isHidden = false
                    cell.anncImg.image = anncImgs[indexPath.row]
                }
            }
        }
        return cell
    }
    
    //*****************************************REFRESHING DATA**************************************
    func addRefreshControl(){
        refreshControl = UIRefreshControl()
        refreshControl?.tintColor = UIColor.red
        refreshControl?.addTarget(self, action: #selector(refreshList), for: .valueChanged)
        clubContoller.addSubview(refreshControl!)
    }
    
    @objc func refreshList(){
        print("I refreshed stuff")
        //Wipe all data
        clubData.removeAll()
        //Get Club Data
        let docRef = db.collection("clubs").document(clubID)
        docRef.getDocument { (document, error) in
            if let error = error {
                let alert = UIAlertController(title: "Error in retrieveing Clubs", message: "Please Try Again later. Error: \(error.localizedDescription)", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            }
            if let document = document, document.exists {
                self.clubData = document.data()!
                self.navigationItem.title = self.clubData["name"] as? String
                self.getClubAnnc()
                self.getClubBanner()
            } else {
                print("Document does not exist")
            }
        }
    }
    
    //Get club banner
    func getClubBanner() {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        // Create a reference to the file you want to download
        let bannerRef = storageRef.child("clubBanners/\(clubData["img"]!)")
        
        bannerRef.getMetadata { (metadata, error) in
            if let error = error {
                // Uh-oh, an error occurred!
                print(error)
            } else {
                // Metadata now contains the metadata for 'images/forest.jpg'
                if let metadata = metadata {
                    let theMetaData = metadata.dictionaryRepresentation()
                    let updated = theMetaData["updated"]
                    
                    if let updated = updated {
                        if let savedImage = self.getSavedImage(named: "\(self.clubData["img"]!)-\(updated)"){
                            print("already saved \(self.clubData["img"]!)-\(updated)")
                            self.banImage = savedImage
                            print("i got saved club banner")
                        } else {
                            // Create a reference to the file you want to download
                            bannerRef.downloadURL { url, error in
                                if let error = error {
                                    // Handle any errors
                                    print(error)
                                    let alert = UIAlertController(title: "Error in retrieveing Club Banner", message: "Please Try Again later. Error: \(error.localizedDescription)", preferredStyle: .alert)
                                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                    alert.addAction(okAction)
                                    self.present(alert, animated: true, completion: nil)
                                } else {
                                    // Get the download URL
                                    var image: UIImage?
                                    let data = try? Data(contentsOf: url!)
                                    if let imageData = data {
                                        image = UIImage(data: imageData)!
                                        self.banImage = image!
                                        self.clearImageFolder(imageName: "\(self.clubData["img"]!)-\(updated)")
                                        self.saveImageDocumentDirectory(image: image!, imageName: "\(self.clubData["img"]!)-\(updated)")
                                        print("i got club banner")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //selectedAnnc = indexPath.item
        print("im gonna show the announcment number \(String(describing: indexPath.item))")
        print(anncImgs)
    }
    
    //****************************PREPARE FOR SEGUE*****************************
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch(segueNum) {
        case 0:
            print("then lets go edit details")
            let vc = segue.destination as! editClubDetailsController
            vc.clubBannerImage = banImage
            vc.clubName = clubData["name"] as? String
            vc.clubDesc = clubData["desc"] as? String
            vc.clubJoinSetting = clubData["canJoin"] as? Int
            vc.clubBannerID = clubData["img"] as? String
            vc.clubID = clubID
            
            //Refresh the club details to get new banners and other stuff!!!
            vc.onDoneBlock = { result in
                clubListDidUpdateClubDetails.clubAdminUpdatedData = true
                print("wow i come back here after editing")
                self.refreshList()
            }
            break
        case 1:
            let vc = segue.destination as! addAnncController
            vc.clubID = clubID
            
            //See if u have to go into edit mode and set defaults
            if isEditingAnnc {
                vc.editMode = true
                vc.currentAnncID = theCurrentAnncID
                vc.editTitle = theCurrentAnncTitle
                vc.editDesc = theCurrentAnncDesc
                vc.editImage = theCurrentAnncImg
                vc.editImageName = theCurrentAnncImgName
            }
            
            //Refresh the data when coming back after posting to get new announcements 
            vc.onDoneBlock = { result in
                print("wow i come back here after adding")
                clubListDidUpdateClubDetails.clubAdminUpdatedData = true
                self.refreshList()
            }
            break
        default:
            print("welp")
        }
    }
}

