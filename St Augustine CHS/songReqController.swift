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
    //Voted, Name, Artist, Votes, ID
    static var songsVoted:[[Any]] = []
}

class songReqController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    //button used for segue
    @IBOutlet weak var suggestASong: UIButton!
    
    let actInd: UIActivityIndicatorView = UIActivityIndicatorView()
    let container: UIView = UIView()
    
    //The Database
    var db: Firestore!
    var docRef: DocumentReference!
    
    @IBOutlet weak var songView: UICollectionView!
    
    var isOverMaxSongs = false
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let lpgr: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(gestureRecognizer:)))
        lpgr.minimumPressDuration = 0.5
        //lpgr.delegate = self as? UIGestureRecognizerDelegate
        lpgr.delaysTouchesBegan = true
        self.songView.addGestureRecognizer(lpgr)
        
        
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
        
        supervoteSlider.minimumValue = Float(Defaults.supervoteMin)
        supervoteSlider.maximumValue = Float(allUserFirebaseData.data["points"] as! Int)
        
        //Get the data of whether you voted or not
        if let x = UserDefaults.standard.object(forKey: "songsVoted") as? [[Any]]{
            voteData.songsVoted = x
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
            //Disable super vote if user has already voted
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
                    if allUserFirebaseData.data["status"] as? Int ?? 0 == 2 {
                        self.isOverMaxSongs = true
                    }
                }
                
                for document in querySnapshot!.documents {
                    //Get every single song's data
                    let songData = document.data()
                    let theSongName = songData["name"] ?? "Error"
                    let theArtistName = songData["artist"] ?? "Error"
                    let votes = songData["upvotes"] ?? 0
                    let id = document.documentID
                    
                    if (votes as! CGFloat).isNaN {
                        let alert = UIAlertController(title: "Error in retrieveing songs", message: "Please Try Again later", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                        self.hideActivityIndicator(container: self.container, actInd: self.actInd)
                        self.refreshControl?.endRefreshing()
                        return
                    }
                    
                    //Set the latest song data
                    latestSongs.append([0, theSongName as! String, theArtistName as! String, votes as! Int, id])
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
                
                self.sortSongsByVote()
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
                    }
                }
            }
        }
        print(voteData.songsVoted)
        self.hideActivityIndicator(container: self.container, actInd: self.actInd)
        self.refreshControl?.endRefreshing()
        self.songView.reloadData()
    }
    
    //***********************************FORMATTING THE SONGS************************************* 
    //RETURN CLUB COUNT
    //Make sure when you add collection view you add data source and delegate connections on storyboard
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return voteData.songsVoted.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "song", for: indexPath) as! songViewCell
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
        
        cell.bringSubviewToFront(cell.upvotedButton)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(indexPath.item)
    }
 
    //*******************ADD A SONG******************
    //put a reqeust a song thing here
    
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
