//
//  SignInCoursesController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-11-17.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(picChosen)
        
        coursesToCheck = ["ASS","PEE","POO","DIK","KKK","FUK"]
        
        allTextFields = [s1p1TxtField,s1p2TxtField,s1p3TxtField,s1p4TxtField,s2p1TxtField,s2p2TxtField,s2p3TxtField,s2p4TxtField]
        
        hideKeyboardWhenTappedAround()
        
        print(picChosen)
    }
    

    @IBAction func pressedNextButton(_ sender: Any) {
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
            //Set the final courses
            for i in 0..<8{
                coursesTypedIn.append(allTextFields[i].text ?? "Error Code")
            }
            print("valid \(coursesTypedIn)")
            
            self.performSegue(withIdentifier: "PrivSeg", sender: self.nextButton)
        } else {
            let alert = UIAlertController(title: "There is an invalid course code", message: nil, preferredStyle: .alert)
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
