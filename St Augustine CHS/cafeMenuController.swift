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
        
        let fullDate = String(DateFormatter.localizedString(from: Date(), dateStyle: DateFormatter.Style.full, timeStyle: DateFormatter.Style.none)).split(separator: ",")
        
        daymenuLabel.text = "\(String(fullDate[0]).uppercased()) MENU"
        
        let theDay = DateFormatter.localizedString(from: Date(), dateStyle: DateFormatter.Style.full, timeStyle: DateFormatter.Style.none)
        //If its a weekend set up the "monday will be message"
        if (theDay.range(of:"Sunday") != nil) || (theDay.range(of:"Saturday") != nil){
            daymenuLabel.isHidden = true
        }
        
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
                self.sortAlphaOrder()
            }
        }
    }
    
    func sortAlphaOrder(){
        if self.theActualMenu.count > 1 {
            var thereWasASwap = true
            while thereWasASwap {
                thereWasASwap = false
                for i in 0...self.theActualMenu.count-2 {
                    let name1: String = self.theActualMenu[i][0] as! String
                    let name2: String = self.theActualMenu[i+1][0] as! String
                    
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
                        
                        if character2 < character1 {
                            //print("done swap")
                            thereWasASwap = true
                            let temp = self.theActualMenu[i]
                            self.theActualMenu[i] = self.theActualMenu[i+1]
                            self.theActualMenu[i+1] = temp
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
            self.menuCollectionView.reloadData()
        } else {
            self.menuCollectionView.reloadData()
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
        
        let price = theActualMenu[indexPath.item][1] as? Double ?? -1
        let priceNSNumber = NSNumber(value: price)
        
        cell.foodLabel.text = theActualMenu[indexPath.item][0] as? String ?? "Error"
        cell.priceLabel.text = ("$" + (formatter.string(from: priceNSNumber) ?? "Error"))
        cell.priceLabel.textColor = Defaults.primaryColor
        
        return cell
    }
    
}
