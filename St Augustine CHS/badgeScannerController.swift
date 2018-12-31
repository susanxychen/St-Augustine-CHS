//
//  badgeScannerController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-12-31.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit
import AVFoundation

class badgeScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    @IBOutlet weak var theCameraView: UIView!
    
    var video = AVCaptureVideoPreviewLayer()
    
    //The session/video
    let session = AVCaptureSession()
    
    //https://www.youtube.com/watch?v=4Zf9dHDJ2yU
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
                    self.session.stopRunning()
                    let alert = UIAlertController(title: "Student", message: object.stringValue, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Retake", style: .default, handler: { (alert) in
                        self.session.startRunning()
                    }))
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
