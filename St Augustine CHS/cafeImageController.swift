//
//  cafeImageController.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-12-12.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import UIKit
import Firebase

class cafeImageController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var theCafeImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func pressedSelectImage(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.sourceType = .camera
            self.present(imagePicker, animated: true, completion: nil)
        } else {
            print("no camera access")
            //Tell the user there is no camera available
            let alert = UIAlertController(title: "Cannot access Camera", message: "Either the app does not have access to the camera or the device does not have a camera", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    //Picking the image from photo libarry.....Info dictionary contains the image data
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        theCafeImage.image = image
        print("i get run")
        //trainImage()
        picker.dismiss(animated: true, completion: nil)
    }

    //If the user cancesl picking image from library
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("i get run 2")
        picker.dismiss(animated: true, completion: nil)
    }
    
//    func trainImage(){
//        let vision = Vision.vision()
//        let textRecognizer = vision.onDeviceTextRecognizer()
//
//        let image = VisionImage(image: theCafeImage.image!)
//
//        print(theCafeImage.image)
//
//        textRecognizer.process(image) { result, error in
//            print(result?.text)
//
//            guard error == nil, let result = result else {
//                print("Error is: \(error)")
//                return
//            }
//            print("do i even get run")
////            // Recognized text
////            let resultText = result.text
////            print("Result: ")
////            print(resultText)
//
//
//
//            for block in result.blocks {
//                let blockText = block.text
//                let blockConfidence = block.confidence
//
//                for line in block.lines {
//                    let lineText = line.text
//                    let lineConfidence = line.confidence
//
//                    for element in line.elements {
//                        let elementText = element.text
//                        let elementConfidence = element.confidence
//                        print(elementText)
//                    }
//                }
//            }
//        }
//    }

}
