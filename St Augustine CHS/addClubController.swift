//
//  addClubController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-10-28.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit
import Firebase

class addClubController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    //The Database
    var db: Firestore!
    var docRef: DocumentReference!
    
    var clubBannerID: String!
    var clubJoinSetting: Int!
    
    //Club IB Outlets
    @IBOutlet weak var clubBanner: UIImageView!
    @IBOutlet weak var clubNameTxtView: UITextView!
    @IBOutlet weak var clubDescTxtView: UITextView!
    @IBOutlet weak var joinClubSettingsSegmentControl: UISegmentedControl!
    
    //Returning to club vars
    var onDoneBlock : ((Bool) -> Void)?
    
    //Refresh Variables
    var refreshControl: UIRefreshControl?
    let actInd: UIActivityIndicatorView = UIActivityIndicatorView()
    let container: UIView = UIView()
    let overlayView = UIView(frame: UIScreen.main.bounds)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set Up
        // [START setup]
        let settings = FirestoreSettings()
        settings.areTimestampsInSnapshotsEnabled = true
        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
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
        
        //Make things editable
        clubNameTxtView.isEditable = true
        clubDescTxtView.isEditable = true
        
        //Disable return key when there is nothing
        clubNameTxtView.enablesReturnKeyAutomatically = true
        clubDescTxtView.enablesReturnKeyAutomatically = true
        
        //Hide keyboard when tapped out
        self.hideKeyboardWhenTappedAround()
    }
    
    //***************************CLUB BANNER***************************
    @IBAction func editClubBanner(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        let actionSheet = UIAlertController(title: "Photo Source", message: "Choose a source", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action:UIAlertAction) in
            //Check to see if the app has access to camera or if there is one available
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                imagePicker.sourceType = .camera
                self.present(imagePicker, animated: true, completion: nil)
            } else {
                print("no camera access")
                //Tell the user there is no camera available
                let alert = UIAlertController(title: "Cannot access Camera", message: "Either the app does not have access to the camera or the device does not have a camera", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (action:UIAlertAction) in
            //Check to see if the app has access to camera or if there is one available
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                imagePicker.sourceType = .photoLibrary
                self.present(imagePicker, animated: true, completion: nil)
            } else {
                print("no photo access")
                //Tell the user there is no camera available
                let alert = UIAlertController(title: "Cannot access Photos", message: "The app does not have access to the photo library", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
            }
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    //Picking the image from photo libarry.....Info dictionary contains the image data
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        clubBanner.image = image
        picker.dismiss(animated: true, completion: nil)
    }
    
    //If the user cancesl picking image from library
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    //***************************JOIN CLUB SETTINGS***************************
    @IBAction func joinClubDetailsSegment(_ sender: Any) {
        //See which option is selected
        clubJoinSetting = joinClubSettingsSegmentControl.selectedSegmentIndex
        print(clubJoinSetting)
    }
    
    @IBAction func pressedCancel(_ sender: Any) {
        print("i pressed cancel")
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func pressedAddClub(_ sender: Any) {
        var valid = true
        
        if clubNameTxtView.text == "" || clubDescTxtView.text == "" {
            valid = false
            //Tell the user that information needs to be filled in
            let alert = UIAlertController(title: "Error", message: "No field can be left blank", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
        
        if clubNameTxtView.text.contains("\n") {
            valid = false
            let alert = UIAlertController(title: "Error", message: "Club Name must not contain a return key", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
        
        if clubDescTxtView.text.contains("\n") {
            valid = false
            //Tell the user that information needs to be filled in
            let alert = UIAlertController(title: "Error", message: "Club Description must not contain a return key", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
        
        if clubBanner.image == UIImage(named: "space") {
            valid = false
            //Tell the user that information needs to be filled in
            let alert = UIAlertController(title: "Error", message: "Clubs must have a banner", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
        
        if (self.clubNameTxtView.text?.count)! > 50 {
            let alert = UIAlertController(title: "Error", message: "Title is too long", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            valid = false
        }
        
        if (self.clubDescTxtView.text?.count)! > 300 {
            let alert = UIAlertController(title: "Error", message: "Description is too long", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            valid = false
        }
        
        if valid {
            let newClubBanner = clubBanner.image
            
            self.showActivityIndicatory(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
            
            clubBannerID = randomString(length: 20)
            
            //Start to upload image
            //Set up the image data
            let storageRef = Storage.storage().reference(withPath: "clubBanners").child(clubBannerID)
            let metaData = StorageMetadata()
            metaData.contentType = "image/jpeg"
            
            //Upload the image to the database
            if let uploadData = newClubBanner?.resized(toWidth: 600)!.jpegData(compressionQuality: 1.0){
                storageRef.putData(uploadData, metadata: metaData) { (metadata, error) in
                    if let error = error {
                        let alert = UIAlertController(title: "Error in uploading image to database", message: "Please Try Again later. Error: \(error.localizedDescription)", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                        print(error as Any)
                        return
                    }
                    print(metadata as Any)
                    self.uploadTheRestOfTheClub()
                }
            }
        }
    }
    
    func uploadTheRestOfTheClub(){
        //Send the data to firebase
        // Add a new document in collection "announcements"
        let clubID = randomString(length: 20)
        let user = Auth.auth().currentUser
        print("Added club id \(clubID)")
        
        let userRef = self.db.collection("users").document(user!.uid)
        userRef.updateData([
            "clubs": FieldValue.arrayUnion([clubID])
        ])
        
        db.collection("clubs").document(clubID).setData([
            "admins": [user?.uid],
            "desc": clubDescTxtView.text,
            "img": clubBannerID,
            "joinPref": clubJoinSetting,
            "members": [],
            "name": clubNameTxtView.text,
            "pending": []
        ]) { err in
            if let err = err {
                let alert = UIAlertController(title: "Error in adding announcement", message: "Please Try Again later. Error: \(err.localizedDescription)", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
                
                print("Error writing document: \(err)")
            } else {
                print("Document successfully written!")
                //Return to the club controller page
                //add a delay to allow the image to upload add an indicator to show u r uploading. same for returning and refreshing or just getting anncs in general
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                    let user = Auth.auth().currentUser
                    self.db.collection("users").document((user?.uid)!).getDocument { (docSnapshot, err) in
                        if let docSnapshot = docSnapshot {
                            allUserFirebaseData.data = docSnapshot.data()!
                            self.onDoneBlock!(true)
                            self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                            self.dismiss(animated: true, completion: nil)
                        } else {
                            print("wow u dont exist")
                        }
                    }
                }
            }
        }
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
}
