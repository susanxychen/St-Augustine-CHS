//
//  createBadgeController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2019-01-02.
//  Copyright © 2019 St Augustine CHS. All rights reserved.
//

import UIKit
import Firebase
import CropViewController

class createBadgeController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CropViewControllerDelegate {

    var clubID: String!
    
    //The Database
    var db: Firestore!
    var docRef: DocumentReference!
    
    @IBOutlet weak var badgeImageView: UIImageView!
    @IBOutlet weak var descriptionTxtFld: UITextField!
    
    let overlayView = UIView(frame: UIScreen.main.bounds)
    
    var onDoneBlock : ((Bool) -> Void)?
    
    //Colours
    @IBOutlet weak var statusBarView: UIView!
    @IBOutlet weak var topBarView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set Up
        // [START setup]
        let settings = FirestoreSettings()
        settings.areTimestampsInSnapshotsEnabled = true
        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
        print(clubID)
        
        hideKeyboardWhenTappedAround()
        
        descriptionTxtFld.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        
        //Round the image
        badgeImageView.layer.cornerRadius = badgeImageView.frame.width / 2
        badgeImageView.clipsToBounds = true
        
        statusBarView.backgroundColor = DefaultColours.darkerPrimary
        topBarView.backgroundColor = DefaultColours.primaryColor
        descriptionTxtFld.tintColor = DefaultColours.accentColor
    }
    
    @IBAction func chooseImagePressed(_ sender: Any) {
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
//        let theResizedImage = image.scaleImage(toSize: CGSize(width: 150, height: 150))
//        badgeImageView.image = theResizedImage
//        print(theResizedImage)
        let cropVC = CropViewController(croppingStyle: .circular, image: image)
        cropVC.delegate = self
//        cropVC.rotateButtonsHidden = true
//        cropVC.aspectRatioLockEnabled = true
//        cropVC.resetButtonHidden = true
//        cropVC.aspectRatioPickerButtonHidden = true
        
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
        badgeImageView.image = image
    }
    
    @IBAction func cancelButtonPushed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func createPressed(_ sender: Any) {
        var valid = true
        
        if badgeImageView.image == UIImage(named: "blankUser") {
            valid = false
            print("Choose an image")
            let ac = UIAlertController(title: "Error", message: "Badges Require Images", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
        
        if descriptionTxtFld.text == "" {
            valid = false
            print("no text")
            let ac = UIAlertController(title: "Error", message: "Badges Require a Description", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
        
        if valid {
            //Set up an activity indicator
            self.overlayView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
            let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
            activityIndicator.center = self.overlayView.center
            self.overlayView.addSubview(activityIndicator)
            activityIndicator.startAnimating()
            view.addSubview(self.overlayView)
            
            var imageName = ""
            
            //Give the photo a random name
            imageName = self.randomString(length: 20)
            
            //Set up the image data
            let storageRef = Storage.storage().reference(withPath: "badges").child(imageName)
            let metaData = StorageMetadata()
            metaData.contentType = "image/jpeg"
            
            //Upload the image to the database
            if let uploadData = badgeImageView.image?.jpegData(compressionQuality: 1.0){
                storageRef.putData(uploadData, metadata: metaData) { (metadata, error) in
                    if let error = error {
                        let alert = UIAlertController(title: "Error in uploading image to database", message: "Please Try Again later. Error: \(error.localizedDescription)", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                        print(error as Any)
                        self.view.willRemoveSubview(self.overlayView)
                        
                        return
                    }
                    print(metadata as Any)
                    self.uploadRestAfterImageIsDone(imageName: imageName)
                }
            }
        }
    }
    
    func uploadRestAfterImageIsDone(imageName: String){
        let desc = descriptionTxtFld.text!
        
        let badgeID = randomString(length: 20)
        let user = Auth.auth().currentUser
        print("Added badge id \(badgeID)")
        db.collection("badges").document(badgeID).setData([
            "club": clubID,
            "desc": desc,
            "creator": user?.uid as Any,
            "img": imageName,
            "type": -1
        ]) { err in
            if let err = err {
                let alert = UIAlertController(title: "Error in adding badge", message: "Please Try Again later. Error: \(err.localizedDescription)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                self.view.willRemoveSubview(self.overlayView)
            } else {
                print("Document successfully written!")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                    self.onDoneBlock!(true)
                    self.dismiss(animated: true, completion: nil)
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