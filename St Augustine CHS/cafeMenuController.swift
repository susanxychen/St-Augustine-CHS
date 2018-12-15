//
//  cafeMenuController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-12-14.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit

class cafeMenuController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var menuCollectionView: UICollectionView!
    
    var foodList = ["Pizza","Fries","Pasta"]
    var foodPrices = ["3.50","2.50","1.50"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    //****************************FORMATTING THE COLLECTION VIEWS****************************
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return foodList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "food", for: indexPath) as! cafemenuCell
        cell.foodLabel.text = foodList[indexPath.item] + ": $" + foodPrices[indexPath.item]
        return cell
    }
    
}
