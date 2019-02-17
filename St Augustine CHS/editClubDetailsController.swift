//
//  editClubDetailsController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-11-04.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit
import Firebase
import CropViewController

class editClubDetailsController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CropViewControllerDelegate {

    //The Database
    var db: Firestore!
    var docRef: DocumentReference!
    
    //Cloud Functions
    lazy var functions = Functions.functions()
    
    //Club Details
    var clubBannerImage: UIImage!
    var clubBadge: String!
    var clubBannerID: String!
    var clubName: String!
    var clubDesc: String!
    var clubJoinSetting: Int!
    var clubID: String!
    var pendingList = [String]()
    
    //Club IB Outlets
    @IBOutlet weak var bannerHeight: NSLayoutConstraint!
    @IBOutlet weak var updateButton: UIButton!
    @IBOutlet weak var clubBanner: UIImageView!
    @IBOutlet weak var clubNameTxtView: UITextView!
    @IBOutlet weak var clubDescTxtView: UITextView!
    @IBOutlet weak var joinClubSettingsSegmentControl: UISegmentedControl!
    
    //Returning to club vars
    var onDoneBlock : ((Bool) -> Void)?
    
    //Colours
    @IBOutlet weak var statusBarView: UIView!
    @IBOutlet weak var topBarView: UIView!
    
    let actInd: UIActivityIndicatorView = UIActivityIndicatorView()
    let container: UIView = UIView()
    
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
                        self.updateButton.isEnabled = false
                    }
                }
            }
        })
        
        //Set up the interface
        clubBanner.image = clubBannerImage
        clubNameTxtView.text = clubName
        clubDescTxtView.text = clubDesc
        joinClubSettingsSegmentControl.selectedSegmentIndex = clubJoinSetting
        
        //Make things editable
        clubNameTxtView.isEditable = true
        clubDescTxtView.isEditable = true
        
        //Disable return key when there is nothing
        clubNameTxtView.enablesReturnKeyAutomatically = true
        clubDescTxtView.enablesReturnKeyAutomatically = true
        
        print(clubID)
        
        //Hide keyboard when tapped out
        self.hideKeyboardWhenTappedAround()
        
        //Fix the banner to be 1280x720 ratio
        let imgWidth = clubBanner.frame.width
        bannerHeight.constant = imgWidth * (720/1280)
        
        //Colours
        statusBarView.backgroundColor = Defaults.darkerPrimary
        topBarView.backgroundColor = Defaults.primaryColor
        joinClubSettingsSegmentControl.tintColor = Defaults.primaryColor
        clubNameTxtView.backgroundColor = Defaults.primaryColor
        clubDescTxtView.textColor = Defaults.primaryColor
        clubDescTxtView.tintColor = Defaults.accentColor
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
//        let resized = image.scaleImage(toSize: CGSize(width: 1280, height: 720))
//        clubBanner.image = resized
        let cropVC = CropViewController(image: image)
        cropVC.delegate = self
        cropVC.rotateButtonsHidden = true
        cropVC.aspectRatioLockEnabled = true
        cropVC.resetButtonHidden = true
        cropVC.aspectRatioPickerButtonHidden = true
        cropVC.imageCropFrame = CGRect(x: 0, y: 0, width: 1280, height: 720)
        
        picker.dismiss(animated: true, completion: nil)
        present(cropVC, animated: true, completion: nil)
    }
    
    //If the user cancesl picking image from library
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        print("i get here crop")
        cropViewController.dismiss(animated: true, completion: nil)
        print(image)
        clubBanner.image = image
    }
    
    //***************************JOIN CLUB SETTINGS***************************
    @IBAction func joinClubDetailsSegment(_ sender: Any) {
        //See which option is selected
        clubJoinSetting = joinClubSettingsSegmentControl.selectedSegmentIndex
        print(clubJoinSetting)
    }
    
    //***************************CANCEL EDITING***************************
    @IBAction func cancelEditing(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //***************************UPDATE THE CLUB DETAILS***************************
    @IBAction func updateClubDetails(_ sender: Any) {
        //Check each condition such as empty fields or too long names
        
        if clubNameTxtView.text == "" || clubDescTxtView.text == "" {
            //Tell the user that information needs to be filled in
            let alert = UIAlertController(title: "Error", message: "No field can be left blank", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
        
        else if clubNameTxtView.text.contains("\n") {
            let alert = UIAlertController(title: "Error", message: "Club Name must not contain a return key", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
        
        else if (self.clubNameTxtView.text?.count)! > 50 {
            let alert = UIAlertController(title: "Error", message: "Title is too long", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
        
        else if (self.clubDescTxtView.text?.count)! > 300 && (allUserFirebaseData.data["status"] as? Int ?? 0 != 2) {
            let alert = UIAlertController(title: "Error", message: "Description is too long", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
        
        else {
            let newClubBanner = clubBanner.image
            
            //Set up an activity indicator
            showActivityIndicatory(container: container, actInd: actInd)
            
            //Start to upload image
            //Set up the image data
            let storageRef = Storage.storage().reference(withPath: "clubBanners").child(clubBannerID)
            let metaData = StorageMetadata()
            metaData.contentType = "image/jpeg"
            
            //Upload the image to the database
            if let uploadData = newClubBanner?.jpegData(compressionQuality: 1.0){
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
                    self.updateTheRestOfTheClub()
                }
            }
        }
    }
    
    func updateTheRestOfTheClub() {
        let newClubName = clubNameTxtView.text!
        let newClubDesc = clubDescTxtView.text!
        
        //Update data in the firebase
        let clubRef = db.collection("clubs").document(clubID)
        
        //PRIVATE CLUB
        if clubJoinSetting == 0 {
            let clubRef = self.db.collection("clubs").document(clubID)
            clubRef.setData([
                "pending": []
            ], merge: true) { (err) in
                if let err = err {
                    print("error in updating club \(err)")
                }
            }
        }
        
        //OPEN CLUB
        else if clubJoinSetting == 2 {
            //Update the club members array
            let clubRef = self.db.collection("clubs").document(clubID)
            clubRef.updateData(["members": FieldValue.arrayUnion(pendingList)])
            
            for user in pendingList {
                //Update the picsOwned array
                let userRef = self.db.collection("users").document(user)
                
                if self.clubBadge as String != "" {
                    userRef.updateData([
                        "badges": FieldValue.arrayUnion([self.clubBadge])
                    ])
                }
                
                userRef.updateData([
                    "clubs": FieldValue.arrayUnion([clubID]),
                    "notifications": FieldValue.arrayUnion([clubID])
                ])
                
                userRef.getDocument { (snap, err) in
                    if let snap = snap {
                        let data = snap.data()
                        let msgToken = data?["msgToken"] as? String ?? "error"
                        self.functions.httpsCallable("manageSubscriptions").call(["registrationTokens": [msgToken], "isSubscribing": true, "clubID": self.clubID]) { (result, error) in
                            if let error = error as NSError? {
                                if error.domain == FunctionsErrorDomain {
                                    let code = FunctionsErrorCode(rawValue: error.code)
                                    let message = error.localizedDescription
                                    let details = error.userInfo[FunctionsErrorDetailsKey]
                                    print(code as Any)
                                    print(message)
                                    print(details as Any)
                                }
                            }
                            print("Result is: \(String(describing: result?.data))")
                        }
                        
                        self.functions.httpsCallable("sendToUser").call(["token": msgToken, "title": "You've been accepted into \(newClubName)", "body": "Congrats!"]) { (result, error) in
                            if let error = error as NSError? {
                                if error.domain == FunctionsErrorDomain {
                                    let code = FunctionsErrorCode(rawValue: error.code)
                                    let message = error.localizedDescription
                                    let details = error.userInfo[FunctionsErrorDetailsKey]
                                    print(code as Any)
                                    print(message)
                                    print(details as Any)
                                }
                            }
                        }
                    }
                    if let err = err {
                        print(err)
                    }
                }
            }
            
            clubRef.setData([
                "pending": []
            ], merge: true) { (err) in
                if let err = err {
                    print("error in updating club \(err)")
                }
            }
        }
        
        clubRef.setData([
            "desc": newClubDesc,
            "name": newClubName,
            "joinPref": clubJoinSetting
        ], merge: true) { (err) in
            if let err = err {
                let alert = UIAlertController(title: "Error in updating Club", message: "Please Try Again later. Error: \(err.localizedDescription)", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
                print("error in updating club \(err)")
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                    self.doneWithEverything()
                }
                
            }
        }
    }
    
    func doneWithEverything() {
        onDoneBlock!(true)
        //self.hideActivityIndicator(container: self.container, actInd: self.actInd)
        dismiss(animated: true, completion: nil)
        hideActivityIndicator(container: container, actInd: actInd)
    }
}
