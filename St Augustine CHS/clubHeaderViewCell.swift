//
//  CollectionViewCell.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-10-31.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit
import Firebase

class clubHeaderViewCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var banner: UIImageView!
    @IBOutlet weak var name: UITextView!
    @IBOutlet weak var desc: UITextView!
    @IBOutlet weak var nameHeight: NSLayoutConstraint!
    @IBOutlet weak var descHeight: NSLayoutConstraint!
    @IBOutlet weak var joinClubButton: UIButton!
    @IBOutlet weak var announcmentLabel: UILabel!
    
    @IBOutlet weak var badgesCollectionView: UICollectionView!
    
    //***********************************FORMATTING THE BADGES*************************************
    //RETURN Badge COUNT
    //Make sure when you add collection view you add data source and delegate connections on storyboard
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "badge", for: indexPath) as! clubBadgeCell
        cell.badge.image = UIImage(named: "cafe")
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(indexPath.item)
    }
}
