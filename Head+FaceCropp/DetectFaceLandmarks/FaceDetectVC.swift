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
    
    @IBOutlet weak var templateImageView: UIImageView!
    @IBOutlet weak var templateCollectoinView: UICollectionView!
    @IBOutlet weak var faceImageView: UIImageView!
    let faceDetector = FaceLandmarksDetector()
    let captureSession = AVCaptureSession()
    @IBOutlet weak var imageView: UIImageView!
    var finalImage: UIImage?
    var usingFrontCamera = true
    var captureDevice: AVCaptureDevice!
    var imagePicker: UIImagePickerController?
    @IBOutlet weak var faceImageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var faceImageViewWidthConstraint: NSLayoutConstraint!
    var templateImages = [UIImage]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        configureDevice()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.view.layoutIfNeeded()
        
    }
    
    
    @IBAction func tappedOnGellaryButton(_ sender: UIButton) {
       // self.imagePickerPresent()
    }
    
    
    @IBAction func tappedOnDetectButton(_ sender: UIButton) {
        
        if let img = self.finalImage {
            self.captureSession.stopRunning()
            
            faceDetector.outputFaces(for: img) { (resultImage) in
                DispatchQueue.main.async {
                    self.templateImageView.image = UIImage(named: "IMG_0522")
                    let output = resultImage.cropAlpha()
                    
                    let rect = AVMakeRect(aspectRatio: output.size, insideRect: self.faceImageView.bounds)
                    self.faceImageViewWidthConstraint.constant = rect.width
                    self.faceImageViewHeightConstraint.constant = rect.height
                    
                    self.faceImageView?.image = output
                    
                    if let ci = CIImage(image: output) ?? output.ciImage {
                        self.exportTemplate(faceImg: ci)
                    }
                  
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
                self.faceImageView?.image = nil
                self.templateImageView.image = nil
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
                        self?.templateImageView.image = UIImage(named: "IMG_0521")
                        self?.faceImageView?.image = resultImage.cropAlpha()
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


//MARK: CollectionView
extension FaceDetectVC {
    
    func setupCollectionView() {
        self.registerCollectionViewCell()
        self.setCollectionViewFlowLayout()
        self.setCollectionViewDelegate()
    }
    //MARK: Registration nib file and Set Delegate, Datasource
    
    fileprivate func registerCollectionViewCell(){
        let emojiNib = UINib(nibName: TemplateCollectionViewCell.id, bundle: nil)
        self.templateCollectoinView.register(emojiNib, forCellWithReuseIdentifier: TemplateCollectionViewCell.id)
    }
    
    //MARK: Set Collection View Flow Layout
    fileprivate func setCollectionViewFlowLayout(){
        if let layoutMenu = self.templateCollectoinView.collectionViewLayout as? UICollectionViewFlowLayout{
            layoutMenu.scrollDirection = .horizontal
            layoutMenu.minimumLineSpacing = 0
            layoutMenu.minimumInteritemSpacing = 0
        }
        self.templateCollectoinView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    //MARK: Set Collection View Delegate
    fileprivate func setCollectionViewDelegate(){
        self.templateCollectoinView.delegate = self
        self.templateCollectoinView.dataSource = self
    }
    
}

extension FaceDetectVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.templateImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.templateCollectoinView.dequeueReusableCell(withReuseIdentifier: TemplateCollectionViewCell.id, for: indexPath) as? TemplateCollectionViewCell
        cell?.imageView.image = self.templateImages[indexPath.item]
        return cell!
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
       
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.height
        let height =  collectionView.bounds.height
        return CGSize(width: width, height: height)
    }
    
}

extension FaceDetectVC {
    
    func exportTemplate(faceImg: CIImage) {
        let tm = UIImage(named: "IMG_0522")
        var cTemp = CIImage(image: tm!) ?? tm!.ciImage
        
        let s512 = 512.0 / cTemp!.extent.width
        
        cTemp = cTemp?.transformed(by: CGAffineTransform(scaleX: s512, y: s512))
        
        var scale = self.faceImageView.bounds.width / self.templateImageView.bounds.width
        
        let curSize = scale * cTemp!.extent.width
        
        scale = curSize / faceImg.extent.width
        
        var face = faceImg.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        var transX = self.faceImageView.frame.origin.x / self.templateImageView.bounds.width
        var transY = self.faceImageView.frame.origin.y / self.templateImageView.bounds.height
        
        print("Fraa  ", self.faceImageView.frame,"   ", (transY *  cTemp!.extent.height))
        transX = transX * cTemp!.extent.width
        transY = cTemp!.extent.height - (transY *  cTemp!.extent.height) - face.extent.height
        
        
        face = face.transformed(by: CGAffineTransform(translationX: transX, y: transY))
        
        let output = self.blendImage(topImage: face, bgImage: cTemp!)
        
        
    }
    
    func blendImage(topImage: CIImage, bgImage: CIImage) -> CIImage? {
        
        let filter = CIFilter(name: "CISourceOverCompositing")
        filter?.setValue(topImage, forKey: kCIInputImageKey)
        filter?.setValue(bgImage, forKey: kCIInputBackgroundImageKey)
        if let out = filter?.outputImage?.cropped(to: bgImage.extent) {
            return out
        }
        return topImage
    }
    
}


extension UIColor {
    func image(_ size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}

