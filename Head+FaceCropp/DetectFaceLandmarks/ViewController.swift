//
//  ViewController.swift
//  DetectFaceLandmarks
//
//  Created by mathieu on 21/06/2017.
//  Copyright © 2017 mathieu. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {

    let faceDetector = FaceLandmarksDetector()
    let captureSession = AVCaptureSession()
    @IBOutlet weak var imageView: UIImageView!
    var finalImage: UIImage?
    var usingFrontCamera = true
    var captureDevice: AVCaptureDevice!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        let vc = FaceDetectVC()
        self.navigationController?.pushViewController(vc, animated: true)
        // Do any additional setup after loading the view, typically from a nib.
       // configureDevice()
    }

    
    @IBAction func tappedOnDetectButton(_ sender: UIButton) {
        
        if let img = self.finalImage {
            self.captureSession.stopRunning()
            
            faceDetector.outputFaces(for: img) { (resultImage) in
                DispatchQueue.main.async {
                    self.imageView?.image = resultImage
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

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

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

