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

import UserNotifications

//This is the struct that holds all of the users firebase data
struct allUserFirebaseData {
    static var data:[String:Any] = [:]
    static var profilePic:UIImage = UIImage(named: "blankUser")!
    static var didUpdateProfilePicture = false
}

class menuController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    //All Basic Menu Variables
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet var homeView: UIView!
    @IBOutlet weak var tapOutOfMenuButton: UIButton!
    @IBOutlet weak var dateToString: UILabel!
    @IBOutlet weak var dayNumber: UILabel!
    @IBOutlet weak var snowDay: UILabel!
    //@IBOutlet weak var ytVideoView: WKWebView!
    //@IBOutlet weak var ytVideoViewHeight: NSLayoutConstraint!
    @IBOutlet weak var calendarView: WKWebView!
    
    //Profile UI Variables
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var displayName: UILabel!
    @IBOutlet weak var displayEmail: UILabel!
    var menuShowing = false
    
    //Online Data Variables
    var newsData = [[String]]()
    let dayURL = URL(string: "https://staugustinechs.netfirms.com/stadayonetwo/")
    let newsURL = URL(string: "http://staugustinechs.ca/printable/")
    let busURL = URL(string: "http://net.schoolbuscity.com/")
    let ytSourceURL = URL(string: "https://staugustinechs.netfirms.com/stayt/")
    let backupURL = URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    let schoolCalendarURL = URL(string: "https://calendar.google.com/calendar/embed?showTitle=0&showTz=0&height=230&wkst=1&src=ycdsbk12.ca_f456pem6p0idarcilfuqiakaa8@group.calendar.google.com&color=%23004183&src=ycdsbk12.ca_4tepqngmnt9htbg435bmbpf3tg%40group.calendar.google.com&color=%23711616")
    
    //Annoucment Variables
    var counter = 0
    @IBOutlet weak var annoucView: UICollectionView!
    @IBOutlet weak var anncViewHeight: NSLayoutConstraint!
    
    //Refresh Variables
    var refreshControl: UIRefreshControl?
    @IBOutlet weak var homeScrollView: UIScrollView!
    
    //Database Variables
    var db: Firestore!
    var docRef: DocumentReference!
    
    //Filler Vars
    var fillerImage = UIImage(named: "blankUser")
    
    //***********************************SETTING UP EVERYTHING****************************************
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //News Data
        newsTask()
        
        //Disable webkit View Zoom
        //self.ytVideoView.scrollView.delegate = self
        
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
        profilePicture.layer.cornerRadius = 10
        
        //Cuts profile picture to the bounds. Dont show anything out of the bounds
        profilePicture.clipsToBounds = true
        
        //Top Bar Colour
        navigationController?.navigationBar.barTintColor = UIColor(red: 0.44, green: 0.14, blue: 0.14, alpha: 1.0)
        //Top Bar Text Colour
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        //Drop Shadow
        menuView.layer.shadowOpacity = 1
        menuView.layer.shadowRadius = 5
        
        //The Date
        dateToString.text = DateFormatter.localizedString(from: NSDate() as Date, dateStyle: DateFormatter.Style.full, timeStyle: DateFormatter.Style.none)
        
        //Remainin Tasks
        dayTask()
        snowTask()
        //ytTask()
        
        //*******************SET UP USER PROFILE ON MENU*****************
        let user = Auth.auth().currentUser
        //Profile Pic
        //let url = user?.photoURL
        //let data = try? Data(contentsOf: url!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
        //profilePicture.image = UIImage(data: data!)
        //Name
        displayName.text = user?.displayName
        //Email
        displayEmail.text = user?.email
        
        db.collection("users").document((user?.uid)!).getDocument { (docSnapshot, err) in
            if let docSnapshot = docSnapshot {
                allUserFirebaseData.data = docSnapshot.data()!
                self.getPicture(i: docSnapshot.data()!["profilePic"] as? Int ?? 0)
            } else {
                print("wow u dont exist")
            }
        }
        
        //This is only for using direct iframe
        //Set Up the Youtube Video Height
        //these values came from the websites iframe width of 640px and height of 360px
        //ytVideoViewHeight.constant = ytVideoView.frame.width*(9.0/16.0)
        
        //Load the calendar
        calendarView.load(URLRequest(url: schoolCalendarURL ?? backupURL!))
    }
    
    @IBAction func notify(_ sender: Any) {
        print("i get run notifications")
        let content = UNMutableNotificationContent()
        content.title = "Annc Title"
        content.body = "Make sure you bring all your donation money!"
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "timerDone", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        profilePicture.image = allUserFirebaseData.profilePic
        //If content size is still 0, just wait
        if annoucView.contentSize.height == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                if self.annoucView.contentSize.height < 300 {
                    self.anncViewHeight.constant = self.annoucView.contentSize.height
                } else {
                    self.anncViewHeight.constant = 300
                }
            }
        } else {
            if annoucView.contentSize.height < 300 {
                anncViewHeight.constant = annoucView.contentSize.height
            } else {
                anncViewHeight.constant = 300
            }
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
        return newsData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        //Compare which is longer. Department name or announcment name
        if newsData[indexPath.row][0].count < newsData[indexPath.row][1].count {
            //print("dynamic change based on announcement")
            //Dynamically change the cell size depending on the announcement length
            let approxWidthOfAnnouncementTextView = view.frame.width - 145
            let size = CGSize(width: approxWidthOfAnnouncementTextView, height: 1000)
            let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18.5)]
            let estimatedFrame = NSString(string: newsData[indexPath.row][1]).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
            
            return CGSize(width: view.frame.width, height: estimatedFrame.height + 15)
        } else {
            //print("dynamic change based on department")
            //Dynamically change the cell size depending on the department length
            let approxWidthOfAnnouncementTextView = 145
            let size = CGSize(width: approxWidthOfAnnouncementTextView, height: 1000)
            let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18)]
            let estimatedFrame = NSString(string: newsData[indexPath.row][0]).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
            
            return CGSize(width: view.frame.width, height: estimatedFrame.height + 10)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! newsViewCell
        //print("i get run data \(newsData[indexPath.item][0]) replacing \(cell.depName.text)")
        cell.anncDep.text = newsData[indexPath.item][0]
        cell.anncText.text = newsData[indexPath.item][1]
        cell.anncDep.centerVertically()
        cell.anncText.centerVertically()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("you pushed \(indexPath.item)")
    }
    
    //*****************************************REFRESHING DATA**************************************
    func addRefreshControl(){
        refreshControl = UIRefreshControl()
        refreshControl?.tintColor = UIColor.red
        refreshControl?.addTarget(self, action: #selector(refreshList), for: .valueChanged)
        homeScrollView.addSubview(refreshControl!)
    }
    
    @objc func refreshList(){
        print("I refreshed stuff indian tech tutorial style")
        //Day Number
        dayTask()
        newsTask()
        snowTask()
        ytTask()
        let user = Auth.auth().currentUser
        db.collection("users").document((user?.uid)!).getDocument { (docSnapshot, err) in
            if let docSnapshot = docSnapshot {
                allUserFirebaseData.data = docSnapshot.data()!
                self.getPicture(i: docSnapshot.data()!["profilePic"] as? Int ?? 0)
            } else {
                print("wow u dont exist")
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
    
    //************************************CHECK SNOW DAY************************************
    func snowTask() {
        let task3 = URLSession.shared.dataTask(with: busURL!) { (data, response, error) in
            if error != nil {
                //can't find website lol
                print("cant find bus city")
            } else{
                let htmlContent = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)!
                //Need this because UILabel cannot be called out of main thread
                DispatchQueue.main.async {
                    self.snowDay.isHidden = !self.checkSnowDay(content: htmlContent as String)
                }
            }
        }
        task3.resume()
    }
    
    func checkSnowDay(content: String) -> Bool {
        if content.lowercased().range(of: "snow day") != nil{
            //It is a snow day as it found the words "Snow day"
            return true
        }
        return false
    }
    
    //************************************Get Youtube Video************************************
    //Disable webkit view zooming
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.pinchGestureRecognizer?.isEnabled = false
    }
    //dont really need below data
    func ytTask() {
        /*
        let task4 = URLSession.shared.dataTask(with: ytSourceURL!) { (data, response, error) in
            if error != nil {
                //can't find website lol
            } else{
                let htmlContent = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)!
                let request = URLRequest(url: self.findYTVideo(content: htmlContent as String))
                DispatchQueue.main.async {
                    self.ytVideoView.load(request)
                }
            }
        }
        task4.resume()*/
        //self.ytVideoView.load(URLRequest(url: findYTVideo(content: "wow")))
    }
    func findYTVideo(content: String) -> URL{
        /*
        //The Start and End of the video
        let start = content.index(of: "<iframe src=\"")?.encodedOffset
        let end = content.index(of: "\" frameborder")?.encodedOffset
        
        //Characters is Depracted. Find a better solution in the future to find a string within a string
        let c = content.characters;
        let r = c.index(c.startIndex, offsetBy: (start! + 13))..<c.index(c.startIndex, offsetBy: (end! + 18))
        
        //print(content[r])
        //print(backupURL)
        
        //return URL(string: String(content[r])) ?? backupURL!
        
        //for now return the iframe*/
        return URL(string: "https://staugustinechs.netfirms.com/stayt/")!
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
        //Weekend, don't look for the Day number
        if (theDay.range(of:"Sunday") != nil) || (theDay.range(of:"Saturday") != nil){
            //Set the database reference
//            var dayNum = 3
//            docRef = db.collection("info").document("dayNumber")
//            docRef.getDocument { (docSnapshot, error) in
//                guard let docSnapshot = docSnapshot, docSnapshot.exists else { return }
//                //Should add error checking here lol
//                let myData = docSnapshot.data()
//                dayNum = myData?["dayNumber"] as! Int
//                //print("wowzers", dayNum)
//            }
//            while dayNum == 3 {
//                //Keep the display stuck until you get a response
//                //Find a better way to keep the async from being annoying and for sure returning a dayNum value other than 3
//            }
            return "It's a Weekend!"
        } else{
            //Look for last time "Day " is mentioned and output that
//            let c = content.characters;
            let dayFound = content.lastIndex(of: "Day ")!
            
            let range = dayFound..<(dayFound + 5)
            
            //let r = c.index(c.startIndex, offsetBy: dayFound)..<c.index(c.startIndex, offsetBy: dayFound + 5)
            //print(content[r])
            return String(content[range])
        }
    }
    
    //*********************************************GETTING NEWS**************************************************
    func newsTask(){
        let task2 = URLSession.shared.dataTask(with: newsURL!) { (data, response, error) in
            if error != nil {
                print("error in finding news page")
                self.newsData = [["No internet connection","Can't find news"]]
                let alert = UIAlertController(title: "Error in retrieveing School News", message: "Please Try Again later. Error: \(error!)", preferredStyle: .alert)
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
        
//        let c = content.characters;
//        let r = c.index(c.startIndex, offsetBy: (start! + 10))..<c.index(c.startIndex, offsetBy: end!)
        
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
