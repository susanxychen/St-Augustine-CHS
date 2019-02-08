//
//  signInController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-10-15.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class signInController: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate {
    
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var failedButton: UIButton!
    @IBOutlet weak var signInFlowButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set delegates
        GIDSignIn.sharedInstance()?.delegate = self
        GIDSignIn.sharedInstance()?.uiDelegate = self
        GIDSignIn.sharedInstance()?.signIn()
    }
    
    //****************SIGN OUT BUTTON*******************
    @IBAction func tappedSignOut(_ sender: Any) {
        //Sign out of Google
        GIDSignIn.sharedInstance()?.signOut()
        //Sign out of Firebase
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
            let alert = UIAlertController(title: "Error in retrieveing Clubs", message: "Please Try Again later. Error: \(signOutError)", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func sign(inWillDispatch signIn: GIDSignIn!, error: Error!) {
        guard error == nil else {
            print("Error while trying to redirect : \(String(describing: error))")
            let alert = UIAlertController(title: "Error in retrieveing Clubs", message: "Please Try Again later. Error: \(error.localizedDescription)", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            return
        }
        print("Successful Redirection")
    }
    
    //MARK: GIDSignIn Delegate
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!){
        if (error == nil) {
            //Successfuly Signed In to Google
        } else {
            print("ERROR ::\(error.localizedDescription)")
            let alert = UIAlertController(title: "Error in signing in to Google", message: "Error: \(error.localizedDescription)", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        let checkEmail = user.profile.email
        
        //Note. Code is not linear
        //Async means not linear
        //Could see if u can force the auth to be sync instead of async
        
        //let studentEmail = Auth.auth().currentUser?.email
        if ((checkEmail?.hasSuffix("ycdsbk12.ca"))! || (checkEmail?.hasSuffix("ycdsb.ca"))! || (checkEmail == "sachstesterforapple@gmail.com")){
            //print("wow nice sign in")
            //************************Firebase Auth************************ 
            guard let authentication = user.authentication else {
                let alert = UIAlertController(title: "Error occured signing in to Firebase", message: "Please Try Again later", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
                return
                
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
            
            Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
                if let error = error {
                    let alert = UIAlertController(title: "Error in signing in to Firebase", message: "Please Try Again later. Error: \(error.localizedDescription)", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                
                //If Valid k12 account auto segue to main screen
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let lastSignIn = Auth.auth().currentUser?.metadata.lastSignInDate
                    let creation = Auth.auth().currentUser?.metadata.creationDate
                    
                    if lastSignIn == creation {
                        var didSignInBefore: Bool
                        
                        if let x = UserDefaults.standard.object(forKey: "didSignInBefore") as? Bool {
                            didSignInBefore = x
                        } else {
                            didSignInBefore = false
                        }
                        
                        if !didSignInBefore {
                            print("new user! take em through the sign in flow")
                            self.performSegue(withIdentifier: "signInFlow", sender: self.signInFlowButton)
                        } else {
                            self.performSegue(withIdentifier: "loggedIn", sender: self.continueButton)
                        }
                    } else {
                        self.performSegue(withIdentifier: "loggedIn", sender: self.continueButton)
                    }
                }
            }
        } else{
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                //print("i sign fial now")
                self.performSegue(withIdentifier: "failedLogin", sender: self.failedButton)
            }
        }
    }
    
    // Finished disconnecting |user| from the app successfully if |error| is |nil|.
    public func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!){
        
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
