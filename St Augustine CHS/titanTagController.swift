//
//  titanTagController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-12-19.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit
import Firebase

class titanTagController: UIViewController {

    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var theGreetingLabel: UILabel! //the lower hidden one
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Show debug output for TT for status
        if allUserFirebaseData.data["status"] as! Int == 2 {
            theGreetingLabel.isHidden = false
        }
        
        //Change brightness
        UserDefaults.standard.set(true, forKey: "didEnterTT")
        UIScreen.animateBrightness(to: 1)
        
        //Update the TT
        update()
        _ = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
    }
    
    @objc func update() {
        DispatchQueue.main.async {
            //let email = Auth.auth().currentUser?.email?.split(separator: "@")
            //let emailAfterSplit = String(email?[0] ?? "Error")
            
            let finalEmail = Auth.auth().currentUser?.email ?? "error"
            
            let encoded = self.encode(data: finalEmail)
            
            let time: Int = Int(Date().timeIntervalSince1970 / 5)
            self.theGreetingLabel.text = "m:\(finalEmail) c: \(encoded) t: \(time)"
            
            let image = self.generateQRCode(from: encoded)
            self.qrImageView.image = image

            //print("kenn de: \(self.decode(data: encoded))")
        }
    }
    
    func encode(data: String) -> String {
        let time: Int = Int(Date().timeIntervalSince1970 / 5)
        let btyeArray: [UInt8] = Array(data.utf8)
        var sb = ""
        for b in btyeArray {
            let theAppendData = b ^ UInt8(time & 0x000000FF)
            sb.append(Character(UnicodeScalar(theAppendData)))
            
        }
        return sb
    }
    
//    func decode(data: String) -> String {
//        let time: Int = Int(Date().timeIntervalSince1970 / 5)
//        let chars = Array(data)
//        var bytes = [UInt8]()
//        for _ in chars {
//            bytes.append(0)
//        }
//        let charAsByteArray = chars.asByteArray()
//        for i in 0..<chars.count {
//            bytes[i] = UInt8(UInt8(charAsByteArray[i]) ^ UInt8(time & 0x000000FF))
//        }
//        return String(bytes: bytes, encoding: .utf8) ?? "Error"
//    }
    
//    func generateQRCode(from string: String) -> UIImage? {
//        //print("Generating from \(string)")
//        let data = string.data(using: String.Encoding.utf8)
//        if let filter = CIFilter(name: "CIQRCodeGenerator") {
//            filter.setValue(data, forKey: "inputMessage")
//
//            //Set the colour of the QR Code
////            guard let colorFilter = CIFilter(name: "CIFalseColor") else { return nil }
//            filter.setValue("H", forKey: "inputCorrectionLevel")
//
////            colorFilter.setValue(filter.outputImage, forKey: "inputImage")
////            colorFilter.setValue(CIColor(red: 1, green: 1, blue: 1), forKey: "inputColor1") // Background white
////            colorFilter.setValue(CIColor(red: 216/255.0, green: 175/255.0, blue: 28/255.0), forKey: "inputColor0") // Foreground or the barcode colour
//            
//            //Change its size
//            let scaleX = qrImageView.frame.size.width / qrCodeImage.extent.size.width
//            let scaleY = qrImageView.frame.size.height / qrCodeImage.extent.size.height
//            let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
//
//            if let output = colorFilter.outputImage?.transformed(by: transform) {
//                // Change the color using CIFilter
//                let colorParameters = [
//                    "inputColor0": CIColor(color: UIColor.red), // Foreground
//                    "inputColor1": CIColor(color: UIColor.black) // Background
//                ]
//                let colored = output.applyingFilter("CIFalseColor", parameters: colorParameters)
//
//                return UIImage(ciImage: colored)
//            } else {
//                print("Cannot process")
//            }
//
//        }
//        return nil
//    }
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: .utf8)
        
        // Generate the code image with CIFilter
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        
        // Scale it up (because it is generated as a tiny image)
        let scale = qrImageView.frame.size.width / (filter.outputImage?.extent.size.width ?? 1.0)
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        guard let output = filter.outputImage?.transformed(by: transform) else { return nil }
        
        // Change the color using CIFilter
        let colorParameters = [
            "inputColor0": CIColor(color: Defaults.accentColor), // Foreground
            "inputColor1": CIColor(color: UIColor.clear) // Background
        ]
        let colored = output.applyingFilter("CIFalseColor", parameters: colorParameters)
        
        return UIImage(ciImage: colored)
    }

}
