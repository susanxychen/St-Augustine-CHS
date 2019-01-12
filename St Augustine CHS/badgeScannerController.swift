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
    @IBOutlet weak var theViewWithCancel: UIView!
    @IBOutlet weak var cancelButtonItself: UIButton!
    
    @IBOutlet weak var theTestLabel: UILabel!
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    //colours
    @IBOutlet weak var statusBarView: UIView!
    @IBOutlet weak var topBarView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set Up
        // [START setup]
        let settings = FirestoreSettings()
        settings.areTimestampsInSnapshotsEnabled = true
        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
        print(badgeID!)
        
        statusBarView.backgroundColor = DefaultColours.darkerPrimary
        topBarView.backgroundColor = DefaultColours.primaryColor
        
        if allUserFirebaseData.data["status"] as! Int == 2 {
            theTestLabel.isHidden = false
        }
        
        theViewWithCancel.bringSubviewToFront(cancelButtonItself)
        view.bringSubviewToFront(cancelButtonItself)
        
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        theCameraView.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            found(code: stringValue)
        }
    }
    
    func found(code: String) {
        var email = self.decode(data: code)
        let time: Int = Int(Date().timeIntervalSince1970 / 5)
        print("c: \(code) m: \(email) t: \(time)")
        theTestLabel.text = ("c: \(code) m: \(email) t: \(time)")
        
        //Check to see if something went wrong while decoding as the tag should only have normal characters
        let characterset = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.@")
        if email.rangeOfCharacter(from: characterset.inverted) != nil {
            //there are special characters
        } else {
            captureSession.stopRunning()
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            if !email.hasSuffix("@ycdsbk12.ca") {
                email = email + "@ycdsbk12.ca"
            }

            let alert = UIAlertController(title: "Student", message: email, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Retake", style: .default, handler: { (alert) in
                self.captureSession.startRunning()
            }))
            alert.addAction(UIAlertAction(title: "Give Badge", style: .default, handler: { (alert) in
                self.db.collection("users").whereField("email", isEqualTo: email).getDocuments(completion: { (snap, err) in
                    if let error = err {
                        let alert = UIAlertController(title: "Error in retrieveing Club Data", message: "Error \(error.localizedDescription)", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (alert) in
                            self.captureSession.startRunning()
                        }))
                        self.present(alert, animated: true, completion: nil)
                    }
                    if let snap = snap {
                        if snap.documents.count == 1 {
                            let userRef = self.db.collection("users").document(snap.documents[0].documentID)
                            userRef.updateData([
                                "badges": FieldValue.arrayUnion([self.badgeID])
                            ])
                            
                            self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                                let uDoc: DocumentSnapshot
                                do {
                                    try uDoc = transaction.getDocument(userRef)
                                } catch let fetchError as NSError {
                                    errorPointer?.pointee = fetchError
                                    return nil
                                }
                                
                                guard let oldPoints = uDoc.data()?["points"] as? Int else {
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
                                transaction.updateData(["points": oldPoints + 10], forDocument: userRef)
                                return nil
                            }, completion: { (object, err) in
                                if let error = err {
                                    print("Transaction failed: \(error)")
                                } else {
                                    print("Transaction successfully committed!")
                                    print("successfuly gave badge")
                                    self.dismiss(animated: true, completion: nil)
                                }
                            })
                        } else {
                            let alert = UIAlertController(title: "Error in giving badges", message: "No user found with \(email)", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (alert) in
                                self.captureSession.startRunning()
                            }))
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                })
            }))
            self.present(alert, animated: true, completion: nil)
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
        print("I cancel")
        self.dismiss(animated: true, completion: nil)
    }
    
}
