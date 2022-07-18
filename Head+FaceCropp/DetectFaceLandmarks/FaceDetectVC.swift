//
//  FaceDetectVC.swift
//  DetectFaceLandmarks
//
//  Created by Mehedi Hasan on 18/7/22.
//  Copyright © 2022 mathieu. All rights reserved.
//

import UIKit
import AVFoundation
import Vision
import Photos

class FaceDetectVC: UIViewController {
    
    let faceDetector = FaceLandmarksDetector()
    let captureSession = AVCaptureSession()
    @IBOutlet weak var imageView: UIImageView!
    var finalImage: UIImage?
    var usingFrontCamera = true
    var captureDevice: AVCaptureDevice!
    var imagePicker: UIImagePickerController?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        configureDevice()
    }
    
    
    @IBAction func tappedOnGellaryButton(_ sender: UIButton) {
        self.imagePickerPresent()
    }
    
    
    @IBAction func tappedOnDetectButton(_ sender: UIButton) {
        
        if let img = self.finalImage {
            self.captureSession.stopRunning()
            
            faceDetector.outputFaces(for: img) { (resultImage) in
                DispatchQueue.main.async {
                    self.imageView?.image = resultImage.cropAlpha()
                }
            }
        }
        
    }
    
    
    @IBAction private func changeCamera(_ cameraButton: UIButton) {
        usingFrontCamera = !usingFrontCamera
        self.captureSession.startRunning()
        
        do{
            captureSession.removeInput(captureSession.inputs.first!)
            
            if(usingFrontCamera){
                captureDevice = getFrontCamera()
                do {
                    try captureDevice.lockForConfiguration()
                    let zoomFactor:CGFloat = 1
                    captureDevice.videoZoomFactor = zoomFactor
                    captureDevice.unlockForConfiguration()
                } catch {
                    //Catch error from lockForConfiguration
                }
            }else{
                captureDevice = getBackCamera()
                
                do {
                    try captureDevice.lockForConfiguration()
                    let zoomFactor:CGFloat = 3
                    captureDevice.videoZoomFactor = zoomFactor
                    captureDevice.unlockForConfiguration()
                } catch {
                    //Catch error from lockForConfiguration
                }
            }
            let captureDeviceInput1 = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(captureDeviceInput1)
        }catch{
            print(error.localizedDescription)
        }
    }
    
    func getFrontCamera() -> AVCaptureDevice?{
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .front).devices.first
    }
    
    func getBackCamera() -> AVCaptureDevice?{
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices.first
    }
    
    private func getDevice() -> AVCaptureDevice? {
        let discoverSession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInTelephotoCamera, .builtInWideAngleCamera], mediaType: .video, position: .front)
        return discoverSession.devices.first
    }
    
    private func configureDevice() {
        if let device = getDevice() {
            self.captureDevice = device
            
            do {
                try device.lockForConfiguration()
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                }
                device.unlockForConfiguration()
            } catch { print("failed to lock config") }
            
            do {
                let input = try AVCaptureDeviceInput(device: device)
                captureSession.addInput(input)
            } catch { print("failed to create AVCaptureDeviceInput") }
            
            captureSession.startRunning()
            
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_32BGRA)]
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .utility))
            
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension FaceDetectVC: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // Scale image to process it faster
        let maxSize = CGSize(width: 1024, height: 1024)
        
        if let image = UIImage(sampleBuffer: sampleBuffer)?.flipped()?.imageWithAspectFit(size: maxSize) {
            self.finalImage = image
            DispatchQueue.main.async {
                self.imageView?.image = image
            }
            
            //            faceDetector.highlightFaces(for: image) { (resultImage) in
            //
            //            }
        }
    }
}

extension FaceDetectVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerPresent() {
        
        self.captureSession.stopRunning()
        
        self.imagePicker = UIImagePickerController()
        imagePicker?.sourceType = .photoLibrary
        imagePicker?.allowsEditing = false
        imagePicker?.delegate = self
        self.present(imagePicker!, animated: true, completion: nil)
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print("Delegate  ")
        
        guard var image = (info[UIImagePickerController.InfoKey.originalImage] as? UIImage) else { return }
        
        image = image.fixedOrientation() ?? image
        
        image = image.imageWithAspectFit(size: CGSize(width: 1200, height: 1200)) ?? image
        
        self.dismiss(animated: true, completion: { [weak self] in
            DispatchQueue.main.async {
                self?.faceDetector.outputFaces(for: image) { (resultImage) in
                    DispatchQueue.main.async {
                        self?.imageView?.image = resultImage.cropAlpha()
                    }
                }
            }
        })
    }
}

extension UIImage {
    
    /// Fix image orientaton to protrait up
    func fixedOrientation() -> UIImage? {
        guard imageOrientation != UIImage.Orientation.up else {
            // This is default orientation, don't need to do anything
            return self.copy() as? UIImage
        }
        
        guard let cgImage = self.cgImage else {
            // CGImage is not available
            return nil
        }
        
        let colorSpace:CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            return nil // Not able to create CGContext
        }
        
        var transform: CGAffineTransform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat.pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2.0)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: CGFloat.pi / -2.0)
        case .up, .upMirrored:
            break
        @unknown default:
            fatalError("Missing...")
            break
        }
        
        // Flip image one more time if needed to, this is to prevent flipped image
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .up, .down, .left, .right:
            break
        @unknown default:
            fatalError("Missing...")
            break
        }
        
        ctx.concatenate(transform)
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            break
        }
        
        guard let newCGImage = ctx.makeImage() else { return nil }
        return UIImage.init(cgImage: newCGImage, scale: 1, orientation: .up)
    }
    
    
    func cropAlpha() -> UIImage {
        
        let cgImage = self.cgImage!;
        
        let width = cgImage.width
        let height = cgImage.height
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel:Int = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let bitmapInfo: UInt32 = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo),
              let ptr = context.data?.assumingMemoryBound(to: UInt8.self) else {
            return self
        }
        
        context.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var minX = width
        var minY = height
        var maxX: Int = 0
        var maxY: Int = 0
        
        for x in 1 ..< width {
            for y in 1 ..< height {
                
                let i = bytesPerRow * Int(y) + bytesPerPixel * Int(x)
                let a = CGFloat(ptr[i + 3]) / 255.0
                
                if(a > 0.1) {
                    if (x < minX) { minX = x };
                    if (x > maxX) { maxX = x };
                    if (y < minY) { minY = y};
                    if (y > maxY) { maxY = y};
                }
            }
        }
        
        let rect = CGRect(x: CGFloat(minX),y: CGFloat(minY), width: CGFloat(maxX-minX), height: CGFloat(maxY-minY))
        let imageScale:CGFloat = self.scale
        let croppedImage =  self.cgImage!.cropping(to: rect)!
        let ret = UIImage(cgImage: croppedImage, scale: imageScale, orientation: self.imageOrientation)
        
        return ret;
    }
}

