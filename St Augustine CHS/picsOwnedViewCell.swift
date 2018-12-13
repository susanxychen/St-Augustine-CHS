//
//  picsOwnedViewCell.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-12-02.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit

class picsOwnedViewCell: UICollectionViewCell {
    @IBOutlet weak var pic: UIImageView!
    override func prepareForReuse() {
        pic.image = nil
        super.prepareForReuse()
    }
}
