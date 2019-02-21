//
//  clubNewsViewCell.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-10-28.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit

class clubNewsViewCell: UICollectionViewCell {
    @IBOutlet weak var anncDate: UILabel!
    @IBOutlet weak var anncTitle: UITextView!
    @IBOutlet weak var anncText: UITextView!
    @IBOutlet weak var anncTitleHeight: NSLayoutConstraint!
    @IBOutlet weak var anncTextHeight: NSLayoutConstraint!
    @IBOutlet weak var anncImg: UIImageView!
    @IBOutlet weak var anncImgHeight: NSLayoutConstraint!
    @IBOutlet weak var studentPicture: UIImageView!
    @IBOutlet weak var studentName: UILabel!
    
    
    var hardCodedImgHeight = 0
}
