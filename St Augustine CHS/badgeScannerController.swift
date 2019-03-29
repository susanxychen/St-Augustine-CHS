//
//  badgeScannerController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-12-31.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import Firebase

class badgeScannerController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    //The Database
    var db: Firestore!
    var docRef: DocumentReference!
    
    //Cloud Functions
    lazy var functions = Functions.functions()
    
    var badgeID: String!
    
    @IBOutlet weak var theCameraView: UIView!
    @IBOutlet weak var theViewWithCancel: UIView!
    @IBOutlet weak var cancelButtonItself: UIButton!
    @IBOutlet weak var theTestLabel: UILabel!
    
    let session = AVCaptureSession()
    lazy var vision = Vision.vision()
    var barcodeDetector :VisionBarcodeDetector?
    
    //colours
    @IBOutlet weak var statusBarView: UIView!
    @IBOutlet weak var topBarView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set Up
        // [START setup]
        let settings = FirestoreSettings()
        ////settings.areTimestampsInSnapshotsEnabled = true
        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
        print(badgeID!)
        
        statusBarView.backgroundColor = Defaults.darkerPrimary
        topBarView.backgroundColor = Defaults.primaryColor
        
        if allUserFirebaseData.data["status"] as! Int == 2 {
            theTestLabel.isHidden = false
        }
        
        theViewWithCancel.bringSubviewToFront(cancelButtonItself)
        view.bringSubviewToFront(cancelButtonItself)
        
        startLiveVideo()
        self.barcodeDetector = vision.barcodeDetector()
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        if (captureSession?.isRunning == false) {
//            captureSession.startRunning()
//        }
//    }
    
//    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
//        if let metadataObject = metadataObjects.first {
//            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
//            guard let stringValue = readableObject.stringValue else { return }
//            found(code: stringValue)
//        }
//    }

    private func startLiveVideo() {
        session.sessionPreset = AVCaptureSession.Preset.photo
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        let deviceInput = try! AVCaptureDeviceInput(device: captureDevice!)
        let deviceOutput = AVCaptureVideoDataOutput()
        deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        session.addInput(deviceInput)
        session.addOutput(deviceOutput)
        
        let imageLayer = AVCaptureVideoPreviewLayer(session: session)
        imageLayer.frame = CGRect(x: 0, y: 0, width: self.theCameraView.frame.size.width + 100, height: self.theCameraView.frame.size.height)
        imageLayer.videoGravity = .resizeAspectFill
        theCameraView.layer.addSublayer(imageLayer)
        
        session.startRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //print("he")
        if let barcodeDetector = self.barcodeDetector {
            let visionImage = VisionImage(buffer: sampleBuffer)
            barcodeDetector.detect(in: visionImage) { (barcodes, error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                
                for barcode in barcodes! {
                    print(barcode.rawValue!)
                    self.found(code: barcode.rawValue!)
                }
            }
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
            session.stopRunning()
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            if !email.hasSuffix("@ycdsbk12.ca") {
                email = email + "@ycdsbk12.ca"
            }

            let alert = UIAlertController(title: "Student", message: email, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Retake", style: .default, handler: { (alert) in
                self.session.startRunning()
            }))
            alert.addAction(UIAlertAction(title: "Give Badge", style: .default, handler: { (alert) in
                //Get the student's info to give points
                self.db.collection("users").whereField("email", isEqualTo: email).getDocuments(completion: { (snap, err) in
                    if let error = err {
                        let alert = UIAlertController(title: "Error in retrieveing user data", message: "Error \(error.localizedDescription)", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                    if let snap = snap {
                        if snap.documents.count == 1 {
                            let userRef = self.db.collection("users").document(snap.documents[0].documentID)
                            userRef.updateData([
                                "badges": FieldValue.arrayUnion([self.badgeID as Any])
                            ])
                            
                            let msgToken = snap.documents[0].data()["msgToken"] as? String ?? "error"
                            
                            self.functions.httpsCallable("sendToUser").call(["token": msgToken, "title": "", "body": "You Have Received A New Badge!"]) { (result, error) in
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
                            }
                            
                            //Give user points
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
                                transaction.updateData(["points": oldPoints + Defaults.attendingEvent], forDocument: userRef)
                                return nil
                            }, completion: { (object, err) in
                                if let error = err {
                                    print("Transaction failed: \(error)")
                                } else {
                                    print("Transaction successfully committed!")
                                    print("successfuly gave badge")
                                    
                                    //Give the grade points
                                    let gradYear = Int(email.suffix(14).prefix(2)) ?? 0
                                    let pointRef = self.db.collection("info").document("spiritPoints")
                                    self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                                        let pDoc: DocumentSnapshot
                                        do {
                                            try pDoc = transaction.getDocument(pointRef)
                                        } catch let fetchError as NSError {
                                            errorPointer?.pointee = fetchError
                                            return nil
                                        }
                                        guard let oldPoints = pDoc.data()?[String(gradYear)] as? Int else {
                                            let error = NSError(
                                                domain: "AppErrorDomain",
                                                code: -1,
                                                userInfo: [
                                                    NSLocalizedDescriptionKey: "Unable to retrieve points from snapshot \(pDoc)"
                                                ]
                                            )
                                            errorPointer?.pointee = error
                                            return nil
                                        }
                                        transaction.updateData([String(gradYear): oldPoints + Defaults.attendingEvent], forDocument: pointRef)
                                        return nil
                                    }, completion: { (object, err) in
                                        if let error = err {
                                            print("Transaction failed: \(error)")
                                        } else {
                                            print("Transaction successfully committed!")
                                            print("successfuly gave badge")
                                        }
                                        self.dismiss(animated: true, completion: nil)
                                    })
                                }
                            })
                        } else {
                            let alert = UIAlertController(title: "Error in giving badges", message: "No user found with \(email)", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
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
