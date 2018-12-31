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
                        self.session.stopRunning()
                        let alert = UIAlertController(title: "Student", message: message, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Retake", style: .default, handler: { (alert) in
                            self.session.startRunning()
                        }))
                        alert.addAction(UIAlertAction(title: "Give Badge", style: .default, handler: { (alert) in
                            let userRef = self.db.collection("users").document(message)
                            userRef.updateData([
                                "badges": FieldValue.arrayUnion([self.badgeID])
                            ])
                        }))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
