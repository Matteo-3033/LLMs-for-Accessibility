//
//  Extensions.swift
//  AccessibleAR
//
//  Created by Kristian Keller on 08/08/23.
//

import UIKit
import RealityKit
import AVFoundation

extension UIView {
    func addConstrained(subview: UIView) {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        subview.topAnchor.constraint(equalTo: topAnchor).isActive = true
        subview.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        subview.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        subview.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
}

extension CGPoint {
    func distanceSquaredFrom(_ otherPoint: CGPoint) -> CGFloat {
        return (self.x - otherPoint.x) * (self.x - otherPoint.x) + (self.y - otherPoint.y) * (self.y - otherPoint.y)
    }
    
    func distanceFrom(_ otherPoint: CGPoint) -> CGFloat {
        sqrt(self.distanceSquaredFrom(otherPoint))
    }
}

extension CVPixelBuffer {
    public func toUIImage() -> UIImage {
        let ciImageDepth = CIImage(cvPixelBuffer: self)
        let contextDepth = CIContext.init(options: nil)
        let cgImageDepth = contextDepth.createCGImage(ciImageDepth, from: ciImageDepth.extent)!
        return UIImage(cgImage: cgImageDepth, scale: 1, orientation: UIImage.Orientation.right)
    }
}

extension UIImage {
    public func resizedTo(size newSize: CGSize) -> UIImage {
        let availableRect = AVFoundation.AVMakeRect(
            aspectRatio: self.size,
            insideRect: .init(origin: .zero, size: newSize)
        )
        let targetSize = availableRect.size

        // Set scale of renderer so that 1pt == 1px
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)

        let resized = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return resized
    }
    
    public func saveToGallery() {
        UIImageWriteToSavedPhotosAlbum(self, nil, nil, nil)
    }
    
    public func getBase64() -> String? {
        let data = jpegData(compressionQuality: 0.5)
        
        if let data {
            return "data:image/jpeg;base64,\(data.base64EncodedString())"
        }
        
        return nil
    }
}

extension simd_float4x4 {
    public var position: simd_float3 {
        return SIMD3<Float>(
            columns.3.x,
            columns.3.y,
            columns.3.z
        )
    }
}

extension simd_float3 {
    public func distance(to: simd_float3) -> Float {
        return sqrt(
            (x - to.x) * (x - to.x) +
            (y - to.y) * (y - to.y) +
            (z - to.z) * (z - to.z)
        )
    }
}
