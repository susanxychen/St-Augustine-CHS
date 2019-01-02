//
//  sharedData.swift
//  St Augustine CHS
//
//  Created by Kenny Miu on 2018-11-05.
//  Copyright © 2018 St Augustine CHS. All rights reserved.
//

import Foundation
import UIKit

class allExtensions: UIViewController {
    var clubAdminUpdatedData = false
}

//****************************CLASS EXTENSIONS*****************************
//********************TO ALLOW FINDING STRING INDEX************************
/*var str = "abcde"
 if let index = str.index(of: "cd") {
 let domains = str.prefix(upTo: index)
 print(domains)  // "ab\n"
 }
 
 Example
 str = "Hello, playground, playground, playground"
 print(str.index(of: "play")?.encodedOffset)      // 7
 print(str.endIndex(of: "play")?.encodedOffset)       //11
 */
extension StringProtocol where Index == String.Index {
    func index(of string: Self, options: String.CompareOptions = []) -> Index? {
        return range(of: string, options: options)?.lowerBound
    }
    func endIndex(of string: Self, options: String.CompareOptions = []) -> Index? {
        return range(of: string, options: options)?.upperBound
    }
    /*
     func indexes(of string: Self, options: String.CompareOptions = []) -> [Index] {
     var result: [Index] = []
     var start = startIndex
     while start < endIndex,
     let range = self[start..<endIndex].range(of: string, options: options) {
     result.append(range.lowerBound)
     start = range.lowerBound < range.upperBound ? range.upperBound :
     index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
     }
     return result
     }
     func ranges(of string: Self, options: String.CompareOptions = []) -> [Range<Index>] {
     var result: [Range<Index>] = []
     var start = startIndex
     while start < endIndex,
     let range = self[start..<endIndex].range(of: string, options: options) {
     result.append(range)
     start = range.lowerBound < range.upperBound ? range.upperBound :
     index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
     }
     return result
     }
     */
}

extension String {
    /*
     subscript (bounds: CountableClosedRange<Int>) -> String {
     let start = index(startIndex, offsetBy: bounds.lowerBound)
     let end = index(startIndex, offsetBy: bounds.upperBound)
     return String(self[start...end])
     }
     subscript (bounds: CountableRange<Int>) -> String {
     let start = index(startIndex, offsetBy: bounds.lowerBound)
     let end = index(startIndex, offsetBy: bounds.upperBound)
     return String(self[start..<end])
     }
     */
    func lastIndex(of string: String) -> Int? {
        guard let index = range(of: string, options: .backwards) else { return nil }
        return self.distance(from: self.startIndex, to: index.lowerBound)
    }
    func encodeUrl() -> String? {
        return self.addingPercentEncoding( withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
    }
    func decodeUrl() -> String? {
        return self.removingPercentEncoding
    }
}
extension UITextView {
    
    func centerVertically() {
        let fittingSize = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let size = sizeThatFits(fittingSize)
        let topOffset = (bounds.size.height - size.height * zoomScale) / 2
        let positiveTopOffset = max(1, topOffset)
        contentOffset.y = -positiveTopOffset
    }
    
}

extension Array where Element: Hashable {
    func difference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
    }
}

extension Array {
    mutating func remove(at indexes: [Int]) {
        for index in indexes.sorted(by: >) {
            remove(at: index)
        }
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension UIImage {
    func resized(withPercentage percentage: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: size.width * percentage, height: size.height * percentage)
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    func resized(toWidth width: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

public extension FileManager {
    
    /// Calculate the allocated size of a directory and all its contents on the volume.
    ///
    /// As there's no simple way to get this information from the file system the method
    /// has to crawl the entire hierarchy, accumulating the overall sum on the way.
    /// The resulting value is roughly equivalent with the amount of bytes
    /// that would become available on the volume if the directory would be deleted.
    ///
    /// - note: There are a couple of oddities that are not taken into account (like symbolic links, meta data of
    /// directories, hard links, ...).
    public func allocatedSizeOfDirectory(at directoryURL: URL) throws -> UInt64 {
        
        // The error handler simply stores the error and stops traversal
        var enumeratorError: Error? = nil
        func errorHandler(_: URL, error: Error) -> Bool {
            enumeratorError = error
            return false
        }
        
        // We have to enumerate all directory contents, including subdirectories.
        let enumerator = self.enumerator(at: directoryURL,
                                         includingPropertiesForKeys: Array(allocatedSizeResourceKeys),
                                         options: [],
                                         errorHandler: errorHandler)!
        
        // We'll sum up content size here:
        var accumulatedSize: UInt64 = 0
        
        // Perform the traversal.
        for item in enumerator {
            
            // Bail out on errors from the errorHandler.
            if enumeratorError != nil { break }
            
            // Add up individual file sizes.
            let contentItemURL = item as! URL
            accumulatedSize += try contentItemURL.regularFileAllocatedSize()
        }
        
        // Rethrow errors from errorHandler.
        if let error = enumeratorError { throw error }
        
        return accumulatedSize
    }
}


fileprivate let allocatedSizeResourceKeys: Set<URLResourceKey> = [
    .isRegularFileKey,
    .fileAllocatedSizeKey,
    .totalFileAllocatedSizeKey,
]


fileprivate extension URL {
    
    func regularFileAllocatedSize() throws -> UInt64 {
        let resourceValues = try self.resourceValues(forKeys: allocatedSizeResourceKeys)
        
        // We only look at regular files.
        guard resourceValues.isRegularFile ?? false else {
            return 0
        }
        
        // To get the file's size we first try the most comprehensive value in terms of what
        // the file may use on disk. This includes metadata, compression (on file system
        // level) and block size.
        // In case totalFileAllocatedSize is unavailable we use the fallback value (excluding
        // meta data and compression) This value should always be available.
        return UInt64(resourceValues.totalFileAllocatedSize ?? resourceValues.fileAllocatedSize ?? 0)
    }
}

extension UIViewController {
    //let actInd: UIActivityIndicatorView = UIActivityIndicatorView()
    //let container: UIView = UIView()
    func showActivityIndicatory(uiView: UIView, container: UIView, actInd: UIActivityIndicatorView, overlayView: UIView) {
     overlayView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
        
        container.frame = uiView.frame
        container.center = overlayView.center
        container.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.3)
        
        let loadingView: UIView = UIView()
        loadingView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        loadingView.center = uiView.center
        loadingView.backgroundColor = UIColor(red: 68/255, green: 68/255, blue: 68/255, alpha: 0.7)
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10
        
        actInd.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        actInd.style = UIActivityIndicatorView.Style.whiteLarge
        actInd.center = CGPoint(x: loadingView.frame.size.width / 2, y: loadingView.frame.size.height / 2)
        
        loadingView.addSubview(actInd)
        container.addSubview(loadingView)
        //overlayView.addSubview(container)
        //uiView.addSubview(overlayView)
        //uiView.addSubview(container)
        UIApplication.shared.keyWindow!.addSubview(container)
        //uiView.bringSubviewToFront(overlayView)
        actInd.startAnimating()
        
        /*
         //Set up an activity indicator
         self.overlayView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
         let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
         activityIndicator.center = self.overlayView.center
         self.overlayView.addSubview(activityIndicator)
         activityIndicator.startAnimating()
         self.entireView.addSubview(self.overlayView)*/
    }
    
    func hideActivityIndicator(uiView: UIView, container: UIView, actInd: UIActivityIndicatorView, overlayView: UIView) {
        actInd.stopAnimating()
        container.removeFromSuperview()
    }
    
    //********************************************MISC FUNCTIONS********************************************
    func saveImageDocumentDirectory(image: UIImage, imageName: String) {
        let imgFolderArr = imageName.split(separator: "-")
        let fileManager = FileManager.default
        let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(String(imgFolderArr[0]))
        if !fileManager.fileExists(atPath: path) {
            try! fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        let url = NSURL(string: path)
        let imagePath = url!.appendingPathComponent(imageName)
        let urlString: String = imagePath!.absoluteString
        let imageData = image.jpegData(compressionQuality: 1)
        //let imageData = UIImagePNGRepresentation(image)
        fileManager.createFile(atPath: urlString as String, contents: imageData, attributes: nil)
    }
    
    func getSavedImage(named: String) -> UIImage? {
        let imgFolderArr = named.split(separator: "-")
        if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            return UIImage(contentsOfFile: URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(String(imgFolderArr[0])).appendingPathComponent(named).path)
        }
        return nil
    }
    
    func clearImageFolder(imageName: String) {
        let imgFolderArr = imageName.split(separator: "-")
        let fileManager = FileManager.default
        let myDocuments = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let diskCacheStorageBaseUrl = myDocuments.appendingPathComponent(String(imgFolderArr[0]))
        guard let filePaths = try? fileManager.contentsOfDirectory(at: diskCacheStorageBaseUrl, includingPropertiesForKeys: nil, options: []) else { return }
        for filePath in filePaths {
            print("sucessfully removed a file: \(filePath)")
            try? fileManager.removeItem(at: filePath)
        }
    }
}

extension UIResponder {
    
    func next<T: UIResponder>(_ type: T.Type) -> T? {
        return next as? T ?? next?.next(type)
    }
}
extension UICollectionViewCell {
    var collectionView: UICollectionView? {
        return next(UICollectionView.self)
    }
    var indexPath: IndexPath? {
        return collectionView?.indexPath(for: self)
    }
}

extension UIImage {
    func imageWithSize(_ size:CGSize) -> UIImage {
        var scaledImageRect = CGRect.zero
        
        let aspectWidth:CGFloat = size.width / self.size.width
        let aspectHeight:CGFloat = size.height / self.size.height
        let aspectRatio:CGFloat = min(aspectWidth, aspectHeight)
        
        scaledImageRect.size.width = self.size.width * aspectRatio
        scaledImageRect.size.height = self.size.height * aspectRatio
        scaledImageRect.origin.x = (size.width - scaledImageRect.size.width) / 2.0
        scaledImageRect.origin.y = (size.height - scaledImageRect.size.height) / 2.0
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        self.draw(in: scaledImageRect)
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
}

extension UIAlertController {
    func addImage(image: UIImage) {
        //Formate all image sizes (shouldnt need it because its square, but this function allows all images to look good inside alert controllers
        let maxSize = CGSize(width: 245, height: 300)
        let imgSize = image.size
        
        var ratio: CGFloat!
        if imgSize.width > imgSize.height {
            ratio = maxSize.width / imgSize.width
        } else {
            ratio = maxSize.height / imgSize.height
        }
        
        let scaledSize = CGSize(width: imgSize.width * ratio, height: imgSize.height * ratio)
        
        var resizedImage = image.imageWithSize(scaledSize)
        
        //Center the image
        if (imgSize.height >= imgSize.width){
            let left = (maxSize.width - resizedImage.size.width) / 2
            resizedImage = resizedImage.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: -left, bottom: 0, right: 0))
        }
        
        let imgAction = UIAlertAction(title: "", style: .default, handler: nil)
        imgAction.isEnabled = false
        imgAction.setValue(resizedImage.withRenderingMode(.alwaysOriginal), forKey: "image")
        self.addAction(imgAction)
    }
}

extension String {
    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }
    
    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
}

extension Sequence where Iterator.Element == Character {
    
    /* extension accessible as function */
    func asByteArray() -> [UInt8] {
        return String(self).utf8.map{UInt8($0)}
    }
    
    /* or, as @LeoDabus pointed out below (thanks!),
     use a computed property for this simple case  */
    var byteArray : [UInt8] {
        return String(self).utf8.map{UInt8($0)}
    }
}

extension UIScreen {
    private static let step: CGFloat = 0.005
    
    static func animateBrightness(to value: CGFloat) {
        guard abs(UIScreen.main.brightness - value) > step else { return }
        
        let delta = UIScreen.main.brightness > value ? -step : step
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.003) {
            UIScreen.main.brightness += delta
            animateBrightness(to: value)
        }
    }
}
