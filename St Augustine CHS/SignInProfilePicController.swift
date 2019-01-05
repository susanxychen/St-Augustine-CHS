//
//  SignInProfilePicController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-11-17.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit
import Firebase

class SignInProfilePicController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var hiddenNextButton: UIButton!
    @IBOutlet weak var theProfilePicture: UIImageView!
    
    //Loading Vars
    let actInd: UIActivityIndicatorView = UIActivityIndicatorView()
    let container: UIView = UIView()
    let overlayView = UIView(frame: UIScreen.main.bounds)
    
    //Database Variables
    var db: Firestore!
    var docRef: DocumentReference!
    
    //User choices
    var thePicChosen = 0
    
    //The Images
    var allProfileImages = [UIImage]()
    var fillerImage = UIImage(named: "blankUser")!
    
    //Collection View Vars
    @IBOutlet weak var profilePicsCollectionView: UICollectionView!
    var counter = 0
    
    //Colors
    @IBOutlet weak var statusBarView: UIView!
    @IBOutlet weak var topBarView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overlayView.frame = UIApplication.shared.keyWindow!.frame
        //Set Up
        // [START setup]
        let settings = FirestoreSettings()
        settings.areTimestampsInSnapshotsEnabled = true
        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
        statusBarView.backgroundColor = DefaultColours.darkerPrimary
        topBarView.backgroundColor = DefaultColours.primaryColor
        
        showActivityIndicatory(uiView: self.view, container: container, actInd: actInd, overlayView: self.overlayView)
        
        var numOfPics = 0
        
        //Get the profile pictures
        db.collection("info").document("profilePics").getDocument { (snapshot, error) in
            if let error = error {
                print(error)
                let alert = UIAlertController(title: "Error in getting profile pictures", message: "Error: \(error.localizedDescription)", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            }
            if let data = snapshot?.data() {
                numOfPics = data["numOfFreePics"] as? Int ?? 0
                
                print("i get here \(numOfPics))")
                
                self.allProfileImages = [UIImage](repeating: self.fillerImage, count: numOfPics)
                print(self.allProfileImages)
                
                for i in 0...self.allProfileImages.count-1 {
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
                                        self.allProfileImages[i] = savedImage
                                    } else {
                                        // Create a reference to the file you want to download
                                        imgRef.downloadURL { url, error in
                                            if error != nil {
                                                //print(error)
                                                print("cant find image \(i) + \(self.allProfileImages[i])")
                                                self.allProfileImages[i] = self.fillerImage
                                            } else {
                                                // Get the download URL
                                                var image: UIImage?
                                                let data = try? Data(contentsOf: url!)
                                                if let imageData = data {
                                                    image = UIImage(data: imageData)!
                                                    self.allProfileImages[i] = image!
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
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    print("hey i am done getting imgs")
                    self.theProfilePicture.image = self.allProfileImages[0]
                    self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                    self.profilePicsCollectionView.reloadData()
                }
                
            }
        }
        
        
        //Set Image Array Data
        //allProfileImages = [UIImage(named: "cafe"), UIImage(named: "gear"), UIImage(named: "space"), UIImage(named: "snoo"), UIImage(named: "stalogo"), UIImage(named: "home")] as! [UIImage]
        
        //Format the profile pic
        theProfilePicture.layer.cornerRadius = 200/2
        theProfilePicture.clipsToBounds = true
    }
    
    //****************************FORMATTING THE COLLECTION VIEWS****************************
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allProfileImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let picsCell = collectionView.dequeueReusableCell(withReuseIdentifier: "profilePic", for: indexPath) as! signInProfilePicViewCell
        
        //Format the picture boarder
        picsCell.picture.layer.cornerRadius = 100/2
        picsCell.picture.clipsToBounds = true
        
        if counter < allProfileImages.count {
            picsCell.picture.image = allProfileImages[counter]
            counter += 1
        }
        return picsCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        thePicChosen = indexPath.item
        print("picture \(thePicChosen) was selected")
        theProfilePicture.image = allProfileImages[thePicChosen]
    }
    
    @IBAction func nextButtonPressed(_ sender: Any) {
        print("wow i am going next")
        self.performSegue(withIdentifier: "courseSeg", sender: self.hiddenNextButton)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! SignInCoursesController
        vc.picChosen = thePicChosen
    }
}
