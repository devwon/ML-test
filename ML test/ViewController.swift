//
//  ViewController.swift
//  ML test
//
//  Created by WonHyerin on 2019. 2. 3..
//  Copyright © 2019년 WonHyerin. All rights reserved.
//  https://www.appcoda.com/coreml-introduction/ 참고하여 개발
//

import UIKit
import CoreML

class ViewController: UIViewController, UINavigationControllerDelegate{
    
    //  @IBOutlet으로 선언한 imageView, classifier
    // 변수명 imageView, classifier이 이제 소스코드내에서 해당 이미지뷰와 라벨을 참조할 때 사용하게 된다.
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var classifier: UILabel!
    
    var model : Inceptionv3!
    
    override func viewDidLoad() {
        // 로드가 완료될 때 실행되는 코드들이 정의되는 부분
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        model = Inceptionv3()
    }

    override func didReceiveMemoryWarning() {
        // 앱이 메모리부족등의 경고가 발생시 처리해야되는 코드들이 선언되는 부분
        super.didReceiveMemoryWarning()
    }
    
    
    //create the respective actions from clicking the bar button items
    @IBAction func camera(_ sender: Any) {
        
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            return
        }
        
        let cameraPicker = UIImagePickerController()
        cameraPicker.delegate = self  //cameraPicker의 뒷바라지는 내(UIViewController)가 할게
        cameraPicker.sourceType = .camera
        cameraPicker.allowsEditing = false
        
        present(cameraPicker, animated: true)
    }
    
    @IBAction func openLibrary(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.delegate = self  //picker의 뒷바라지는 내(UIViewController)가 할게
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

}

// adopt the delegate
// UIImagePickerControllerDelegate 선언 및 사용자가 '취소'할때 동작
extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        picker.dismiss(animated: true)  // image가 선택되면 UIImagePickerController dismiss
        classifier.text = "Analyzing Image..."
        //retrieve the selected image from the info dictionary using UIImagePickerControllerOriginalImage key
        guard let image = info["UIImagePickerControllerOriginalImage"] as? UIImage else {
            return
        }
        
        // 299x299 image를 모델이 accept하면 image를 정사각형으로 바꾸고 newImage로 할당
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 299, height: 299), true, 2.0)
        image.draw(in: CGRect(x: 0, y: 0, width: 299, height: 299))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        //newImage를 CVPixelBuffer(An image buffer that holds pixels in main memory)로 바꿈
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(newImage.size.width), Int(newImage.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        // pixel to RGB color(device-dependent)
        // CGContext안에 담기
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(newImage.size.width), height: Int(newImage.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) //3
        
        // func translateBy(x: CGFloat, y: CGFloat) Changes the origin of the user coordinate system in a context.
        // func scaleBy(x: CGFloat, y: CGFloat) Changes the scale of the user coordinate system in a context.
        context?.translateBy(x: 0, y: newImage.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        // make the graphics context into the current context, render the image, remove the context from the top stack
        UIGraphicsPushContext(context!)
        newImage.draw(in: CGRect(x: 0, y: 0, width: newImage.size.width, height: newImage.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        // newImage 보여주기
        imageView.image = newImage
        
        // Core ML
        guard let prediction = try? model.prediction(image: pixelBuffer!) else {
            return
        }
        
        classifier.text = "내 생각에 이거는 \(prediction.classLabel)인 것 같아. 맞아? "
    }
    
}

