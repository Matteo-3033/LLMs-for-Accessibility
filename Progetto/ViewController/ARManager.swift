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
    
    public var currentFrame: CVPixelBuffer? {
        arView.session.currentFrame?.capturedImage
    }
    
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
    }
    
    public func stopSession() {
        arView.session.pause()
        arView.session.delegate = nil
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
}
