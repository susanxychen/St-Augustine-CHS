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
    
    var theTime = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        theTime = Int(Date().timeIntervalSince1970 / 5)
        
        DispatchQueue.main.async {
            let email = Auth.auth().currentUser?.email?.split(separator: "@")
            let emailAfterSplit = String(email?[0] ?? "Error")
            print("Encoding \(emailAfterSplit)")
            let encoded = self.encode(data: emailAfterSplit)
            print("kenn en: \(encoded)")
            
            let image = self.generateQRCode(from: encoded)
            self.qrImageView.image = image
            
            //print("kenn de: \(self.decode(data: encoded))")
        }
    }
    
    //This is right
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
    
    func generateQRCode(from string: String) -> UIImage? {
        print("Generating from \(string)")
        let data = string.data(using: String.Encoding.utf8)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            } else {
                print("Cant return image")
            }
        }
        return nil
    }

}
