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
    let overlayView = UIView(frame: UIApplication.shared.keyWindow!.frame)
    
    //Colors
    @IBOutlet weak var statusBarView: UIView!
    @IBOutlet weak var cancelOrUpdateView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set Up
        // [START setup]
        let settings = FirestoreSettings()
        settings.areTimestampsInSnapshotsEnabled = true
        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
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
        
        showActivityIndicatory(uiView: self.view, container: container, actInd: actInd, overlayView: self.overlayView)
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
                self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
            }
        }
        
        allTextFields = [s1p1,s1p2,s1p3,s1p4,s2p1,s2p2,s2p3,s2p4]
        
        //Colors
        statusBarView.backgroundColor = DefaultColours.darkerPrimary
        cancelOrUpdateView.backgroundColor = DefaultColours.primaryColor
        
        for x in allTextFields {
            x.tintColor = DefaultColours.accentColor
        }
        
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
        
        //Checking for invalid courses
        for course in allTextFields {
            //Clear all leading and trailing whitespaces
            let trimmedString = course.text!.trimmingCharacters(in: .whitespaces)
            course.text = trimmedString
            
            //Allow spare to be written and don't check the below stuff
            if course.text?.uppercased() == "SPARE" {
                course.text = course.text?.uppercased()
            } else {
                //Check to see if the course subject is valid
                let theCourse = String(course.text!.prefix(6))
                
                if !(coursesToCheck.contains(theCourse)) {
                    print("invalid course: " + theCourse)
                    validCourses = false
                    break
                }
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
                    let alert = UIAlertController(title: "Error in updating courses", message: "Error: \(err.localizedDescription)", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                } else {
                    self.db.collection("users").document((user?.uid)!).getDocument { (docSnapshot, err) in
                        if let docSnapshot = docSnapshot {
                            allUserFirebaseData.data = docSnapshot.data()!
                            self.onDoneBlock!(true)
                            self.hideActivityIndicator(uiView: self.view, container: self.container, actInd: self.actInd, overlayView: self.overlayView)
                            self.dismiss(animated: true, completion: nil)
                        }
                        if let err = err {
                            let alert = UIAlertController(title: "Error in updating courses", message: "Error: \(err.localizedDescription)", preferredStyle: .alert)
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
