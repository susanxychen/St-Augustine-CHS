//
//  songReqController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-10-25.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit
import Firebase
import Floaty

struct voteData {
    //Voted, Name, Artist, Votes, ID, Suggestor
    static var songsVoted:[[Any]] = []
}

class songReqController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, SongViewCellDelegate {
    
    //button used for segue
    @IBOutlet weak var suggestASong: UIButton!
    
    let actInd: UIActivityIndicatorView = UIActivityIndicatorView()
    let container: UIView = UIView()
    
    //The Database
    var db: Firestore!
    var docRef: DocumentReference!
    
    @IBOutlet weak var songView: UICollectionView!
    
    var isOverMaxSongs = false
    
    //Song Request Themes
    @IBOutlet weak var themeLabel: UILabel!
    @IBOutlet weak var themeLabelHeight: NSLayoutConstraint!
    
    //Refresh Controls
    var refreshControl: UIRefreshControl?
    
    //Super vote stuff
    @IBOutlet weak var noSongLabel: UILabel!
    @IBOutlet weak var supervoteView: UIView!
    @IBOutlet weak var supervoteSongName: UILabel!
    @IBOutlet weak var supervotePoints: UILabel!
    @IBOutlet weak var supervoteVotes: UILabel!
    @IBOutlet weak var supervoteSlider: UISlider!
    @IBOutlet weak var supervoteDesc: UILabel!
    
    @IBOutlet weak var spendButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    var userNames = [String]()
    var userPics = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Clear Keys of previous song voting only once
        var haventCleared = true
        if let x = UserDefaults.standard.object(forKey: "haventClearedSongKeys") as? Bool {
           haventCleared = x
            print("Have cleared songs already")
        }

        if haventCleared {
            print("Have not cleared songs. Clearing")
            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
            
            UserDefaults.standard.set(false, forKey: "haventClearedSongKeys")
        }
        
        //Add the super vote recognizer
        let lpgr: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(gestureRecognizer:)))
        lpgr.minimumPressDuration = 0.5
        //lpgr.delegate = self as? UIGestureRecognizerDelegate
        lpgr.delaysTouchesBegan = true
        self.songView.addGestureRecognizer(lpgr)
        
        //Add the request a song floating button
        let floaty = Floaty()
        floaty.buttonColor = Defaults.accentColor
        floaty.plusColor = UIColor.white
        floaty.overlayColor = UIColor.clear
        
        let item = FloatyItem()
        item.buttonColor = Defaults.accentColor
        item.icon = UIImage(named: "addSong")!
        item.handler = { item in
            if self.isOverMaxSongs {
                let alert = UIAlertController(title: "", message: "There are too many songs requested today. Try again tomorrow!", preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5){
                    alert.dismiss(animated: true, completion: nil)
                }
            } else {
                self.performSegue(withIdentifier: "suggestSong", sender: self.suggestASong)
            }
            
            floaty.close()
        }
        floaty.addItem(item: item)
        floaty.openAnimationType = .slideLeft
        floaty.sticky = true
        self.view.addSubview(floaty)
        
        //Add refresh control
        addRefreshControl()
        
        //Allow refreshing anytime
        songView.alwaysBounceVertical = true
        
        //Set up the activity indicator
        showActivityIndicatory(container: container, actInd: actInd)
        
        //Set Up
        // [START setup]
        let settings = FirestoreSettings()
        settings.areTimestampsInSnapshotsEnabled = true
        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
        //Colours
        spendButton.setTitleColor(Defaults.accentColor, for: .normal)
        cancelButton.setTitleColor(Defaults.accentColor, for: .normal)
        supervoteSlider.tintColor = Defaults.accentColor
        
        themeLabel.textColor = Defaults.accentColor
        themeLabel.backgroundColor = Defaults.darkerPrimary
        
        supervoteSlider.minimumValue = Float(Defaults.supervoteMin)
        supervoteSlider.maximumValue = Float(allUserFirebaseData.data["points"] as! Int)
        
        //Get the data of what you voted for before
        if let x = UserDefaults.standard.object(forKey: "songsVoted") as? [[Any]]{
            voteData.songsVoted = x
        }
        
        //Check for a song request theme
        if Defaults.songRequestTheme != "" {
            themeLabel.text = "THEME: \(Defaults.songRequestTheme)"
            themeLabelHeight.constant = 35
        } else {
            themeLabelHeight.constant = 0
        }
        
        getSongData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //Reset the slider max to new amount of votes
        supervoteSlider.maximumValue = Float(allUserFirebaseData.data["points"] as! Int)
    }
    
    var selectedSuperSongID: String!
    var supervotedIndex = 0
    @objc func handleLongPress(gestureRecognizer : UILongPressGestureRecognizer){
        if (gestureRecognizer.state != UIGestureRecognizer.State.began){
            return
        }
        let p = gestureRecognizer.location(in: self.songView)
        if let indexPath : NSIndexPath = (self.songView.indexPathForItem(at: p) as NSIndexPath?){
            //Let teachers delete songs
            if allUserFirebaseData.data["status"] as? Int ?? 0 > 0 {
                let actionSheet = UIAlertController(title: "Choose an Option for \(voteData.songsVoted[indexPath.item][1] as? String ?? "Error")", message: nil, preferredStyle: .actionSheet)
                
                actionSheet.addAction(UIAlertAction(title: "Delete Song", style: .default, handler: { (action:UIAlertAction) in
                    let alert = UIAlertController(title: "Confirmation", message: "Are you sure you want to delete \(voteData.songsVoted[indexPath.item][1] as? String ?? "Error")?", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil)
                    let confirmAction = UIAlertAction(title: "Confirm", style: UIAlertAction.Style.destructive) { (action:UIAlertAction) in
                        print("delete song")
                        
                        //Remove the song
                        self.showActivityIndicatory(container: self.container, actInd: self.actInd)
                        self.db.collection("songs").document(voteData.songsVoted[indexPath.item][4] as? String ?? "error").delete() { err in
                            if let err = err {
                                print("Error in removing song: \(err.localizedDescription)")
                                let alert = UIAlertController(title: "Error in deleting song", message: "Please Try Again later. Error: \(err.localizedDescription)", preferredStyle: .alert)
                                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                alert.addAction(okAction)
                                self.present(alert, animated: true, completion: nil)
                            } else {
                                self.getSongData()
                            }
                        }
                    }
                    alert.addAction(confirmAction)
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                }))
                actionSheet.addAction(UIAlertAction(title: "Supervote", style: .default, handler: { (action:UIAlertAction) in
                    //Already voted
                    if voteData.songsVoted[indexPath.item][0] as! Int != 0 {
                        let alert = UIAlertController(title: "", message: "You already voted!", preferredStyle: .alert)
                        self.present(alert, animated: true, completion: nil)
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5){
                            alert.dismiss(animated: true, completion: nil)
                        }
                    } else {
                        //Regular supervote for teachers
                        self.supervotedIndex = indexPath.item
                        self.selectedSuperSongID = voteData.songsVoted[indexPath.item][4] as? String
                        self.supervoteSongName.text = "Supervote: \(voteData.songsVoted[indexPath.item][1] as? String ?? "Error")"
                        self.supervoteDesc.text = "Super vote allows you to spend points for votes. You have \(allUserFirebaseData.data["points"] ?? "Error") points."
                        self.supervoteView.isHidden = false
                        self.view.bringSubviewToFront(self.supervoteView)
                        
                        UIView.animate(withDuration: 0.1) {
                            self.supervoteView.alpha = 1
                        }
                    }
                }))
                actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(actionSheet, animated: true, completion: nil)
            }
            
            //Normal super vote
            else {
                //Only allow super vote if user has not already voted
                if voteData.songsVoted[indexPath.item][0] as! Int == 0 {
                    print("Long Pressed on: \(indexPath.item)")
                    supervotedIndex = indexPath.item
                    selectedSuperSongID = voteData.songsVoted[indexPath.item][4] as? String
                    supervoteSongName.text = "Supervote: \(voteData.songsVoted[indexPath.item][1] as? String ?? "Error")"
                    supervoteDesc.text = "Super vote allows you to spend points for votes. You have \(allUserFirebaseData.data["points"] ?? "Error") points."
                    supervoteView.isHidden = false
                    self.view.bringSubviewToFront(supervoteView)
                    
                    UIView.animate(withDuration: 0.1) {
                        self.supervoteView.alpha = 1
                    }
                }
            }
            
        }
    }
    
    var supervoteAmount = 0
    var supervoteCost = 0
    @IBAction func sliderMoved(_ sender: Any) {
        let value = CGFloat(supervoteSlider.value)
        supervoteAmount = Int(value * Defaults.supervoteRatio)
        supervoteCost = Int(value)
        
        supervoteVotes.text = "Votes: \(supervoteAmount)"
        supervotePoints.text = "Points: \(supervoteCost)"
    }
    
    @IBAction func cancelSuperVote(_ sender: Any) {
        UIView.animate(withDuration: 0.1, animations: {
            self.supervoteView.alpha = 0
        }) { _ in
            self.supervoteView.isHidden = true
            self.view.sendSubviewToBack(self.supervoteView)
        }
    }
    
    //Cloud Functions
    lazy var functions = Functions.functions()
    @IBAction func spendPointsSuper(_ sender: Any) {
        if supervoteAmount != 0 {
            UIView.animate(withDuration: 0.1, animations: {
                self.supervoteView.alpha = 0
            }) { _ in
                self.supervoteSlider.setValue(0, animated: false)
                self.supervoteView.isHidden = true
                self.view.sendSubviewToBack(self.supervoteView)
            }
            
            //Subtact the points
            allUserFirebaseData.data["points"] = allUserFirebaseData.data["points"] as! Int - self.supervoteCost
            supervoteSlider.maximumValue = Float(allUserFirebaseData.data["points"] as! Int)
            
            let userRef = self.db.collection("users").document((Auth.auth().currentUser?.uid)!)
            userRef.setData([
                "points" : allUserFirebaseData.data["points"] as! Int
            ], mergeFields: ["points"]) { (err) in
                if let err = err {
                    let alert = UIAlertController(title: "Error in supervoting", message: "Error: \(err.localizedDescription)", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                } else {
                    print("Document successfully updated")
                    
                    let songRef = self.db.collection("songs").document(self.selectedSuperSongID)
                    self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                        let uDoc: DocumentSnapshot
                        do {
                            try uDoc = transaction.getDocument(songRef)
                        } catch let fetchError as NSError {
                            errorPointer?.pointee = fetchError
                            return nil
                        }
                        
                        guard let oldPoints = uDoc.data()?["upvotes"] as? Int else {
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
                        transaction.updateData(["upvotes": oldPoints + self.supervoteAmount], forDocument: songRef)
                        return nil
                    }, completion: { (object, err) in
                        if let error = err {
                            print("Transaction failed: \(error)")
                        } else {
                            print("Transaction successfully committed!")
                            print("successfuly upvoted")
                            voteData.songsVoted[self.supervotedIndex][0] = 2
                            voteData.songsVoted[self.supervotedIndex][3] = self.supervoteAmount + (voteData.songsVoted[self.supervotedIndex][3] as! Int)
                            UserDefaults.standard.set(voteData.songsVoted, forKey: "songsVoted")
                            self.refreshList()
                        }
                    })
                }
            }
        }    
    }
    
    //***************************************GET SONG DATA*************************************
    func getSongData() {
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
                        let alert = UIAlertController(title: "Error", message: "You are not connected to the internet. Infortmation loaded from cache.", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                        self.isOverMaxSongs = true
                    }
                }
            }
        })
        
        db.collection("songs").getDocuments() { (querySnapshot, err) in
            if let err = err {
                let alert = UIAlertController(title: "Error in retrieveing songs", message: "Please Try Again later. Error: \(err.localizedDescription)", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
                self.hideActivityIndicator(container: self.container, actInd: self.actInd)
                self.refreshControl?.endRefreshing()
                print("Error getting documents: \(err)")
            } else {
                var latestSongs = [[Any]]()
                
                if querySnapshot?.count == 0 {
                    print("no songs at all")
                    self.noSongLabel.isHidden = false
                } else {
                    self.noSongLabel.isHidden = true
                }
                
                //Disable the add song button if there are over max songs
                if querySnapshot!.documents.count >= Defaults.maxSongs {
                    self.isOverMaxSongs = true
                    
                    //Status
                    if allUserFirebaseData.data["status"] as? Int ?? 0 == 2 {
                        self.isOverMaxSongs = false
                    }
                }
                
                for document in querySnapshot!.documents {
                    //Get every single song's data
                    let songData = document.data()
                    let theSongName = songData["name"] ?? "Error"
                    let theArtistName = songData["artist"] ?? "Error"
                    let votes = songData["upvotes"] ?? 0
                    
                    let suggestor = songData["suggestor"] ?? "Error"
                    
                    let id = document.documentID
                    
                    //Set the latest song data
                    latestSongs.append([0, theSongName as! String, theArtistName as! String, votes as! Int, id, suggestor as! String])
                }
                
                //Check if there was previously saved data
                if voteData.songsVoted.count != 0 {
                    //Remove old songs and also update votes
                    var songsToRemove = [Int]()
                    for i in 0...voteData.songsVoted.count-1 {
                        var songIsInBothArrays = false
                        
                        for newSong in latestSongs {
                            //Check all IDs
                            if (voteData.songsVoted[i][4] as! String == newSong[4] as! String) {
                                songIsInBothArrays = true
                                voteData.songsVoted[i][3] = newSong[3] as! Int
                            }
                        }
                        
                        //Remove the song if it isnt part of latest songs
                        if !songIsInBothArrays {
                            songsToRemove.append(i)
                        }
                    }
                    //print("Removing \(songsToRemove)")
                    voteData.songsVoted.remove(at: songsToRemove)
                } else {
                    //If not then just continnue
                    voteData.songsVoted = latestSongs
                }
                
                //At this point, latest Songs should be larger
                //Now that you removed old songs, add new songs
                var songsToAdd = [[Any]]()
                for newSong in latestSongs {
                    //Check if you already have this song
                    var alreadyGotThisSong = false
                    for song in voteData.songsVoted {
                        if (newSong[4] as! String == song[4] as! String) {
                            alreadyGotThisSong = true
                        }
                    }
                    
                    //If Not then add it!
                    if !alreadyGotThisSong {
                        songsToAdd.append(newSong)
                    }
                }
                
                //print("Songs to add: \(songsToAdd)")
                
                //Now finally actually add these new songs to voteData *cant do it within the loop cause itll break the count
                for song in songsToAdd {
                    voteData.songsVoted.append(song)
                }
                
                //print("Latest Songs: \(latestSongs)")
                
                //print("The Final Songs: \(voteData.songsVoted)")
                
                self.getUserData()
            }
        }
    }
    
    func getUserData(){
        if Defaults.showUsersOnSongs {
            userNames.removeAll()
            userPics.removeAll()
            
            for _ in voteData.songsVoted {
                userNames.append("")
                userPics.append(UIImage(named: "safeProfilePic")!)
            }
            
            for i in 0..<voteData.songsVoted.count {
                //print("\(voteData.songsVoted.count - 1) vs \(i)")
                let id = voteData.songsVoted[i][5] as? String ?? "error"
                
                db.collection("users").document(id).collection("info").document("vital").getDocument { (snap, err) in
                    if err != nil {
                        self.userNames[i] = "error"
                        self.getPicture(profPic: 0, user: i)
                    }
                    if let snap = snap {
                        let data = snap.data()
                        self.userNames[i] = data?["name"] as? String ?? "error"
                        self.getPicture(profPic: data?["profilePic"] as? Int ?? 0, user: i)
                    }
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                self.sortSongsByVote()
            }
        } else {
            self.sortSongsByVote()
        }
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
                            //print("already saved \(profPic)=\(updated)")
                            self.userPics[user] = savedImage
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
                                        self.userPics[user] = image!
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
    
    func sortSongsByVote(){
        if voteData.songsVoted.count > 1{
            var thereWasASwap = true
            while thereWasASwap {
                thereWasASwap = false
                for i in 0...voteData.songsVoted.count - 2 {
                    let value1 = voteData.songsVoted[i][3] as? Int ?? 0
                    let value2 = voteData.songsVoted[i+1][3] as? Int ?? 0
                    
                    if value1 < value2 {
                        thereWasASwap = true
                        let temp = voteData.songsVoted[i]
                        voteData.songsVoted[i] = voteData.songsVoted[i+1]
                        voteData.songsVoted[i+1] = temp
                        
                        //Only sort if u actully show songs
                        if Defaults.showUsersOnSongs {
                            let temp2 = userNames[i]
                            userNames[i] = userNames[i+1]
                            userNames[i+1] = temp2
                            
                            let temp3 = userPics[i]
                            userPics[i] = userPics[i+1]
                            userPics[i+1] = temp3
                        }
                    }
                }
            }
        }
        //print(voteData.songsVoted)
        self.hideActivityIndicator(container: self.container, actInd: self.actInd)
        self.refreshControl?.endRefreshing()
        self.songView.reloadData()
    }
    
    func didVote() {
        sortSongsByVote()
    }
    
    //***********************************FORMATTING THE SONGS*************************************
    //For some odd reason iPhone SE requires this
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if Defaults.showUsersOnSongs {
            return CGSize(width: (self.songView.frame.width), height: 140)
        } else {
            return CGSize(width: (self.songView.frame.width), height: 100)
        }
    }
    
    //Make sure when you add collection view you add data source and delegate connections on storyboard
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return voteData.songsVoted.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "song", for: indexPath) as! songViewCell
        //Clear previous data
        cell.studentProfileImgView.image = UIImage()
        cell.studentName.text = ""
        
        //Cell Delegate for sorting after each vote
        cell.delegate = self
        
        //Student
        if Defaults.showUsersOnSongs {
            cell.studentViewPanelHeight.constant = 40
            
            //the pic
            cell.studentProfileImgView.clipsToBounds = true
            cell.studentProfileImgView.layer.cornerRadius = 34/2
            
            //No index out of bounds
            if indexPath.item < userPics.count  {
                cell.studentProfileImgView.image = userPics[indexPath.item]
            } else {
                cell.studentProfileImgView.image = UIImage(named: "safeProfilePic")
            }
            
            //no index out of bounds
            if indexPath.item < userNames.count {
                cell.studentName.text = userNames[indexPath.item]
            } else {
                cell.studentName.text = ""
            }
        } else {
            //hide the name
            cell.studentViewPanelHeight.constant = 0
            cell.studentNameTop.constant = 0
            cell.studentNameBottom.constant = 0
            cell.studentProfileImgViewTop.constant = 0
            cell.studentProfileImgViewBottom.constant = 0
        }
        
        
        //Show the respective data
        cell.songName.text = voteData.songsVoted[indexPath.item][1] as? String
        cell.artistName.text = voteData.songsVoted[indexPath.item][2] as? String
        cell.voteCount.text = String(voteData.songsVoted[indexPath.item][3] as! Int)
        cell.songID.text = voteData.songsVoted[indexPath.item][4] as? String
        
        //If The user has voted on song, display upvote image, if not display regular image
        if voteData.songsVoted[indexPath.item][0] as! Int == 1 {
            cell.voteArrow.image = UIImage(named: "voteArrowActive")
            cell.voteCount.textColor = UIColor(red: 140/255.0, green: 201/255.0, blue: 140/255.0, alpha: 1.0)
        } else if voteData.songsVoted[indexPath.item][0] as! Int == 2 {
            cell.voteArrow.image = UIImage(named: "supervoteActive")
            cell.voteCount.textColor = UIColor(red: 255/255.0, green: 171/255.0, blue: 35/255.0, alpha: 1.0)
        } else {
            cell.voteArrow.image = UIImage(named: "voteArrowEmpty")
            cell.voteCount.textColor = UIColor.darkText
        }
        
        //Drop shadow
        cell.layer.shadowColor = UIColor.lightGray.cgColor
        cell.layer.shadowOffset = CGSize(width:0,height: 2.0)
        cell.layer.shadowRadius = 2.0
        cell.layer.shadowOpacity = 1.0
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect:cell.bounds, cornerRadius:cell.contentView.layer.cornerRadius).cgPath
        
        cell.bringSubviewToFront(cell.voteArrowButtonView)
        cell.voteArrowButtonView.bringSubviewToFront(cell.upvotedButton)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("\(indexPath.item) voted")
    }
    
    
    //*****************************************REFRESHING DATA**************************************
    func addRefreshControl(){
        refreshControl = UIRefreshControl()
        refreshControl?.tintColor = UIColor.red
        refreshControl?.addTarget(self, action: #selector(refreshList), for: .valueChanged)
        //homeScrollView.addSubview(refreshControl!)
        songView.addSubview(refreshControl!)
    }
    
    @objc func refreshList(){
        supervoteCost = 0
        supervoteAmount = 0
        supervoteVotes.text = "Votes: "
        supervotePoints.text = "Points: "
        
        //Dont need to remove all as the getSongData checks if there is a new song and will get it
        //However. To delete songs, thats another issue
        getSongData()
    }
    
    func randomString(length: Int) -> String {
        //announcements are 20 long
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        return randomString
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! suggestASongController
        vc.onDoneBlock = { result in
            self.refreshList()
        }
    }
}
