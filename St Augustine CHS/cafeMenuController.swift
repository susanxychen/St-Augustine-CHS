//
//  cafeMenuController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-12-14.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit
import Firebase

class cafeMenuController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    //Database Variables
    var db: Firestore!
    var docRef: DocumentReference!
    
    @IBOutlet weak var daymenuLabel: UILabel!
    @IBOutlet weak var menuCollectionView: UICollectionView!
    
    var theActualMenu = [[Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
                        //self.updateButton.isEnabled = false
                    }
                }
            }
        })
        
        //Set Up Firebase
        // [START setup]
        let settings = FirestoreSettings()
        settings.areTimestampsInSnapshotsEnabled = true
        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
        let fullDate = String(DateFormatter.localizedString(from: NSDate() as Date, dateStyle: DateFormatter.Style.full, timeStyle: DateFormatter.Style.none)).split(separator: ",")
        
        daymenuLabel.text = "\(String(fullDate[0]).uppercased()) MENU"
        
        getCafeMenu()
    }
    
    func getCafeMenu(){
        db.collection("info").document("cafMenu").getDocument { (snap, err) in
            if let err = err {
                let alert = UIAlertController(title: "Error in updating profile picture", message: "Error: \(err.localizedDescription)", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            }
            if let snap = snap {
                for (food,cost) in snap.data()! {
                    self.theActualMenu.append([food,cost])
                }
                self.menuCollectionView.reloadData()
            }
        }
    }
    
    //****************************FORMATTING THE COLLECTION VIEWS****************************
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return theActualMenu.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "food", for: indexPath) as! cafemenuCell
        
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        let price = theActualMenu[indexPath.item][1] as! Double
        let priceNSNumber = NSNumber(value: price)
        
        cell.foodLabel.text = theActualMenu[indexPath.item][0] as? String ?? "Error"
        cell.priceLabel.text = ("$" + (formatter.string(from: priceNSNumber) ?? "Error"))
        cell.priceLabel.textColor = DefaultColours.primaryColor
        
        return cell
    }
    
}
