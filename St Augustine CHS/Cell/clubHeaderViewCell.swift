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
    @IBOutlet weak var badgesLabel: UILabel!
    
    @IBOutlet weak var badgesCollectionView: UICollectionView!
    @IBOutlet weak var badgesCollectionHeight: NSLayoutConstraint!
    
    @IBOutlet weak var createBadgeButton: UIButton!
    @IBOutlet weak var createBadgeHeight: NSLayoutConstraint!
    
    var isClubAdmin = false
    
    //Badges
    //var badgeData = [[String:Any]]()
    var badgeImgs = [UIImage]()
    
    var delegate: HeaderCellDelegate?
    
    //***********************************FORMATTING THE BADGES*************************************
    //RETURN Badge COUNT
    //Make sure when you add collection view you add data source and delegate connections on storyboard
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return badgeImgs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "badge", for: indexPath) as! clubBadgeCell
        cell.badge.image = badgeImgs[indexPath.item]
        cell.badge.layer.cornerRadius = 100/2
        cell.badge.clipsToBounds = true
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("did select \(indexPath.item)")
        self.delegate?.badgeWasPressed(index: indexPath.item)
    }
}
