//
//  failedLoginController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-10-15.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit
import GoogleSignIn
import Firebase

class failedLoginController: UIViewController {

    @IBOutlet weak var loginValidLabel: UILabel!
    @IBOutlet weak var goBackButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginValidLabel.textColor = DefaultColours.primaryColor
        goBackButton.setTitleColor(DefaultColours.accentColor, for: .normal)
    }
    
    @IBAction func goBack(_ sender: Any) {
        //Sign out of Google
        GIDSignIn.sharedInstance()?.signOut()
        //Sign out of Firebase
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    //**************DISABLE NAVIGATION CONTROLLER BAR AT ATOP OF SIGN IN SCREEN*******************
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the navigation bar on the this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Show the navigation bar on other view controllers
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
}
