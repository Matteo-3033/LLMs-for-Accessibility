//
//  ARManager.swift
//  Progetto
//
//  Created by Students on 12/06/24.
//

import ARKit
import RealityKit
import SwiftUI

struct ARSettings {
    var showPlanes: Bool = false
    var showBorders: Bool = false
    var borderWidth: Float = 10
    var borderColor: Color = Color.green
}

class ARManager: NSObject, ARSessionDelegate {
    var settings = ARSettings()
    private var arView: ARView
    private let arConfiguration: ARConfiguration
    
    private var objs: [UUID: simd_float4x4] = [:]
    
    init(arView: ARView) {
        self.arView = arView
        
        let configuration = ARWorldTrackingConfiguration()
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.worldAlignment = .gravityAndHeading
        configuration.environmentTexturing = .automatic
        
        arConfiguration = configuration
    }

    public func startSession() {
        arView.session.delegate = self
        arView.environment.sceneUnderstanding.options.insert(
            [.collision, .occlusion, .physics, .receivesLighting]
        )
       
        arView.session.run(
            arConfiguration, options: [.resetTracking, .removeExistingAnchors]
        )
    }
    
    public func addObjectToScene(obj: ARObject, transform: simd_float4x4) {
        guard let model = obj.load() else { return }
        
        print("addObjectToScene \(obj.modelName)")
        
        let arAnchor = ARObjectAnchor(obj: obj, transform: transform)
        let anchorEntity = AnchorEntity(world: arAnchor.transform)
        anchorEntity.addChild(model)
        
        arView.session.add(anchor: arAnchor)
        arView.scene.addAnchor(anchorEntity)
        objs[arAnchor.identifier] = transform
    }
    
    public func stopSession() {
        arView.session.pause()
        arView.session.delegate = nil
        objs.removeAll()
    }
    
    private func updateObjAnchor(anchor: ARObjectAnchor, camera: simd_float4x4) {
    }
    
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        frame.anchors.forEach { anchor in
            if let objAnchor = anchor as? ARObjectAnchor {
                updateObjAnchor(anchor: objAnchor, camera: frame.camera.transform)
            }
            
            if let planeAnchor = anchor as? ARPlaneAnchor {
                updatePlaneEntity(with: planeAnchor, in: arView, isEnabled: settings.showPlanes)
            }
        }
        
        
        let width = UIScreen.main.bounds.size.width
        
        let size = frame.camera.imageResolution
        // w e h invertite perché l'immagine deve essere ruotata
        let height = width * size.width / size.height
        
        if width != arView.frame.size.width || height != arView.frame.size.height {
            arView.frame.size = CGSize(width: width, height: height)
            if let superview = arView.superview {
                arView.center = superview.center
            }
        }
    }
    
    public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        anchors.forEach { anchor in
            if let planeAnchor = anchor as? ARPlaneAnchor {
                addPlaneEntity(with: planeAnchor, to: arView)
            }
        }
    }
    
    public func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        anchors.forEach { anchor in
            if let planeAnchor = anchor as? ARPlaneAnchor {
                removePlaneEntity(with: planeAnchor, from: arView)
            }
        }
    }
    
    public func currentCameraFrame(onFrame: (UIImage?) -> Void) {
        onFrame(arView.session.currentFrame?.capturedImage.toUIImage())
    }
    
    public func currentARFrame(onFrame: @escaping (UIImage?) -> Void) {
        arView.environment.background = .color(.white)
        
        currentFrame { frame in
            self.arView.environment.background = .cameraFeed()
            onFrame(frame)
        }
    }
    
    public func currentFrame(onFrame: @escaping (UIImage?) -> Void) {
        arView.snapshot(saveToHDR: false) { acquiredFrame in
            var frame: UIImage? = nil
            
            if let data = acquiredFrame?.pngData() {
                frame = UIImage(data: data)
            }
            
            onFrame(frame)
        }
    }
    
    public func getNearestAnchor(transform: simd_float4x4) -> ARAnchor? {
        let position = transform.position
        
        return arView.session.currentFrame?.anchors.min {
            position.distance(to: $0.transform.position) < position.distance(to: $1.transform.position)
        }
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
