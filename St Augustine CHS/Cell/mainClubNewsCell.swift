//
//  mainClubNewsCell.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-12-19.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit

class mainClubNewsCell: UICollectionViewCell {
    
    @IBOutlet weak var clubLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UITextView!
    @IBOutlet weak var contentLabel: UITextView!
    @IBOutlet weak var titleHeight: NSLayoutConstraint!
    @IBOutlet weak var contentHeight: NSLayoutConstraint!
    @IBOutlet weak var seeImageLabel: UILabel!
    @IBOutlet weak var seeImageLabelHeight: NSLayoutConstraint!
}
