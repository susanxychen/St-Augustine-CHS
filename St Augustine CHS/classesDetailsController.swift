//
//  socialDetailsController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-11-26.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit

class classesDetailsController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var classes = [String]()
    var yourClasses = [String]()
    var viewingYourself = true
    
    @IBOutlet weak var semester1CollectionView: UICollectionView!
    @IBOutlet weak var semester2CollectionView: UICollectionView!
    
    @IBOutlet weak var editButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("The classes: \(classes)")
        
        if viewingYourself {
            //create a new button
            let button = UIButton(type: .custom)
            button.setImage(UIImage(named: "3Dots"), for: .normal)
            
            //add function for button
            button.addTarget(self, action: #selector(editCoursesPressed), for: .touchUpInside)
            button.frame = CGRect(x: 0, y: 0, width: 48, height: 48)
            
            //assign button to navigationbar
            let barButton = UIBarButtonItem(customView: button)
            self.navigationItem.rightBarButtonItem = barButton
        }
    }
    
    @objc func editCoursesPressed(){
        print("nice going to edit")
        self.performSegue(withIdentifier: "edit", sender: editButton)
    }
    
    //****************************FORMATTING THE COLLECTION VIEWS****************************
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //**********************FORMAT THE BADGES**********************
        if collectionView == semester1CollectionView {
            let sem1Cell = collectionView.dequeueReusableCell(withReuseIdentifier: "sem1", for: indexPath) as! semester1ViewCell
            sem1Cell.theClass.text = classes[indexPath.item]
            
            //If same class, highlight
            if (!viewingYourself && classes[indexPath.item] == yourClasses[indexPath.item]) {
                sem1Cell.theClass.textColor = UIColor(red: 249/255.0, green: 225/255.0, blue: 44/255.0, alpha: 1.0)
            }
            
            return sem1Cell
        } else {
            let sem2Cell = collectionView.dequeueReusableCell(withReuseIdentifier: "sem2", for: indexPath) as! semester2ViewCell
            sem2Cell.theClass.text = classes[indexPath.item + 4]
            
            if (!viewingYourself && classes[indexPath.item + 4] == yourClasses[indexPath.item + 4]) {
                sem2Cell.theClass.textColor = UIColor(red: 249/255.0, green: 225/255.0, blue: 44/255.0, alpha: 1.0)
            }
            
            return sem2Cell
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! changeCoursesController
        vc.coursesBefore = allUserFirebaseData.data["classes"] as! [String]
        vc.onDoneBlock = { result in
            self.classes = allUserFirebaseData.data["classes"] as! [String]
            self.semester1CollectionView.reloadData()
            self.semester2CollectionView.reloadData()
        }
    }
}
