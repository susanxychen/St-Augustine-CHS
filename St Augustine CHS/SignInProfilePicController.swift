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
    
    //Colors
    @IBOutlet weak var statusBarView: UIView!
    @IBOutlet weak var topBarView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set Up
        // [START setup]
        let settings = FirestoreSettings()
        //settings.areTimestampsInSnapshotsEnabled = true
        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
        statusBarView.backgroundColor = Defaults.darkerPrimary
        topBarView.backgroundColor = Defaults.primaryColor
        
        showActivityIndicatory(container: container, actInd: actInd)
        
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
                let picRarities = data["rarities"] as! [Int]
                var freePics = [Int]()
                
                for x in 0..<picRarities.count {
                    if picRarities[x] == 0 {
                        freePics.append(x)
                    }
                }
                
                self.allProfileImages = [UIImage](repeating: self.fillerImage, count: freePics.count)
                print(self.allProfileImages)
                
                for imgNum in 0...self.allProfileImages.count-1 {
                    let storage = Storage.storage()
                    let storageRef = storage.reference()
                    
                    // Create a reference to the file you want to download
                    let imgRef = storageRef.child("profilePictures/\(freePics[imgNum]).png")
                    
                    imgRef.getMetadata { (metadata, error) in
                        if let error = error {
                            // Uh-oh, an error occurred!
                            print("cant find image \(freePics[imgNum])")
                            print(error)
                        } else {
                            // Metadata now contains the metadata for 'images/forest.jpg'
                            if let metadata = metadata {
                                let theMetaData = metadata.dictionaryRepresentation()
                                let updated = theMetaData["updated"]
                                
                                if let updated = updated {
                                    if let savedImage = self.getSavedImage(named: "\(freePics[imgNum])=\(updated)"){
                                        print("already saved \(freePics[imgNum])=\(updated)")
                                        self.allProfileImages[imgNum] = savedImage
                                    } else {
                                        // Create a reference to the file you want to download
                                        imgRef.downloadURL { url, error in
                                            if error != nil {
                                                //print(error)
                                                print("cant find image \(freePics[imgNum])")
                                                self.allProfileImages[imgNum] = self.fillerImage
                                            } else {
                                                // Get the download URL
                                                var image: UIImage?
                                                let data = try? Data(contentsOf: url!)
                                                if let imageData = data {
                                                    image = UIImage(data: imageData)!
                                                    self.allProfileImages[imgNum] = image!
                                                    self.clearImageFolder(imageName: "\(freePics[imgNum])=\(updated)")
                                                    self.saveImageDocumentDirectory(image: image!, imageName: "\(freePics[imgNum])=\(updated)")
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
                    self.hideActivityIndicator(container: self.container, actInd: self.actInd)
                    self.profilePicsCollectionView.reloadData()
                    
                    //Back up because images dont all load sometimes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.profilePicsCollectionView.reloadData()
                    }
                }
                
            }
        }
        
        
        //Set Image Array Data
        //allProfileImages = [UIImage(named: "cafe"), UIImage(named: "gear"), UIImage(named: "space"), UIImage(named: "snoo"), UIImage(named: "stalogo"), UIImage(named: "home")] as! [UIImage]
        
        //Format the profile pic
        theProfilePicture.layer.cornerRadius = 170/2
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
        picsCell.picture.image = allProfileImages[indexPath.item]
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
