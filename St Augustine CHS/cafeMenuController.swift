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
    @IBOutlet weak var daymenuLabelHeight: NSLayoutConstraint!
    @IBOutlet weak var menuCollectionView: UICollectionView!
    @IBOutlet weak var regularMenuCollectionView: UICollectionView!
    @IBOutlet weak var menuCollectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var regularMenuCollectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var cafeViewHeight: NSLayoutConstraint!
    @IBOutlet weak var lineBetweenMenuHeights: NSLayoutConstraint!
    
    //Weekend Constraints
    @IBOutlet weak var topofdayHeight: NSLayoutConstraint!
    @IBOutlet weak var topofmenuHeight: NSLayoutConstraint!
    @IBOutlet weak var topoflineHeight: NSLayoutConstraint!
    
    
    var theActualMenu = [[Any]]()
    var theActualRegularMenu = [[Any]]()
    
    var isWeekend = false
    
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
        ////settings.areTimestampsInSnapshotsEnabled = true
        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
        let fullDate = String(DateFormatter.localizedString(from: Date(), dateStyle: DateFormatter.Style.full, timeStyle: DateFormatter.Style.none)).split(separator: ",")
        
        daymenuLabel.text = "\(String(fullDate[0]).uppercased()) MENU"
        
        let theDay = DateFormatter.localizedString(from: Date(), dateStyle: DateFormatter.Style.full, timeStyle: DateFormatter.Style.none)
        //If its a weekend set up the "monday will be message"
        if (theDay.range(of:"Sunday") != nil) || (theDay.range(of:"Saturday") != nil){
            isWeekend = true
            daymenuLabel.isHidden = true
            daymenuLabelHeight.constant = 0
            menuCollectionView.isHidden = true
            menuCollectionViewHeight.constant = 0
            lineBetweenMenuHeights.constant = 0
            topofdayHeight.constant = 0
            topoflineHeight.constant = 0
            topofmenuHeight.constant = 0
        }
        
        getCafeMenu()
        getRegularMenu()
    }
    
    func getCafeMenu(){
        db.collection("info").document("cafMenu").getDocument { (snap, err) in
            if let err = err {
                let alert = UIAlertController(title: "Error in getting cafe menu", message: "Error: \(err.localizedDescription)", preferredStyle: .alert)
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
    
    func getRegularMenu(){
        db.collection("info").document("cafMenuRegular").getDocument { (snap, err) in
            if let err = err {
                let alert = UIAlertController(title: "Error in getting cafe menu", message: "Error: \(err.localizedDescription)", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            }
            if let snap = snap {
                for (food,cost) in snap.data()! {
                    self.theActualRegularMenu.append([food,cost])
                }
                self.sortRegularAlphaOrder()
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
    
    func sortRegularAlphaOrder(){
        print("Sort regular")
        if self.theActualRegularMenu.count > 1 {
            var thereWasASwap = true
            while thereWasASwap {
                thereWasASwap = false
                for i in 0...self.theActualRegularMenu.count-2 {
                    let name1: String = self.theActualRegularMenu[i][0] as! String
                    let name2: String = self.theActualRegularMenu[i+1][0] as! String
                    
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
                            let temp = self.theActualRegularMenu[i]
                            self.theActualRegularMenu[i] = self.theActualRegularMenu[i+1]
                            self.theActualRegularMenu[i+1] = temp
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
            self.regularMenuCollectionView.reloadData()
        } else {
            self.regularMenuCollectionView.reloadData()
        }
    }
    
    //****************************FORMATTING THE COLLECTION VIEWS****************************
    //For some odd reason iPhone SE requires this
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == menuCollectionView {
            return CGSize(width: (self.menuCollectionView.frame.width), height: 45)
        } else {
            return CGSize(width: (self.regularMenuCollectionView.frame.width), height: 45)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == menuCollectionView {
            return theActualMenu.count
        } else {
            print("regular")
            return theActualRegularMenu.count
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let height = self.menuCollectionView.contentSize.height + self.regularMenuCollectionView.contentSize.height + 100
        
        if !isWeekend {
            self.menuCollectionViewHeight.constant = self.menuCollectionView.contentSize.height + 10
        }
        
        self.regularMenuCollectionViewHeight.constant = self.regularMenuCollectionView.contentSize.height + 10
        
        //If the screen is too small to fit all announcements, just change the height to whatever it is
        if height > UIScreen.main.bounds.height {
            self.cafeViewHeight.constant = height
        } else {
            self.cafeViewHeight.constant = UIScreen.main.bounds.height
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "food", for: indexPath) as! cafemenuCell
        
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        if collectionView == menuCollectionView {
            let price = theActualMenu[indexPath.item][1] as? Double ?? -1
            let priceNSNumber = NSNumber(value: price)
            
            cell.foodLabel.text = theActualMenu[indexPath.item][0] as? String ?? "Error"
            cell.priceLabel.text = ("$" + (formatter.string(from: priceNSNumber) ?? "Error"))
        } else {
            let price = theActualRegularMenu[indexPath.item][1] as? Double ?? -1
            let priceNSNumber = NSNumber(value: price)
            
            cell.foodLabel.text = theActualRegularMenu[indexPath.item][0] as? String ?? "Error"
            cell.priceLabel.text = ("$" + (formatter.string(from: priceNSNumber) ?? "Error"))
        }
        
        cell.priceLabel.textColor = Defaults.primaryColor
        return cell
    }
    
}
