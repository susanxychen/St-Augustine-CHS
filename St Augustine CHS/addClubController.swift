//
//  addClubController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-10-28.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit

class addClubController: UIViewController {

    @IBOutlet weak var clubNameTxtFld: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Hide keyboard when tapped out
        self.hideKeyboardWhenTappedAround()
    }
    @IBAction func pressedCancel(_ sender: Any) {
        print("i pressed cancel")
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func pressedAddClub(_ sender: Any) {
        if clubNameTxtFld.text != "" {
            //Create the alert controller.
            let alert = UIAlertController(title: "Confirmation", message: "Are you sure you want to create the \(clubNameTxtFld.text!) club?", preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { (action:UIAlertAction) in
                print("You've pressed cancel");
            }
            
            let confirmAction = UIAlertAction(title: "Confirm", style: UIAlertAction.Style.default) { (action:UIAlertAction) in
                print("You've offically create the \(self.clubNameTxtFld.text!) club");
                self.dismiss(animated: true, completion: nil)
            }
            
            alert.addAction(confirmAction)
            alert.addAction(cancelAction)
            
            // 4. Present the alert.
            self.present(alert, animated: true, completion: nil)
        } else {
            //Tell the user that information needs to be filled in
            let alert = UIAlertController(title: "Error", message: "Fill in all required information", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
}
