//
//  songViewCell.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-10-25.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit
import Foundation
import Firebase

class songViewCell: UICollectionViewCell {
    @IBOutlet weak var songName: UILabel!
    @IBOutlet weak var artistName: UILabel!
    @IBOutlet weak var voteCount: UILabel!
    @IBOutlet weak var upvotedButton: UIButton!
    @IBOutlet weak var voteArrow: UIImageView!
    @IBOutlet weak var songID: UILabel!
    
    //Cloud Functions
    lazy var functions = Functions.functions()
    
    //The Database
    var db: Firestore!
    var docRef: DocumentReference!
    
    @IBAction func upvoteAction(_ sender: Any) {
        //Set Up
        // [START setup]
        let settings = FirestoreSettings()
        settings.areTimestampsInSnapshotsEnabled = true
        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
        print("voted")
        upvotedButton.isEnabled = false
        //If the user has not voted on the current song, do upvote calculation
        let theSong = self.indexPath![1]
        print(theSong)
        
        var voteAmount = 1
        if allUserFirebaseData.data["status"] as? Int ?? 0 >= 2 {
            voteAmount = 5
        }
        
        
        if voteData.songsVoted[theSong][0] as! Int == 0 {
            //Send the vote to cloud functions
//            functions.httpsCallable("changeVote").call(["id": songID.text!, "uservote": voteAmount]) { (result, error) in
//                if let error = error as NSError? {
//                    if error.domain == FunctionsErrorDomain {
//                        let code = FunctionsErrorCode(rawValue: error.code)
//                        let message = error.localizedDescription
//                        let details = error.userInfo[FunctionsErrorDetailsKey]
//                        print(code as Any)
//                        print(message)
//                        print(details as Any)
//                    }
//                }
//                print("vote sent to functions")
//                print("Result is: \(String(describing: result?.data))")
//                self.upvotedButton.isEnabled = true
//            }
            
            let songRef = self.db.collection("songs").document(songID.text!)
            self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                let uDoc: DocumentSnapshot
                do {
                    try uDoc = transaction.getDocument(songRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }
                
                guard let oldPoints = uDoc.data()?["upvotes"] as? Int else {
                    let error = NSError(
                        domain: "AppErrorDomain",
                        code: -1,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Unable to retrieve points from snapshot \(uDoc)"
                        ]
                    )
                    errorPointer?.pointee = error
                    return nil
                }
                transaction.updateData(["upvotes": oldPoints + voteAmount], forDocument: songRef)
                return nil
            }, completion: { (object, err) in
                if let error = err {
                    print("Transaction failed: \(error)")
                } else {
                    print("Transaction successfully committed!")
                    print("successfuly upvoted")
                    self.upvotedButton.isEnabled = true
                }
            })
            
            voteArrow.image = UIImage(named: "voteArrowActive")
            print("Upvoted: \(voteData.songsVoted[theSong][1])")
            
            //Get votes and update it
            var votes = voteData.songsVoted[theSong][3] as! Int
            votes += voteAmount
            voteData.songsVoted[theSong][3] = votes
            
            voteCount.text = String(votes)
            
            voteData.songsVoted[theSong][0] = 1
            voteCount.textColor = UIColor(red: 140/255.0, green: 201/255.0, blue: 140/255.0, alpha: 1.0)
        } else if voteData.songsVoted[theSong][0] as! Int == 1 {
            var votes = voteData.songsVoted[theSong][3] as! Int
            voteArrow.image = UIImage(named: "voteArrowEmpty")
            
            if votes > 0 {
//                //Send the vote to cloud functions
//                functions.httpsCallable("changeVote").call(["id": songID.text!, "uservote": (voteAmount * -1)]) { (result, error) in
//                    if let error = error as NSError? {
//                        if error.domain == FunctionsErrorDomain {
//                            let code = FunctionsErrorCode(rawValue: error.code)
//                            let message = error.localizedDescription
//                            let details = error.userInfo[FunctionsErrorDetailsKey]
//                            print(code as Any)
//                            print(message)
//                            print(details as Any)
//                        }
//                    }
//                    print("vote sent to functions")
//                    print("Result is: \(String(describing: result?.data))")
//                    self.upvotedButton.isEnabled = true
//                }
                
                let songRef = self.db.collection("songs").document(songID.text!)
                self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                    let uDoc: DocumentSnapshot
                    do {
                        try uDoc = transaction.getDocument(songRef)
                    } catch let fetchError as NSError {
                        errorPointer?.pointee = fetchError
                        return nil
                    }
                    
                    guard let oldPoints = uDoc.data()?["upvotes"] as? Int else {
                        let error = NSError(
                            domain: "AppErrorDomain",
                            code: -1,
                            userInfo: [
                                NSLocalizedDescriptionKey: "Unable to retrieve points from snapshot \(uDoc)"
                            ]
                        )
                        errorPointer?.pointee = error
                        return nil
                    }
                    transaction.updateData(["upvotes": oldPoints + (voteAmount * -1)], forDocument: songRef)
                    return nil
                }, completion: { (object, err) in
                    if let error = err {
                        print("Transaction failed: \(error)")
                    } else {
                        print("Transaction successfully committed!")
                        print("successfuly upvoted")
                        self.upvotedButton.isEnabled = true
                    }
                })
                
                votes -= voteAmount
                voteData.songsVoted[theSong][3] = votes
            } else {
                self.upvotedButton.isEnabled = true
            }
            voteCount.text = String(votes)
            voteData.songsVoted[theSong][0] = 0
            voteCount.textColor = UIColor.darkText
        }
        
        //Save the vote data locally
        UserDefaults.standard.set(voteData.songsVoted, forKey: "songsVoted")
    }
    
}
