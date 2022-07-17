//
//  FaceLandmarksDetector.swift
//  DetectFaceLandmarks
//
//  Created by mathieu on 09/07/2017.
//  Copyright © 2017 mathieu. All rights reserved.
//

import UIKit
import Vision

class FaceLandmarksDetector {

    open func outputFaces(for source: UIImage, complete: @escaping (UIImage) -> Void) {
        var resultImage = source
        let detectFaceRequest = VNDetectFaceLandmarksRequest { (request, error) in
            if error == nil {
                if let results = request.results as? [VNFaceObservation] {
                    for faceObservation in results {
                        guard let landmarks = faceObservation.landmarks else {
                            continue
                        }
                        let boundingRect = faceObservation.boundingBox

                        resultImage = self.getoutputImageImage(source: resultImage, boundingRect: boundingRect, faceLandmarks: landmarks)
                    }
                }
            } else {
                print(error!.localizedDescription)
            }
            complete(resultImage)
        }

        let vnImage = VNImageRequestHandler(cgImage: source.cgImage!, options: [:])
        try? vnImage.perform([detectFaceRequest])
    }
  
    //MARK: Get output
    private func getoutputImageImage(source: UIImage, boundingRect: CGRect, faceLandmarks: VNFaceLandmarks2D) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(source.size, false, 1)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: 0.0, y: source.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
      //  context.setBlendMode(CGBlendMode.colorBurn)
        context.setLineJoin(.round)
        context.setLineCap(.round)
        context.setShouldAntialias(true)
        context.setAllowsAntialiasing(true)

        let rectWidth = source.size.width * boundingRect.size.width
        let rectHeight = source.size.height * boundingRect.size.height

        //draw image
       // let rect = CGRect(x: 0, y:0, width: source.size.width, height: source.size.height)
   
        func getOutputFeature(_ feature: VNFaceLandmarkRegion2D, color: CGColor, close: Bool = false) -> UIImage {

            var maxX: CGFloat = 0
            var maxY: CGFloat = 0
            
            var minX: CGFloat = 100000
            var minY: CGFloat = 100000
            
            let bePath = UIBezierPath()
            
            let mappedPoints = feature.normalizedPoints.map {
    
                CGPoint(x: boundingRect.origin.x * source.size.width + $0.x * rectWidth, y: source.size.height - (boundingRect.origin.y * source.size.height + $0.y * rectHeight))
            }
 
            if mappedPoints.count > 0 {
                
                var y =  mappedPoints.first!.y
                
                bePath.move(to: CGPoint(x: mappedPoints.first!.x, y: y))
                for p in mappedPoints {
                    
                    y =  p.y
                    maxX = max(maxX, p.x)
                    maxY = max(maxY, y)
                    
                    minX = min(minX, p.x)
                    minY = min(minY, y)
                    
                    bePath.addLine(to: p)
                }
                
             //   print("MMMXX  ", maxX,"  ", minX,"   ", maxY,"   ", minY)
                bePath.addLine(to: CGPoint(x: minX, y: minY))
                
                let con1 = CGPoint(x: max(0,  minX - 100), y: minY - ((maxY - minY) * 1.2) )
                
                let con2 = CGPoint(x: min(source.size.width,  maxX + 100), y: minY - ((maxY - minY) * 1.2) )
                
                bePath.addCurve(to: CGPoint(x: maxX, y: minY), controlPoint1: con1, controlPoint2: con2)
                bePath.close()
                
            }
            
            let img = source.imageByApplyingMaskingBezierPath(bePath)
            return img
        }
        
        if let faceContour = faceLandmarks.faceContour {
            return getOutputFeature(faceContour, color: UIColor.magenta.cgColor)
        }

        let coloredImg : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return coloredImg
    }

}


extension UIImage {


    func imageByApplyingMaskingBezierPath(_ path: UIBezierPath) -> UIImage {
    
        UIGraphicsBeginImageContext(self.size)
        let context = UIGraphicsGetCurrentContext()!
 
        context.addPath(path.cgPath)
        context.clip()
        draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        
        let maskedImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        
        return maskedImage
    }

}


//MARK: Initial code

//    open func highlightFaces(for source: UIImage, complete: @escaping (UIImage) -> Void) {
//        var resultImage = source
//        let detectFaceRequest = VNDetectFaceLandmarksRequest { (request, error) in
//            if error == nil {
//                if let results = request.results as? [VNFaceObservation] {
//                    for faceObservation in results {
//                        guard let landmarks = faceObservation.landmarks else {
//                            continue
//                        }
//                        let boundingRect = faceObservation.boundingBox
//
//                        resultImage = self.drawOnImage(source: resultImage, boundingRect: boundingRect, faceLandmarks: landmarks)
//                    }
//                }
//            } else {
//                print(error!.localizedDescription)
//            }
//            complete(resultImage)
//        }
//
//        let vnImage = VNImageRequestHandler(cgImage: source.cgImage!, options: [:])
//        try? vnImage.perform([detectFaceRequest])
//    }
//
//


//
//
//    private func drawOnImage(source: UIImage, boundingRect: CGRect, faceLandmarks: VNFaceLandmarks2D) -> UIImage {
//        UIGraphicsBeginImageContextWithOptions(source.size, false, 1)
//        let context = UIGraphicsGetCurrentContext()!
//        context.translateBy(x: 0.0, y: source.size.height)
//        context.scaleBy(x: 1.0, y: -1.0)
//      //  context.setBlendMode(CGBlendMode.colorBurn)
//        context.setLineJoin(.round)
//        context.setLineCap(.round)
//        context.setShouldAntialias(true)
//        context.setAllowsAntialiasing(true)
//
//        let rectWidth = source.size.width * boundingRect.size.width
//        let rectHeight = source.size.height * boundingRect.size.height
//
//        //draw image
//        let rect = CGRect(x: 0, y:0, width: source.size.width, height: source.size.height)
//     //   context.draw(source.cgImage!, in: rect)
//
//
//        //draw bound rect
//       // context.setStrokeColor(UIColor.green.cgColor)
//       // context.addRect(CGRect(x: boundingRect.origin.x * source.size.width, y: boundingRect.origin.y * source.size.height, width: rectWidth, height: rectHeight))
//        //context.drawPath(using: CGPathDrawingMode.stroke)
//
//        //draw overlay
//     //   context.setLineWidth(1.0)
//
//
//
//        func drawFeature(_ feature: VNFaceLandmarkRegion2D, color: CGColor, close: Bool = false)  {
////            context.setStrokeColor(color)
////            context.setFillColor(color)
//            for point in feature.normalizedPoints {
////                // Draw DEBUG numbers
////                let textFontAttributes = [
////                    NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16),
////                    NSAttributedStringKey.foregroundColor: UIColor.white
////                ]
//                context.saveGState()
////                // rotate to draw numbers
//                context.translateBy(x: 0.0, y: source.size.height)
//                context.scaleBy(x: 1.0, y: -1.0)
//
//              //  let mp = CGPoint(x: boundingRect.origin.x * source.size.width + point.x * rectWidth, y: source.size.height - (boundingRect.origin.y * source.size.height + point.y * rectHeight))
//
//               // context.fillEllipse(in: CGRect(origin: CGPoint(x: mp.x-2.0, y: mp.y-2), size: CGSize(width: 4.0, height: 4.0)))
//
//                if let index = feature.normalizedPoints.index(of: point) {
//                 //  NSString(format: "%d", index).draw(at: mp, withAttributes: textFontAttributes)
//                }
//                context.restoreGState()
//            }
//
//
//            var maxX: CGFloat = 0
//            var maxY: CGFloat = 0
//
//            var minX: CGFloat = 100000
//            var minY: CGFloat = 100000
//
//            var bePath = UIBezierPath()
//
//
//            let mappedPoints = feature.normalizedPoints.map {
//
//               // CGPoint(x: boundingRect.origin.x * source.size.width + point.x * rectWidth, y: source.size.height - (boundingRect.origin.y * source.size.height + point.y * rectHeight))
//                CGPoint(x: boundingRect.origin.x * source.size.width + $0.x * rectWidth, y: source.size.height - (boundingRect.origin.y * source.size.height + $0.y * rectHeight))
//
//            }
//
//
//
//            if mappedPoints.count > 0 {
//
//                var y =  mappedPoints.first!.y
//
//                bePath.move(to: CGPoint(x: mappedPoints.first!.x, y: y))
//                for p in mappedPoints {
//
//                    y =  p.y
//                    maxX = max(maxX, p.x)
//                    maxY = max(maxY, y)
//
//                    minX = min(minX, p.x)
//                    minY = min(minY, y)
//
//                    bePath.addLine(to: p)
//                }
//
//              //  bePath.close()
//                print("MMMXX  ", maxX,"  ", minX,"   ", maxY,"   ", minY)
//               // context.addLines(between: mappedPoints)
//               // bePath.close()
//
//                bePath.addLine(to: CGPoint(x: minX, y: minY))
//
//              //  bePath.addQuadCurve(to: CGPoint(x: maxX, y: minY), controlPoint: CGPoint(x: maxX - ((maxX - minX) * 0.5), y: minY - (maxY - minY) ) )
//
//                let con1 = CGPoint(x: minX, y: minY - (maxY - minY) )
//                let con2 = CGPoint(x: maxX, y: minY - (maxY - minY) )
//
//                bePath.addCurve(to: CGPoint(x: maxX, y: minY), controlPoint1: con1, controlPoint2: con2)
//                bePath.close()
//
//                if close, let first = mappedPoints.first, let lats = mappedPoints.last {
//                   // context.addLines(between: [lats, first])
//
//                }
//
//            }
//           // let img = source.imageByApplyingMaskingBezierPath(bePath)
//
//           // return img
//
//        }
//
//
//        if let faceContour = faceLandmarks.faceContour {
//            drawFeature(faceContour, color: UIColor.magenta.cgColor)
//        }
//
////        if let leftEye = faceLandmarks.leftEye {
////            drawFeature(leftEye, color: UIColor.cyan.cgColor, close: true)
////        }
////        if let rightEye = faceLandmarks.rightEye {
////            drawFeature(rightEye, color: UIColor.cyan.cgColor, close: true)
////        }
////        if let leftPupil = faceLandmarks.leftPupil {
////            drawFeature(leftPupil, color: UIColor.cyan.cgColor, close: true)
////        }
////        if let rightPupil = faceLandmarks.rightPupil {
////            drawFeature(rightPupil, color: UIColor.cyan.cgColor, close: true)
////        }
////
////        if let nose = faceLandmarks.nose {
////            drawFeature(nose, color: UIColor.green.cgColor)
////        }
////        if let noseCrest = faceLandmarks.noseCrest {
////            drawFeature(noseCrest, color: UIColor.green.cgColor)
////        }
////
////        if let medianLine = faceLandmarks.medianLine {
////            drawFeature(medianLine, color: UIColor.gray.cgColor)
////        }
////
////        if let outerLips = faceLandmarks.outerLips {
////            drawFeature(outerLips, color: UIColor.red.cgColor, close: true)
////        }
////        if let innerLips = faceLandmarks.innerLips {
////            drawFeature(innerLips, color: UIColor.red.cgColor, close: true)
////        }
////
////        if let leftEyebrow = faceLandmarks.leftEyebrow {
////            drawFeature(leftEyebrow, color: UIColor.blue.cgColor)
////        }
////        if let rightEyebrow = faceLandmarks.rightEyebrow {
////            drawFeature(rightEyebrow, color: UIColor.blue.cgColor)
////        }
//
//        let coloredImg : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
//        UIGraphicsEndImageContext()
//        return coloredImg
//    }
//
  
