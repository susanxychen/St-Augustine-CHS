//
//  ViewController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-10-14.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit
import Foundation
import Firebase
import WebKit
import GoogleSignIn
import SafariServices
import UserNotifications

//This is the struct that holds all of the users firebase data
struct allUserFirebaseData {
    static var data:[String:Any] = [:]
    static var profilePic:UIImage = UIImage(named: "blankUser")!
    static var didUpdateProfilePicture = false
}

class menuController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, GIDSignInDelegate, GIDSignInUIDelegate {
    
    //Sign In Variables
    @IBOutlet weak var failedSignInButton: UIButton!
    @IBOutlet weak var newUserButton: UIButton!
    
    //All Basic Menu Variables
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet var homeView: UIView!
    @IBOutlet weak var tapOutOfMenuButton: UIButton!
    @IBOutlet weak var dateToString: UILabel!
    @IBOutlet weak var dayNumber: UILabel!
    
    //Scroll Height
    @IBOutlet weak var homeScrollViewHeight: NSLayoutConstraint!
    
    //Profile UI Variables
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var displayName: UILabel!
    @IBOutlet weak var displayEmail: UILabel!
    var menuShowing = false
    
    //Online Data Variables
    let dayURL = URL(string: "https://staugustinechs.netfirms.com/stadayonetwo/")
    let newsURL = URL(string: "http://staugustinechs.ca/printable/")
    
    //Annoucment Variables
    var newsData = [[String]]()
    @IBOutlet weak var annoucView: UICollectionView!
    @IBOutlet weak var anncViewHeight: NSLayoutConstraint!
    
    //Club Annc
    @IBOutlet weak var clubAnncView: UICollectionView!
    @IBOutlet weak var clubAnncHeight: NSLayoutConstraint!
    var clubNewsData = [[String:Any]]()
    
    //Refresh Variables
    var refreshControl: UIRefreshControl?
    @IBOutlet weak var homeScrollView: UIScrollView!
    
    //Database Variables
    var db: Firestore!
    var docRef: DocumentReference!
    
    //Filler Vars
    var fillerImage = UIImage(named: "blankUser")
    
    let viewAboveAllViews = UIView()
    
    //Calendar Vars
    @IBOutlet weak var calendarButton: UIButton!
    
    //Titan Tag Brightness
    var brightnessBeforeTT:CGFloat = 0
    
    //Colors
    @IBOutlet weak var clubAnnouncementsLabel: UILabel!
    @IBOutlet weak var dateAndDayView: UIView!
    @IBOutlet weak var gradientSocialView: UIView!
    
    var hasSignedInAtLoadedAtLeastOnce = false
    
    //***********************************SETTING UP EVERYTHING****************************************
    override func viewDidLoad() {
        super.viewDidLoad()
        brightnessBeforeTT = UIScreen.main.brightness
        calendarButton.isHidden = true
        viewAboveAllViews.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.7)
        viewAboveAllViews.frame = UIApplication.shared.keyWindow!.frame
        UIApplication.shared.keyWindow!.addSubview(viewAboveAllViews)
        definesPresentationContext = true
        GIDSignIn.sharedInstance()?.delegate = self
        GIDSignIn.sharedInstance()?.uiDelegate = self
        GIDSignIn.sharedInstance()?.signIn()
    }
    
    //**********************************SIGN IN TO GOOGLE AND FIREBASE*************************************
    func sign(inWillDispatch signIn: GIDSignIn!, error: Error!) {
        guard error == nil else {
            viewAboveAllViews.removeFromSuperview()
            self.performSegue(withIdentifier: "failedLogin", sender: self.failedSignInButton)
            return
        }
        print("Successful Redirection")
        viewAboveAllViews.removeFromSuperview()
    }
    
    //MARK: GIDSignIn Delegate
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!){
        UIApplication.shared.keyWindow!.addSubview(viewAboveAllViews)
        if (error == nil) {
            //Successfuly Signed In to Google
            print("Sucessfully sign in to google")
        } else {
            print(error.localizedDescription)
            viewAboveAllViews.removeFromSuperview()
            self.performSegue(withIdentifier: "failedLogin", sender: self.failedSignInButton)
            return
        }
        let checkEmail = user.profile.email
        
        if (checkEmail?.count ?? 100 < 8) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.viewAboveAllViews.removeFromSuperview()
                self.performSegue(withIdentifier: "failedLogin", sender: self.failedSignInButton)
            }
        }
        else if ((checkEmail?.hasSuffix("ycdsbk12.ca"))! || (checkEmail?.hasSuffix("ycdsb.ca"))! || (checkEmail == "sachstesterforapple@gmail.com")){
            //print("wow nice sign in")
            //************************Firebase Auth************************
            guard let authentication = user.authentication else {
                self.viewAboveAllViews.removeFromSuperview()
                self.performSegue(withIdentifier: "failedLogin", sender: self.failedSignInButton)
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
            
            Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
                self.viewAboveAllViews.removeFromSuperview()
                if let error = error {
                    print(error)
                    self.performSegue(withIdentifier: "failedLogin", sender: self.failedSignInButton)
                    return
                }
                //If Valid k12 account auto segue to main screen
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let lastSignIn = Auth.auth().currentUser?.metadata.lastSignInDate
                    let creation = Auth.auth().currentUser?.metadata.creationDate
                    
                    //if the user didnt come from the failed login as a new user
                    if ((lastSignIn == creation) && (!cameFromFailedLogin.didComeFromFailedScreen)) {
                        print(cameFromFailedLogin.didComeFromFailedScreen)
                        print("new user! take em through the sign in flow")
                        self.viewAboveAllViews.removeFromSuperview()
                        self.performSegue(withIdentifier: "signInFlow", sender: self.newUserButton)
                    } else {
                        self.getAllStartingInfoAfterSignIn()
                    }
                }
            }
        } else{
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.viewAboveAllViews.removeFromSuperview()
                self.performSegue(withIdentifier: "failedLogin", sender: self.failedSignInButton)
            }
        }
    }
    
    // Finished disconnecting |user| from the app successfully if |error| is |nil|.
    public func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!){
    }
    
    //************************************************************************************************
    func getAllStartingInfoAfterSignIn(){
        InstanceID.instanceID().getID { (result, error) in
            if let error = error {
                print("Error fetching remote instange ID: \(error)")
            } else if let result = result {
                print("Remote instance ID: \(result)") //POWERRRRRRRRRR
            }
        }
        
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print("Error fetching remote instance ID: \(error)")
            } else if let result = result {
                print("Remote instance ID token: \(result.token)")
                
                //self.instanceIDTokenMessage.text  = "Remote InstanceID token: \(result.token)"
            }
        }
        
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "Scada-Regular", size: 20)!]
        
        //Following will push a notification when out of the app 5 seconds later
        //Purely for testing
//        let content = UNMutableNotificationContent()
//        content.title = "title"
//        content.body = "body"
//        content.sound = UNNotificationSound.default
//
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
//
//        let request = UNNotificationRequest(identifier: "testIdentifier", content: content, trigger: trigger)
//
//        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        
        //News Data
        newsTask()
        
        homeScrollView.alwaysBounceVertical = true
        
        //Set Up
        // [START setup]
        let settings = FirestoreSettings()
        settings.areTimestampsInSnapshotsEnabled = true
        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
        //Add refresh control
        addRefreshControl()
        
        //Brings the menu to the front on top of everything and make sure it is out of view
        homeView.bringSubviewToFront(menuView)
        homeView.bringSubviewToFront(tapOutOfMenuButton)
        
        leadingConstraint.constant = -400
        
        //Change profile picture corners to round
        profilePicture.layer.borderWidth = 1.0
        profilePicture.layer.masksToBounds = false
        profilePicture.layer.borderColor = UIColor.white.cgColor
        profilePicture.layer.cornerRadius = 75/2
        profilePicture.clipsToBounds = true
        
        //Drop Shadow
        menuView.layer.shadowOpacity = 1
        menuView.layer.shadowRadius = 5
        
        //The Date
        dateToString.text = DateFormatter.localizedString(from: NSDate() as Date, dateStyle: DateFormatter.Style.full, timeStyle: DateFormatter.Style.none)
        
        //Remainin Tasks
        dayTask()
        //snowTask()
        
        //*******************SET UP USER PROFILE ON MENU*****************
        let user = Auth.auth().currentUser
        //Name
        displayName.text = user?.displayName
        //Email
        displayEmail.text = user?.email
        
        setupRemoteConfigDefaults()
        updateViewWithRCValues()
        fetchRemoteConfig()
        
        db.collection("users").document((user?.uid)!).getDocument { (docSnapshot, err) in
            if let docSnapshot = docSnapshot {
                allUserFirebaseData.data = docSnapshot.data()!
                self.hasSignedInAtLoadedAtLeastOnce = true
                self.getPicture(i: docSnapshot.data()!["profilePic"] as? Int ?? 0)
                self.getClubAnncs()
                self.updateDatabaseWithNewRemoteID()
            } else {
                print("wow u dont exist")
                let alert = UIAlertController(title: "Error", message: "You could not be located in the database. Try again later?", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: {
                    self.performSegue(withIdentifier: "failedLogin", sender: self.failedSignInButton)
                })
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //Adjust the brightness back to whatever it was
        UIScreen.animateBrightness(to: brightnessBeforeTT)
        profilePicture.image = allUserFirebaseData.profilePic
        if hasSignedInAtLoadedAtLeastOnce {
            self.refreshList()
        }
    }
    
    func setupRemoteConfigDefaults() {
        let defaultValues = [
            "primaryColor": UIColor(hex: "#8D1230") as NSObject,
            "darkerPrimary": UIColor(hex: "#460817") as NSObject,
            "accentColor": UIColor(hex: "#D8AF1C") as NSObject
        ]
        RemoteConfig.remoteConfig().setDefaults(defaultValues)
    }
    
    func fetchRemoteConfig(){
        RemoteConfig.remoteConfig().fetch(withExpirationDuration: 360) { [unowned self] (status, error) in
            guard error == nil else {
                print("cant get colours")
                return
            }
            print("yay")
            RemoteConfig.remoteConfig().activateFetched()
            self.updateViewWithRCValues()
        }
    }
    
    func updateViewWithRCValues() {
        //apply the remote config values here
        let primary = RemoteConfig.remoteConfig().configValue(forKey: "primaryColor").stringValue ?? "#8D1230"
        let darker = RemoteConfig.remoteConfig().configValue(forKey: "darkerPrimary").stringValue ?? "#460817"
        let accent = RemoteConfig.remoteConfig().configValue(forKey: "accentColor").stringValue ?? "#D8AF1C"
        let statusTwo = RemoteConfig.remoteConfig().configValue(forKey: "statusTwoPrimary").stringValue ?? "#040405"
        
        //Only change UI colours from hex if they are EXACTLY the proper hex format
        if primary.count == 7 {
            DefaultColours.primaryColor = UIColor(hex: primary)
        }
        
        if darker.count == 7 {
            DefaultColours.darkerPrimary = UIColor(hex: darker)
        }
        
        if accent.count == 7 {
            DefaultColours.accentColor = UIColor(hex: accent)
        }
        
        if statusTwo.count == 7 {
            DefaultColours.statusTwoPrimary = UIColor(hex: statusTwo)
        }
        
//        print(primary)
//        print(darker)
//        print(accent)
//        print(statusTwo)
        
        changeMenuControllerColours()
    }
    
    func changeMenuControllerColours() {
        //Colours
        gradientSocialView.backgroundColor = DefaultColours.primaryColor
        dateAndDayView.backgroundColor = DefaultColours.accentColor
        navigationController?.navigationBar.barTintColor = DefaultColours.primaryColor
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        clubAnnouncementsLabel.textColor = DefaultColours.primaryColor
    }
    
    func updateDatabaseWithNewRemoteID() {
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print("Error fetching remote instance ID: \(error)")
            } else if let result = result {
                //print("Remote instance ID token: \(result.token)")
                self.db.collection("users").document((Auth.auth().currentUser?.uid)!).setData(["msgToken": result.token], merge: true)
            }
        }
    }
    
    func getClubAnncs(){
        clubNewsData.removeAll()
        for club in allUserFirebaseData.data["clubs"] as! [String] {
            db.collection("announcements").whereField("club", isEqualTo: club).getDocuments { (snap, err) in
                if let err = err {
                    let alert = UIAlertController(title: "Error in retrieveing some club announcements", message: "Please try again later. \(err.localizedDescription)", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                }
                if let snap = snap {
                    for annc in snap.documents {
                        let data = annc.data()
                        //Check Dates
                        //Get the date the announcement was made
                        let timestamp: Timestamp = data["date"] as! Timestamp
                        let date: Date = timestamp.dateValue()
                        let weekAgoDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
                        
                        if date > weekAgoDate! {
                            self.clubNewsData.append(data)
                        }
                    }
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            //print(self.clubNewsData)
            self.sortAnncByDate()
        }
    }
    
    func sortAnncByDate() {
        if clubNewsData.count == 0 {
            self.clubAnncView.reloadData()
            return
        }
        
        if clubNewsData.count > 2 {
            var thereWasASwap = true
            while thereWasASwap {
                thereWasASwap = false
                for i in 0...clubNewsData.count-2 {
                    //Check if there is an image. If so also add a note saying there is an image
                    if clubNewsData[i]["img"] as! String != "" {
                        clubNewsData[i]["content"] = clubNewsData[i]["content"] as! String + " (This announcement has an image)"
                    }
                    
                    let timestamp1: Timestamp = clubNewsData[i]["date"] as! Timestamp
                    let date1: Date = timestamp1.dateValue()
                    let timestamp2: Timestamp = clubNewsData[i + 1]["date"] as! Timestamp
                    let date2: Date = timestamp2.dateValue()
                    
                    //Swap values
                    if date2 > date1 {
                        thereWasASwap = true
                        let temp = clubNewsData[i]
                        clubNewsData[i] = clubNewsData[i+1]
                        clubNewsData[i+1] = temp
                    }
                }
                //Check if there is an image. If so also add a note saying there is an image
                if clubNewsData[clubNewsData.count-1]["img"] as! String != "" {
                    clubNewsData[clubNewsData.count-1]["content"] = clubNewsData[clubNewsData.count-1]["content"] as! String + " (This announcement has an image)"
                }
            }
        } else if clubNewsData.count == 2 {
            let i = 0
            let timestamp1: Timestamp = clubNewsData[i]["date"] as! Timestamp
            let date1: Date = timestamp1.dateValue()
            let timestamp2: Timestamp = clubNewsData[i + 1]["date"] as! Timestamp
            let date2: Date = timestamp2.dateValue()
            
            //Check if there is an image. If so also add a note saying there is an image
            if clubNewsData[i]["img"] as! String != "" {
                clubNewsData[i]["content"] = clubNewsData[i]["content"] as! String + " (This announcement has an image)"
            }
            
            //Check if there is an image. If so also add a note saying there is an image
            if clubNewsData[1]["img"] as! String != "" {
                clubNewsData[1]["content"] = clubNewsData[1]["content"] as! String + " (This announcement has an image)"
            }
            
            //Swap values
            if date2 > date1 {
                let temp = clubNewsData[i]
                clubNewsData[i] = clubNewsData[i+1]
                clubNewsData[i+1] = temp
            }
        } else {
            //Check if there is an image. If so also add a note saying there is an image
            if clubNewsData[0]["img"] as! String != "" {
                clubNewsData[0]["content"] = clubNewsData[0]["content"] as! String + " (This announcement has an image)"
            }
        }
        self.clubAnncView.reloadData()
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
                            allUserFirebaseData.profilePic = savedImage
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
                                        allUserFirebaseData.profilePic = image!
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
    
    //*****************************************Annoucments Table**************************************
    //Make sure when you add collection view you add data source and delegate connections on storyboard
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == clubAnncView {
            return clubNewsData.count
        } else {
            return newsData.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == clubAnncView {
            let theFont = UIFont(name: "Scada-Regular", size: 18)!
            //Dynamically change the cell size depending on the announcement length
            let size = CGSize(width: view.frame.width - 8, height: 1000)
            //Get an approximation of the title size
            let attributesTitle = [NSAttributedString.Key.font: theFont]
            let estimatedFrameTitle = NSString(string: clubNewsData[indexPath.item]["title"] as! String).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributesTitle, context: nil)
            
            //Get an approximation of the description size
            let attributesContent = [NSAttributedString.Key.font: theFont]
            let estimatedFrameContent = NSString(string: clubNewsData[indexPath.item]["content"] as! String).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributesContent, context: nil)
            let theHeight = estimatedFrameContent.height + estimatedFrameTitle.height + 125
            
            //Also add the height of the picture and the announcements and the space inbetween
            return CGSize(width: view.frame.width, height: theHeight)
        } else {
            //Dynamically change the cell size depending on the announcement length
            let approxWidthOfAnnouncementTextView = view.frame.width - 8
            var size = CGSize(width: approxWidthOfAnnouncementTextView, height: 1000)
            var attributes = [NSAttributedString.Key.font: UIFont(name: "Scada-Regular", size: 18)!]
            var estimatedFrame = NSString(string: newsData[indexPath.row][1]).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
            
            let contentHeight =  estimatedFrame.height + 10
            size = CGSize(width: approxWidthOfAnnouncementTextView, height: 1000)
            attributes = [NSAttributedString.Key.font: UIFont(name: "Scada-Regular", size: 18)!]
            estimatedFrame = NSString(string: newsData[indexPath.row][0]).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
            
            let titleHeight = estimatedFrame.height + 10

            
            return CGSize(width: view.frame.width, height: contentHeight + titleHeight + 8)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let height = self.annoucView.contentSize.height + self.clubAnncView.contentSize.height + 300
        self.anncViewHeight.constant = self.annoucView.contentSize.height + 10
        self.clubAnncHeight.constant = self.clubAnncView.contentSize.height + 10
        
        //If the screen is too small to fit all announcements, just change the height to whatever it is
        if height > UIScreen.main.bounds.height {
            self.homeScrollViewHeight.constant = height
        } else {
            self.homeScrollViewHeight.constant = UIScreen.main.bounds.height
        }
        
        if collectionView == annoucView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! newsViewCell
            //print("i get run data \(newsData[indexPath.item][0]) replacing \(cell.depName.text)")
            
            cell.contentView.layer.cornerRadius = 10
            cell.contentView.layer.borderWidth = 1.0
            
            cell.contentView.layer.borderColor = UIColor.clear.cgColor
            cell.contentView.layer.masksToBounds = true
            
            cell.layer.shadowColor = UIColor.gray.cgColor
            cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
            cell.layer.shadowRadius = 2.0
            cell.layer.shadowOpacity = 1.0
            cell.layer.masksToBounds = false
            cell.layer.shadowPath = UIBezierPath(roundedRect:cell.bounds, cornerRadius:cell.contentView.layer.cornerRadius).cgPath
            
            cell.anncDep.text = newsData[indexPath.item][0]
            cell.anncText.text = newsData[indexPath.item][1]
            cell.anncDep.centerVertically()
            cell.anncText.centerVertically()
            
            let approxWidthOfAnnouncementTextView = cell.anncText.frame.width
            var size = CGSize(width: approxWidthOfAnnouncementTextView, height: 1000)
            var attributes = [NSAttributedString.Key.font: UIFont(name: "Scada-Regular", size: 18)!]
            var estimatedFrame = NSString(string: newsData[indexPath.row][1]).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
            
            let contentHeight =  estimatedFrame.height + 10
            cell.contentHeight.constant = contentHeight
            
            size = CGSize(width: approxWidthOfAnnouncementTextView, height: 1000)
            attributes = [NSAttributedString.Key.font: UIFont(name: "Scada-Regular", size: 18)!]
            estimatedFrame = NSString(string: newsData[indexPath.row][0]).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
            
            let titleHeight = estimatedFrame.height + 10
            
            cell.titleHeight.constant = titleHeight
            
            //self.anncViewHeight.constant = self.annoucView.contentSize.height + 10
            
            calendarButton.isHidden = false
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "clubNews", for: indexPath) as! mainClubNewsCell
            
            //Get the date the announcement was made
            let timestamp: Timestamp = clubNewsData[indexPath.row]["date"] as! Timestamp
            let date: Date = timestamp.dateValue()
            
            //colours
            cell.clubLabel.backgroundColor = DefaultColours.accentColor
            cell.dateLabel.backgroundColor = DefaultColours.primaryColor
            cell.titleLabel.textColor = DefaultColours.primaryColor
            
            //text
            cell.clubLabel.text = clubNewsData[indexPath.item]["clubName"] as? String ?? "error"
            cell.dateLabel.text = DateFormatter.localizedString(from: date, dateStyle: DateFormatter.Style.full, timeStyle: DateFormatter.Style.none)
            cell.titleLabel.text = clubNewsData[indexPath.item]["title"] as? String ?? "error"
            cell.contentLabel.text = clubNewsData[indexPath.item]["content"] as? String ?? "error"
            
            let theFont = UIFont(name: "Scada-Regular", size: 18)
            let size = CGSize(width: view.frame.width, height: 1000)
            let attributesContent = [NSAttributedString.Key.font: theFont]
            let estimatedFrameContent = NSString(string: clubNewsData[indexPath.item]["content"] as! String).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributesContent as [NSAttributedString.Key : Any], context: nil)
            cell.contentHeight.constant = estimatedFrameContent.height + 20
            
            let estimatedtitleContent = NSString(string: clubNewsData[indexPath.item]["title"] as! String).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributesContent as [NSAttributedString.Key : Any], context: nil)
            cell.titleHeight.constant = estimatedtitleContent.height + 20
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("you pushed \(indexPath.item)")
    }
    
    @IBAction func calendarButtonPushed(_ sender: Any) {
        var didAddCalendar = false
        
        if let x = UserDefaults.standard.object(forKey: "didAddCalendar") as? Bool {
           didAddCalendar = x
        }
        
        if didAddCalendar {
            let interval = Int(Date().timeIntervalSinceReferenceDate)
            let url = URL(string: String(format: "calshow:%ld", interval))
            if let url = url {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        } else {
            //Prompt user to add calendar
            UserDefaults.standard.set(true, forKey: "didAddCalendar")
            guard let url = URL(string: "https://calendar.google.com/calendar/r?cid=ycdsbk12.ca_f456pem6p0idarcilfuqiakaa8@group.calendar.google.com&cid=ycdsbk12.ca_4tepqngmnt9htbg435bmbpf3tg@group.calendar.google.com") else { return }
            let svc = SFSafariViewController(url: url)
            present(svc, animated: true, completion: nil)
        }
    }

    
    //*****************************************REFRESHING DATA**************************************
    func addRefreshControl(){
        refreshControl = UIRefreshControl()
        refreshControl?.tintColor = UIColor.red
        refreshControl?.addTarget(self, action: #selector(refreshList), for: .valueChanged)
        homeScrollView.addSubview(refreshControl!)
    }
    
    @objc func refreshList(){
        //Colours!!
        setupRemoteConfigDefaults()
        updateViewWithRCValues()
        fetchRemoteConfig()
        
        print("I refreshed stuff indian tech tutorial style")
        //Day Number
        dayTask()
        newsTask()
        //snowTask()
        let user = Auth.auth().currentUser
        db.collection("users").document((user?.uid)!).getDocument { (docSnapshot, err) in
            if let docSnapshot = docSnapshot {
                allUserFirebaseData.data = docSnapshot.data()!
                self.getPicture(i: docSnapshot.data()!["profilePic"] as? Int ?? 0)
                self.getClubAnncs()
                self.updateDatabaseWithNewRemoteID()
            } else {
                print("wow u dont exist")
                let alert = UIAlertController(title: "Error", message: "You could not be located in the database. Try again later?", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: {
                    self.performSegue(withIdentifier: "failedLogin", sender: self.failedSignInButton)
                })
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.refreshControl?.endRefreshing()
        }
    }
    
    //******************************************DEALING WITH THE MENU***************************************
    @IBAction func openMenu(_ sender: Any) {
        //Show the menu by changing the left constraint
        if (menuShowing) {
            leadingConstraint.constant = -400
        } else{
            leadingConstraint.constant = 0
        }
        //animate it
        UIView.animate(withDuration: 0.3, animations: {self.view.layoutIfNeeded()})
        view.layoutIfNeeded()
        menuShowing = !menuShowing
    }
    
    @IBAction func tapOutOfMenu(_ sender: Any) {
        //Hide the menu
        leadingConstraint.constant = -400
        UIView.animate(withDuration: 0.3, animations: {self.view.layoutIfNeeded()})
        view.layoutIfNeeded()
    }
    
    //User can swipe left or right to hide and show menu
    @IBAction func leftSwipe(_ sender: Any) {
        //Hide the menu
        leadingConstraint.constant = -400
        UIView.animate(withDuration: 0.3, animations: {self.view.layoutIfNeeded()})
        view.layoutIfNeeded()
    }
    
    @IBAction func rightSwipe(_ sender: Any) {
        //Show the menu
        leadingConstraint.constant = 0
        UIView.animate(withDuration: 0.3, animations: {self.view.layoutIfNeeded()})
        view.layoutIfNeeded()
    }
    
    //*************************************UPDATE THE DAY NUMBER**************************************
    func dayTask() {
        var dayTemp = "Error Occured"
        let task = URLSession.shared.dataTask(with: dayURL!) { (data, response, error) in
            if error != nil {
                DispatchQueue.main.async {
                    self.dayNumber.text = "Cannot find day website URL"
                }
            } else{
                let htmlContent = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)!
                dayTemp = self.updateDay(content: htmlContent as String)
                
                //Need this because UILabel cannot be called out of main thread
                DispatchQueue.main.async {
                    self.dayNumber.text = dayTemp
                }
            }
        }
        task.resume()
    }
    
    func updateDay(content: String) -> String{
        let theDay = DateFormatter.localizedString(from: NSDate() as Date, dateStyle: DateFormatter.Style.full, timeStyle: DateFormatter.Style.none)
        if (theDay.range(of:"Sunday") != nil) || (theDay.range(of:"Saturday") != nil){
            db.collection("info").document("dayNumber").getDocument { (snap, err) in
                if let err = err {
                    self.dayNumber.text = "Error: \(err.localizedDescription)"
                }
                if let snap = snap {
                    let data = snap.data()!
                    let fridayDayNumber = data["dayNumber"] as! String
                    
                    if fridayDayNumber == "1" {
                        self.dayNumber.text = "Monday will be Day 2"
                    } else {
                        self.dayNumber.text = "Monday will be Day 1"
                    }
                    
                }
            }
            
            return "Day "
        } else{
            //Look for last time "Day " is mentioned and output that
            let dayFound = content.lastIndex(of: "Day ")!
            let range = dayFound..<(dayFound + 5)

            return String(content[range])
        }
    }
    
    //*********************************************GETTING NEWS**************************************************
    func newsTask(){
        let task2 = URLSession.shared.dataTask(with: newsURL!) { (data, response, error) in
            if let error = error {
                print("error in finding news page")
                self.newsData = [["No internet connection","Can't find news"]]
                let alert = UIAlertController(title: "Error in retrieveing School News", message: "Please Try Again later. Error: \(error.localizedDescription)", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
                DispatchQueue.main.async {
                    self.annoucView.reloadData()
                }
            } else{
                let htmlContent = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)!
                self.newsData = self.processNewsSite(content: htmlContent as String)
                DispatchQueue.main.async {
                    self.annoucView.reloadData()
                }
            }
        }
        task2.resume()
    }
    
    func processNewsSite(content: String) -> [[String]]{
        //Content is the website code
        //GET STRING BETWEEN 'ancmnt = "' and '".split(",");' AND SPLIT THE DIFFERENT NEWS ITEMS (SEPARATED BY COMMAS)
        
        //The Start and End to Get Annoucments
        let start = content.index(of: "ancmnt = \"")?.encodedOffset
        let end = content.index(of: "\".split(\",\");")?.encodedOffset
        
        let range = (start! + 10)..<end!
        
        var notFormattedCodedNews = String(content[range]).components(separatedBy: ",")
        var finalNews = Array(repeating: Array(repeating: "", count: 2), count: notFormattedCodedNews.count)
        
        for item in 0..<notFormattedCodedNews.count {
            let temp = notFormattedCodedNews[item].components(separatedBy: "%24%25-%25%24")
            
            finalNews[item][0] = temp[0].decodeUrl() ?? "Cannot Decode Name"
            
            if finalNews[item][0].contains("No Announcements Today"){
                finalNews[item][1] = ""
            }
            else{
                finalNews[item][1] = temp[1].decodeUrl() ?? "Cannot Decode Announcement"
            }
        }
        return finalNews
    }
    
    //Make the status bar white
    func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.lightContent;
    }
}
