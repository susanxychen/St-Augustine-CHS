//
//  badgeScannerController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-12-31.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase

class badgeScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    //The Database
    var db: Firestore!
    var docRef: DocumentReference!
    
    var badgeID: String!
    
    @IBOutlet weak var theCameraView: UIView!
    
    var video = AVCaptureVideoPreviewLayer()
    
    //The session/video
    let session = AVCaptureSession()
    
    //https://www.youtube.com/watch?v=4Zf9dHDJ2yU
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set Up
        // [START setup]
        let settings = FirestoreSettings()
        settings.areTimestampsInSnapshotsEnabled = true
        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
        print(badgeID)
        
        //The camera
        let captureDevice = AVCaptureDevice.default(for: .video)
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            session.addInput(input)
        } catch {
            print("Error")
        }
        
        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        
        video = AVCaptureVideoPreviewLayer(session: session)
        video.frame = theCameraView.layer.bounds
        theCameraView.layer.addSublayer(video)
        
        session.startRunning()
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.count != 0 {
            if let object = metadataObjects[0] as? AVMetadataMachineReadableCodeObject {
                if object.type == AVMetadataObject.ObjectType.qr {
                    if let message = object.stringValue {
                        print("The message \(message)")
                        var email = self.decode(data: message)
                        print("The email \(email)")
                        
                        //Check to see if something went wrong while decoding as the tag should only have normal characters
                        let characterset = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.@")
                        if email.rangeOfCharacter(from: characterset.inverted) != nil {
                            print("string contains special characters")
                        } else {
                            if !email.hasSuffix("@ycdsbk12.ca") {
                                email = email + "@ycdsbk12.ca"
                            }
                            self.session.stopRunning()
                            
                            let alert = UIAlertController(title: "Student", message: email, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Retake", style: .default, handler: { (alert) in
                                self.session.startRunning()
                            }))
                            alert.addAction(UIAlertAction(title: "Give Badge", style: .default, handler: { (alert) in
                                self.db.collection("users").whereField("email", isEqualTo: email).getDocuments(completion: { (snap, err) in
                                    if let error = err {
                                        let alert = UIAlertController(title: "Error in retrieveing Club Data", message: "Error \(error.localizedDescription)", preferredStyle: .alert)
                                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (alert) in
                                            self.session.startRunning()
                                        }))
                                        self.present(alert, animated: true, completion: nil)
                                    }
                                    if let snap = snap {
                                        if snap.documents.count == 1 {
                                            let userRef = self.db.collection("users").document(snap.documents[0].documentID)
                                            userRef.updateData([
                                                "badges": FieldValue.arrayUnion([self.badgeID])
                                                ])
                                            print("successfuly gave badge")
                                            self.dismiss(animated: true, completion: nil)
                                        } else {
                                            let alert = UIAlertController(title: "Error in giving badges", message: "No user found with \(email)", preferredStyle: .alert)
                                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (alert) in
                                                self.session.startRunning()
                                            }))
                                            self.present(alert, animated: true, completion: nil)
                                        }
                                    }
                                })
                            }))
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                }
            }
        }
    }
    
    func decode(data: String) -> String {
        let time: Int = Int(Date().timeIntervalSince1970 / 5)
        let chars = Array(data)
        var bytes = [UInt8]()
        for _ in chars {
            bytes.append(0)
        }
        let charAsByteArray = chars.asByteArray()
        for i in 0..<chars.count {
            bytes[i] = UInt8(UInt8(charAsByteArray[i]) ^ UInt8(time & 0x000000FF))
        }
        return String(bytes: bytes, encoding: .utf8) ?? "Error"
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
