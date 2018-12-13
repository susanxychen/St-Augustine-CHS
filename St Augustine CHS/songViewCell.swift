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
    
    @IBAction func upvoteAction(_ sender: Any) {
        upvotedButton.isEnabled = false
        //If the user has not voted on the current song, do upvote calculation
        let theSong = self.indexPath![1]
        print(theSong)
        
        //Allow App Dev votes to count for more
        var voteAmount = 1
        if allUserFirebaseData.data["status"] as? Int ?? 0 >= 2 {
            voteAmount = 5
        }
        
        
        if voteData.songsVoted[theSong][0] as! Bool == false {
            //Send the vote to cloud functions
            functions.httpsCallable("changeVote").call(["id": songID.text!, "uservote": voteAmount]) { (result, error) in
                if let error = error as NSError? {
                    if error.domain == FunctionsErrorDomain {
                        let code = FunctionsErrorCode(rawValue: error.code)
                        let message = error.localizedDescription
                        let details = error.userInfo[FunctionsErrorDetailsKey]
                        print(code as Any)
                        print(message)
                        print(details as Any)
                    }
                }
                print("vote sent to functions")
                print("Result is: \(String(describing: result?.data))")
                self.upvotedButton.isEnabled = true
            }
            
            voteArrow.image = UIImage(named: "voteArrowActive")
            print("Upvoted: \(voteData.songsVoted[theSong][1])")
            
            //Get votes and update it
            var votes = voteData.songsVoted[theSong][3] as! Int
            votes += voteAmount
            voteData.songsVoted[theSong][3] = votes
            
            voteCount.text = String(votes)
        } else {
            var votes = voteData.songsVoted[theSong][3] as! Int
            voteArrow.image = UIImage(named: "voteArrowEmpty")
            
            if votes > 0 {
                //Send the vote to cloud functions
                functions.httpsCallable("changeVote").call(["id": songID.text!, "uservote": (voteAmount * -1)]) { (result, error) in
                    if let error = error as NSError? {
                        if error.domain == FunctionsErrorDomain {
                            let code = FunctionsErrorCode(rawValue: error.code)
                            let message = error.localizedDescription
                            let details = error.userInfo[FunctionsErrorDetailsKey]
                            print(code as Any)
                            print(message)
                            print(details as Any)
                        }
                    }
                    print("vote sent to functions")
                    print("Result is: \(String(describing: result?.data))")
                    self.upvotedButton.isEnabled = true
                }
                votes -= voteAmount
                voteData.songsVoted[theSong][3] = votes
            } else {
                self.upvotedButton.isEnabled = true
            }
            voteCount.text = String(votes)
        }
        
        //Change the vote status
        voteData.songsVoted[theSong][0] = !(voteData.songsVoted[theSong][0] as! Bool)
        
        //print(voteData.songsVoted)
        
        //Save the vote data locally
        UserDefaults.standard.set(voteData.songsVoted, forKey: "songsVoted")
    }
    
    //RIGHT NOW YOUR VOTES WILL DECREASE AS YOU LEAVE SONG SCREEN BECAUSE YOU ARE DIRECTLY GETTING THE VOTES FROM THE DATABASE
}
