//
//  clubListController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-10-19.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit
import Firebase

struct clubListDidUpdateClubDetails {
    static var clubAdminUpdatedData: Bool!
}

class clubListController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet var outerListView: UIView!
    @IBOutlet weak var clubListView: UICollectionView!
    @IBOutlet weak var notLoadList: UILabel!
    
    //The Database
    var db: Firestore!
    var docRef: DocumentReference!
    
    let tempImg = UIImage(named: "space")
    var clubNames = [String]()
    let clubs = [String]()
    var banners = [UIImage]()
    var allClubsData = [[String: Any]]()
    var clubIDs = [String]()
    var selectedClub = Int()
    @IBOutlet weak var chooseAClubButton: UIButton!
    
    //Toolbar vars
    let toolbar = UIToolbar()
    @IBOutlet weak var addAClubButton: UIButton!
    
    //Refresh Controls
    var refreshControl: UIRefreshControl?
    let actInd: UIActivityIndicatorView = UIActivityIndicatorView()
    let container: UIView = UIView()
    
    let overlayView = UIView(frame: UIScreen.main.bounds)
    
    //Showing Personal Clubs
    var viewingPersonalClubs: Bool!
    var clubsYouAreNotAPartOf = [[String: Any]]()
    var personalClubIDs = [String]()
    var personalClubNames = [String]()
    var personalClubBanners = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var iAmConneted = false
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if let connected = snapshot.value as? Bool, connected {
                print("Connected")
                iAmConneted = true
                self.getPersonalClubs()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0){
                    print(iAmConneted)
                    if !iAmConneted{
                        print("Not connected")
                        let alert = UIAlertController(title: "Error", message: "You are not connected to the internet", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                        self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                        self.clubListView.isHidden = true
                        self.notLoadList.text = "No internet"
                        self.notLoadList.isHidden = false
                    }
                }
            }
        })
        
        overlayView.frame = UIApplication.shared.keyWindow!.frame
        
        
        clubListDidUpdateClubDetails.clubAdminUpdatedData = false
        
        viewingPersonalClubs = true
        
        clubListView.alwaysBounceVertical = true
        
        if allUserFirebaseData.data["status"] as? Int ?? 0 >= 1 {
            //create a new button
            let button = UIButton(type: .custom)
            button.setImage(UIImage(named: "addClub"), for: .normal)
            //add function for button
            button.addTarget(self, action: #selector(addClubButtonPressed), for: .touchUpInside)
            button.frame = CGRect(x: 0, y: 0, width: 48, height: 48)
            
            let barButton = UIBarButtonItem(customView: button)
            //assign button to navigationbar
            self.navigationItem.rightBarButtonItem = barButton
        }
        
        //Add refresh control
        addRefreshControl()
        
        //Set up the activity Indicator
        showActivityIndicatory(uiView: self.view, container: container, actInd: actInd, overlayView: self.overlayView)
        clubListView.isHidden = true
        
        //Set Up
        // [START setup]
        let settings = FirestoreSettings()
        settings.areTimestampsInSnapshotsEnabled = true
        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
        //once clubs is done, get pics
        //Test to see if you already have downloaded the data onto the phone
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print(clubListDidUpdateClubDetails.clubAdminUpdatedData)
        if clubListDidUpdateClubDetails.clubAdminUpdatedData {
            print("refrshing clubList after editing data somewhere")
            showActivityIndicatory(uiView: self.view, container: container, actInd: actInd, overlayView: self.overlayView)
            refreshList()
        }
    }
    
    var personalClubReferences = [String]()
    
    //***********************************GET PERSONAL CLUB DATA*************************************
    func getPersonalClubs(){
        //Get the user's clubs
        let user = Auth.auth().currentUser
        let docRef = db.collection("users").document((user?.uid)!)
        docRef.getDocument { (document, error) in
            if let error = error {
                let alert = UIAlertController(title: "Error in retrieveing your info", message: "Please Try Again later. Error: \(error.localizedDescription)", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
                self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                self.notLoadList.text = "Error"
                self.notLoadList.isHidden = false
            }
            if let document = document, document.exists {
                let userData = document.data()
                self.personalClubReferences = userData?["clubs"] as! [String]
                self.getPersonalClubsData()
            } else {
                print("Document does not exist")
            }
        }
    }
    
    var personaClubsData = [[String : Any]]()
    func getPersonalClubsData(){
        if personalClubReferences.count == 0 {
            print("Person has no clubs")
            self.clubListView.reloadData()
            self.refreshControl?.endRefreshing()
            let alert = UIAlertController(title: "No Clubs Available", message: "Join some clubs!", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .cancel) { (action:UIAlertAction) in
                print("OK I will join clubs");
            }
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            self.clubListView.isHidden = false
            self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
            //self.notLoadList.text = "Join Some Clubs!"
            //self.notLoadList.isHidden = false
        } else{
            var counterTemp = 0
            for i in 0...personalClubReferences.count-1 {
                let docRef = db.collection("clubs").document(personalClubReferences[i])
                docRef.getDocument { (document, error) in
                    if let error = error {
                        let alert = UIAlertController(title: "Error in retrieveing Clubs", message: "Please Try Again later. Error: \(error.localizedDescription)", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                        self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                    }
                    if let document = document, document.exists {
                        self.personaClubsData.append(document.data()!)
                        //Also keep all the doucment ids
                        self.personalClubIDs.append(document.documentID)
                        
                        //Set the names of clubs
                        let clubData = document.data()
                        //print(clubData)
                        let clubName = clubData!["name"]
                        self.personalClubNames.append(clubName as! String)
                        
                        //Check to see if there are more than 1 club. Make array size equal to number of clubs
                        counterTemp += 1
                        if self.personalClubBanners.count < counterTemp {
                            self.personalClubBanners.append(self.tempImg!)
                        }
                    } else {
                        print("Document does not exist")
                    }
                    if i == self.personalClubReferences.count - 1{
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.sortClubsAlphaOrder()
                        }
                    }
                }
            }
        }
    }
    
    //***********************************GET ALL CLUB DATA************************************* 
    func getClubs() {
        //print("main thread")
        var counterTemp = 0
        
        self.db.collection("clubs").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                let alert = UIAlertController(title: "Error in retrieveing Clubs", message: "Please Try Again later. Error: \(err.localizedDescription)", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
                self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
            } else {
                for document in querySnapshot!.documents {
                    //Also keep all the doucment ids
                    self.clubIDs.append(document.documentID)
                    //Get every single club's data
                    self.allClubsData.append(document.data())
                    
                    //Set the names of clubs
                    let clubData = document.data()
                    //print(clubData)
                    let clubName = clubData["name"]
                    self.clubNames.append(clubName as! String)
                    
                    //Check to see if there are more than 1 club. Make array size equal to number of clubs
                    counterTemp += 1
                    if self.banners.count < counterTemp {
                        self.banners.append(self.tempImg!)
                    }
                }
                print("just finsihed names")
                self.sortClubsAlphaOrder()
            }
        }
    }
    
    //************************************FORMAT THE CLUB DATA************************************
    func sortClubsAlphaOrder(){
        print("sort alpha")
        //Only sort when have more than 1 club
        if (personaClubsData.count >= 2) || (allClubsData.count >= 2){
            if viewingPersonalClubs {
                var thereWasASwap = true
                while thereWasASwap {
                    thereWasASwap = false
                    for i in 0...personaClubsData.count-2 {
                        let name1: String = personaClubsData[i]["name"] as! String
                        let name2: String = personaClubsData[i+1]["name"] as! String
                        
                        let shortestLength: Int
                        if name1.count < name2.count {
                            //print("\(name1) is shorter")
                            shortestLength = name1.count
                        } else {
                            //print("\(name2) is shorter")
                            shortestLength = name2.count
                        }
                        
                        for j in 0...shortestLength-1 {
                            //Compare Alphabetically
                            let index1 = name1.index(name1.startIndex, offsetBy: j)
                            let index2 = name2.index(name2.startIndex, offsetBy: j)
                            let character1 = Character((String(name1[index1]).lowercased()))
                            let character2 = Character((String(name2[index2]).lowercased()))
                            
                            //print("\(character1) and \(character2)")
                            
                            if character2 < character1 {
                                //print("done swap")
                                thereWasASwap = true
                                let temp = personaClubsData[i]
                                personaClubsData[i] = personaClubsData[i+1]
                                personaClubsData[i+1] = temp
                                
                                let temp2 = personalClubNames[i]
                                personalClubNames[i] = personalClubNames[i+1]
                                personalClubNames[i+1] = temp2
                                
                                let temp3 = personalClubIDs[i]
                                personalClubIDs[i] = personalClubIDs[i+1]
                                personalClubIDs[i+1] = temp3
                                
                                break
                            } else if character1 == character2 {
                                //print("equal so they need to go one higher")
                            } else {
                                //print("not equal")
                                break
                            }
                        }
                    }
                }
            } else {
                var thereWasASwap = true
                while thereWasASwap {
                    thereWasASwap = false
                    for i in 0...allClubsData.count-2 {
                        let name1: String = allClubsData[i]["name"] as! String
                        let name2: String = allClubsData[i+1]["name"] as! String
                        
                        let shortestLength: Int
                        if name1.count < name2.count {
                            //print("\(name1) is shorter")
                            shortestLength = name1.count
                        } else {
                            //print("\(name2) is shorter")
                            shortestLength = name2.count
                        }
                        
                        for j in 0...shortestLength-1 {
                            //Compare Alphabetically
                            let index1 = name1.index(name1.startIndex, offsetBy: j)
                            let index2 = name2.index(name2.startIndex, offsetBy: j)
                            let character1 = Character((String(name1[index1]).lowercased()))
                            let character2 = Character((String(name2[index2]).lowercased()))
                            
                            //print("\(character1) and \(character2)")
                            
                            if character2 < character1 {
                                //print("done swap")
                                thereWasASwap = true
                                let temp = allClubsData[i]
                                allClubsData[i] = allClubsData[i+1]
                                allClubsData[i+1] = temp
                                
                                let temp2 = clubNames[i]
                                clubNames[i] = clubNames[i+1]
                                clubNames[i+1] = temp2
                                
                                let temp3 = clubIDs[i]
                                clubIDs[i] = clubIDs[i+1]
                                clubIDs[i+1] = temp3
                                break
                            } else if character1 == character2 {
                                //print("equal so they need to go one higher")
                            } else {
                                //print("not equal")
                                break
                            }
                        }
                    }
                }
            }
            
        }
        
        if viewingPersonalClubs {
            getClubImages(theData: personaClubsData)
        } else {
            getClubImages(theData: allClubsData)
        }
    }
    
    func getClubImages(theData: [[String: Any]]) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        //Go through each picture for each club
        for clubNum in 0...theData.count-1{
            //Set up the image
            let imageName = theData[clubNum]["img"] as! String
            //print(imageName)
            let bannerRef = storageRef.child("clubBanners/\(imageName)")
            
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
                            if let savedImage = self.getSavedImage(named: "\(imageName)-\(updated)"){
                                print("already saved \(imageName)-\(updated)")
                                if self.viewingPersonalClubs{
                                    //print(self.personalClubBanners)
                                    self.personalClubBanners[clubNum] = savedImage
                                } else {
                                    //print(self.banners)
                                    self.banners[clubNum] = savedImage
                                }
                                if (clubNum == theData.count-1) {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        self.showingPersonalClubsOrNot()
                                    }
                                }
                            } else {
                                // Create a reference to the file you want to download
                                bannerRef.downloadURL { url, error in
                                    if let error = error {
                                        // Handle any errors
                                        let alert = UIAlertController(title: "Error in retrieveing some club images", message: "Please try again later. \(error.localizedDescription)", preferredStyle: .alert)
                                        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                                        alert.addAction(okAction)
                                        self.present(alert, animated: true, completion: nil)
                                        print(error)
                                        if (clubNum == theData.count-1) {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                self.showingPersonalClubsOrNot()
                                            }
                                        }
                                    } else {
                                        print("img gonna get new image \(imageName)")
                                        // Get the download URL
                                        var image: UIImage?
                                        let data = try? Data(contentsOf: url!)
                                        if let imageData = data {
                                            image = UIImage(data: imageData)!
                                            if self.viewingPersonalClubs {
                                                self.personalClubBanners[clubNum] = image!
                                            } else {
                                                self.banners[clubNum] = image!
                                            }
                                            self.clearImageFolder(imageName: "\(imageName)-\(updated)")
                                            self.saveImageDocumentDirectory(image: image!, imageName: "\(imageName)-\(updated)")

                                            if (clubNum == theData.count-1) {
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                    self.showingPersonalClubsOrNot()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func showingPersonalClubsOrNot(){
        if viewingPersonalClubs {
            //Save the data to the phone
            self.clubListView.isHidden = false
            self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
            self.clubListView.reloadData()
            self.refreshControl?.endRefreshing()
        } else {
            //Calculate which clubs you are not part of and remove them 
            var clubsYouAreNotPartOf = allClubsData
            var indexesToRemove = [Int]()
            for i in 0...allClubsData.count-1 {
                for personalClub in personaClubsData {
                    if personalClub["name"] as! String == allClubsData[i]["name"] as! String {
                        indexesToRemove.append(i)
                    }
                }
            }
            //Remove the clubs you are not part of
            clubsYouAreNotPartOf.remove(at: indexesToRemove)
            banners.remove(at: indexesToRemove)
            clubNames.remove(at: indexesToRemove)
            
            self.clubsYouAreNotAPartOf = clubsYouAreNotPartOf
            
            //Load the data
            self.clubListView.isHidden = false
            self.hideActivityIndicator(uiView: self.view, container: container, actInd: actInd, overlayView: self.overlayView)
            self.clubListView.reloadData()
            self.refreshControl?.endRefreshing()
        }
    }
    
    //*************************************FORMATTING THE CLUBS*************************************
    //Make sure when you add collection view you add data source and delegate connections on storyboard
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //print("i do get run club list")
        if viewingPersonalClubs{
            return personalClubNames.count
        } else {
            return clubNames.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "club", for: indexPath) as! clubViewCell
        
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
        
        if viewingPersonalClubs {
            cell.name.text = personalClubNames[indexPath.item]
            cell.banner.image = personalClubBanners[indexPath.item]
        } else {
            cell.name.text = clubNames[indexPath.item]
            cell.banner.image = banners[indexPath.item]
        }
        
        cell.sendSubviewToBack(cell.banner)
        cell.bringSubviewToFront(cell.name)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedClub = indexPath.item
        //print("I am going to club num \(selectedClub)")
        addAClub = false
        //Only segue once you have proper data
        self.performSegue(withIdentifier: "showClub", sender: self.chooseAClubButton)
    }
    
    
    //*************************************FORMATTING THE FOOTER*************************************
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 75)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "showOtherClubs", for: indexPath) as! clubListFooterViewCell
            view.bringSubviewToFront(view.showOtherClubsButton)
            view.showOtherClubsButton.addTarget(self, action: #selector(self.showOtherClubsButtonTapped), for: .touchUpInside)
            
            if viewingPersonalClubs {
                view.showOtherClubsButton.setTitle("Show All Clubs", for: .normal)
            } else {
                view.showOtherClubsButton.setTitle("Show My Clubs", for: .normal)
            }
            
            return view
        }
        fatalError("Unexpected kind")
    }
    
    //Did not download data allows you to switch between show clubs and all clubs quickly (without having to call the database over and over)
    var didNotDownloadData = true
    @objc func showOtherClubsButtonTapped(sender: UIButton){
        print("wow u show other clubs")
        //Invert viewing personal clubs
        clubListView.isHidden = true
        
        showActivityIndicatory(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
        
        if viewingPersonalClubs {
            viewingPersonalClubs = !viewingPersonalClubs
            if didNotDownloadData {
                didNotDownloadData = false
                getClubs()
            } else {
                clubListView.isHidden = false
                self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                clubListView.reloadData()
            }
        } else {
            viewingPersonalClubs = !viewingPersonalClubs
            clubListView.isHidden = false
            self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
            clubListView.reloadData()
        }
    }
    
    //*******************ADD A CLUB FOR TEACHERS******************
    var addAClub = true
    //This method will call when you press button.
    @objc func addClubButtonPressed() {
        addAClub = true
        print("wow u want to add club")
        performSegue(withIdentifier: "addClub", sender: addAClubButton)
    }
    
    //*************************************PASSSING DATA ONTO THE CLUB CONTROLLER*******************************
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if addAClub {
            //do stuff to prepare the add a club controller if needed
        } else {
            let vc = segue.destination as! clubGoodController
            if viewingPersonalClubs {
                vc.clubData = self.personaClubsData[self.selectedClub]
                vc.partOfClub = true
                vc.banImage = personalClubBanners[selectedClub]
                vc.clubID = personalClubIDs[selectedClub]
            } else {
                vc.clubData = self.clubsYouAreNotAPartOf[self.selectedClub]
                vc.partOfClub = false
                vc.banImage = banners[selectedClub]
                vc.clubID = clubIDs[selectedClub]
            }
        }
    }
    
    //*****************************************REFRESHING DATA**************************************
    func addRefreshControl(){
        refreshControl = UIRefreshControl()
        refreshControl?.tintColor = UIColor.red
        refreshControl?.addTarget(self, action: #selector(refreshList), for: .valueChanged)
        clubListView.addSubview(refreshControl!)
    }
    
    @objc func refreshList(){
        print("I refreshed stuff")
        //Remove all club data and refresh it
        
        //Check whether checking personal clubs or all possible clubs
        if viewingPersonalClubs {
            personaClubsData.removeAll()
            personalClubNames.removeAll()
            personalClubBanners = [tempImg] as! [UIImage]
            personalClubIDs.removeAll()
            getPersonalClubs()
        } else {
            allClubsData.removeAll()
            clubNames.removeAll()
            banners = [tempImg] as! [UIImage]
            clubIDs.removeAll()
            getClubs()
        }
    }
}

