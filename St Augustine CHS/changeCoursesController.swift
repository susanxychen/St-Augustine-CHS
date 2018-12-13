//
//  changeCoursesController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-12-06.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit
import Firebase

class changeCoursesController: UIViewController {
    
    //The Database
    var db: Firestore!
    var docRef: DocumentReference!
    
    //The data coming in
    var coursesBefore = [String]()
    
    //UI Elements
    @IBOutlet weak var updateButton: UIButton!
    @IBOutlet weak var s1p1: UITextField!
    @IBOutlet weak var s1p2: UITextField!
    @IBOutlet weak var s1p3: UITextField!
    @IBOutlet weak var s1p4: UITextField!
    
    @IBOutlet weak var s2p1: UITextField!
    @IBOutlet weak var s2p2: UITextField!
    @IBOutlet weak var s2p3: UITextField!
    @IBOutlet weak var s2p4: UITextField!
    
    //The text fields
    var allTextFields = [UITextField]()
    var coursesToCheck = [String]()
    
    //The final data
    var coursesTypedIn = [String]()
    
    //Returning to classes
    var onDoneBlock : ((Bool) -> Void)?
    
    //Refresh Vars
    let actInd: UIActivityIndicatorView = UIActivityIndicatorView()
    let container: UIView = UIView()
    let overlayView = UIView(frame: UIScreen.main.bounds)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //***************INTERNET CONNECTION**************
        var iAmConneted = false
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if let connected = snapshot.value as? Bool, connected {
                print("Connected")
                iAmConneted = true
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0){
                    print(iAmConneted)
                    if !iAmConneted{
                        print("Not connected")
                        let alert = UIAlertController(title: "Error", message: "You are not connected to the internet", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                        self.updateButton.isEnabled = false
                    }
                }
            }
        })
        
        hideKeyboardWhenTappedAround()
        coursesToCheck = ["ASS","PEE","POO","DIK","KKK","FUK"]
        allTextFields = [s1p1,s1p2,s1p3,s1p4,s2p1,s2p2,s2p3,s2p4]
        
        //Set Up
        // [START setup]
        let settings = FirestoreSettings()
        settings.areTimestampsInSnapshotsEnabled = true
        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
        //Set up courses
        for i in 0..<8 {
            allTextFields[i].text = coursesBefore[i]
        }
    }

    @IBAction func cancelButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func updateButton(_ sender: Any) {
        print("wow i am going next")
        var validCourses = true
        print(allTextFields.count)
        
        //Checking for invalid courses
        for course in allTextFields {
            //The course
            let temp = Array(course.text!)
            //print("Course: \(temp)")
            
            //Check to see if the course subject is valid
            for check in coursesToCheck {
                if (course.text?.contains(check))! {
                    print("invalid course")
                    validCourses = false
                    break
                }
            }
            
            //Allow spare to be written and don't check the below stuff
            if course.text?.uppercased() == "SPARE" {
                break
            }
            
            //Not the proper length course code
            if course.text?.count != 7 {
                print("not proper length")
                validCourses = false
                break
            } else if !(temp[3] == "1" || temp[3] == "2" || temp[3] == "3" || temp[3] == "4"){
                //grade is not number
                print("not a grade")
                validCourses = false
                break
            } else if !(temp[4] == "D" || temp[4] == "O" || temp[4] == "U" || temp[4] == "M" || temp[4] == "C" || temp[4] == "A") {
                //not a course type
                print("not a course type")
                validCourses = false
                break
            } else if !(temp[5] == "1" || temp[5] == "E") {
                //Last part is not a 1 or an E
                print("invalid last")
                validCourses = false
                break
            }
        }
        
        if validCourses {
            showActivityIndicatory(uiView: self.view, container: container, actInd: actInd, overlayView: overlayView)
            //Set the final courses
            for i in 0..<8{
                coursesTypedIn.append(allTextFields[i].text ?? "Error Code")
            }
            print("valid \(coursesTypedIn)")
            
            let user = Auth.auth().currentUser
            db.collection("users").document((user?.uid)!).setData([
                "classes": coursesTypedIn
            ], mergeFields: ["classes"]) { (err) in
                if let err = err {
                    let alert = UIAlertController(title: "Error in updating courses", message: "Error: \(err)", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                } else {
                    self.db.collection("users").document((user?.uid)!).getDocument { (docSnapshot, err) in
                        if let docSnapshot = docSnapshot {
                            allUserFirebaseData.data = docSnapshot.data()!
                            self.onDoneBlock!(true)
                            self.dismiss(animated: true, completion: nil)
                        }
                        if let err = err {
                            let alert = UIAlertController(title: "Error in updating courses", message: "Error: \(err)", preferredStyle: .alert)
                            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                            alert.addAction(okAction)
                            self.present(alert, animated: true, completion: nil)
                            self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                        }
                    }
                }
            }
            
        } else {
            let alert = UIAlertController(title: "There is an invalid course code", message: nil, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
}
