//
//  SignInCoursesController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-11-17.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit
import Firebase

class SignInCoursesController: UIViewController {
    
    @IBOutlet weak var nextButton: UIButton!
    
    //The User Info
    var picChosen: Int!
    
    //Course Text Fields
    //Sem 1
    @IBOutlet weak var s1p1TxtField: UITextField!
    @IBOutlet weak var s1p2TxtField: UITextField!
    @IBOutlet weak var s1p3TxtField: UITextField!
    @IBOutlet weak var s1p4TxtField: UITextField!
    
    //Sem 2
    @IBOutlet weak var s2p1TxtField: UITextField!
    @IBOutlet weak var s2p2TxtField: UITextField!
    @IBOutlet weak var s2p3TxtField: UITextField!
    @IBOutlet weak var s2p4TxtField: UITextField!
    
    //The text fields
    var allTextFields = [UITextField]()
    var coursesToCheck = [String]()
    
    //The final data
    var coursesTypedIn = [String]()
    
    //Colours
    @IBOutlet weak var statusBarView: UIView!
    @IBOutlet weak var topBarView: UIView!
    
    //Database Variables
    var db: Firestore!
    var docRef: DocumentReference!
    
    //Loading Vars
    let actInd: UIActivityIndicatorView = UIActivityIndicatorView()
    let container: UIView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(picChosen as Any)
        
        //Set Up
        // [START setup]
        let settings = FirestoreSettings()
        //settings.areTimestampsInSnapshotsEnabled = true
        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
        showActivityIndicatory(container: container, actInd: actInd)
        
        db.collection("info").document("courses").getDocument { (snap, err) in
            if let error = err {
                let alert = UIAlertController(title: "Error in getting course codes", message: "Error: \(error.localizedDescription)", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            }
            
            if let snap = snap {
                let data = snap.data()!
                self.coursesToCheck = data["courses"] as! [String]
                self.hideActivityIndicator(container: self.container, actInd: self.actInd)
            }
        }
        
        statusBarView.backgroundColor = Defaults.darkerPrimary
        topBarView.backgroundColor = Defaults.primaryColor
        
        allTextFields = [s1p1TxtField,s1p2TxtField,s1p3TxtField,s1p4TxtField,s2p1TxtField,s2p2TxtField,s2p3TxtField,s2p4TxtField]
        
        for txtfld in allTextFields {
            txtfld.tintColor = Defaults.accentColor
        }
        
        hideKeyboardWhenTappedAround()
        
        print(picChosen as Any)
    }
    

    @IBAction func pressedNextButton(_ sender: Any) {
        print("wow i am going next")
        var validCourses = true
        var brokenCourse = ""
        
        //Checking for invalid courses
        for course in allTextFields {
            //Clear all leading and trailing whitespaces
            let trimmedString = course.text!.trimmingCharacters(in: .whitespaces)
            course.text = trimmedString
            
            if course.text == "" || course.text == nil {
                course.text = "SPARE"
            }
            
            //Allow spare to be written and don't check the below stuff
            if course.text?.uppercased() == "SPARE" {
                course.text = course.text?.uppercased()
            } else {
                //Check to see if the course subject is valid
                let theCourse = String(course.text!.prefix(6))
                
                if !(coursesToCheck.contains(theCourse)) {
                    print("invalid course: " + theCourse)
                    validCourses = false
                    brokenCourse = theCourse
                    break
                }
            }
        }
        
        if validCourses {
            //Set the final courses
            for i in 0..<8{
                coursesTypedIn.append(allTextFields[i].text ?? "Error Code")
            }
            print("valid \(coursesTypedIn)")
            
            self.performSegue(withIdentifier: "PrivSeg", sender: self.nextButton)
        } else {
            let alert = UIAlertController(title: "There is an invalid course code: \(brokenCourse)", message: nil, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
    }

    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! SignInPrefController
        vc.picChosen = picChosen
        vc.courses = coursesTypedIn
    }
}
