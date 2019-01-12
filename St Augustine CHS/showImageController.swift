//
//  showImageController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2019-01-12.
//  Copyright © 2019 St Augustine CHS. All rights reserved.
//

import UIKit

class showImageController: UIViewController {

    @IBOutlet weak var backPanelView: UIView!
    @IBOutlet weak var theImage: UIImageView!
    @IBOutlet weak var theLabel: UILabel!
    
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    
    var inputtedImage: UIImage!
    var inputtedText: String!
    var showLeftButton = false
    
    var onDoneBlock : ((Bool) -> Void)?
    
    /** List
     * 0 = Profile Pic buy
     * 1 = Profile pic not enough money
     * 2 = Social page badge
     * 3 = Club page badge
     */
    
    var customizingButtonActions: Int!
    
    var rightButtonText: String!
    var leftButtonText: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.isOpaque = false
        backPanelView.layer.shadowOpacity = 1
        backPanelView.layer.shadowRadius = 3
        theImage.layer.cornerRadius = 201/2.0
        theImage.clipsToBounds = true
        rightButton.setTitle(rightButtonText, for: .normal)
        leftButton.setTitle(leftButtonText, for: .normal)
        theImage.image = inputtedImage
        theLabel.text = inputtedText
        leftButton.isHidden = !showLeftButton
        rightButton.tintColor = DefaultColours.accentColor
        leftButton.tintColor = DefaultColours.accentColor
    }
    
    @IBAction func leftButtonPresssed(_ sender: Any) {
        switch customizingButtonActions {
        case 3:
            onDoneBlock!(true)
            self.dismiss(animated: true, completion: nil)
            break
        default:
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func rightButtonPressed(_ sender: Any) {
        switch customizingButtonActions {
        case 0:
            onDoneBlock!(true)
            self.dismiss(animated: true, completion: nil)
            break
        default:
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    
}
