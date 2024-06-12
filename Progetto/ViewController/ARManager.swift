//
//  ARManager.swift
//  Progetto
//
//  Created by Students on 12/06/24.
//

import ARKit
import RealityKit

class ARManager: NSObject, ARSessionDelegate {
    private var arView: ARView
    
    private let arConfiguration: ARConfiguration
    
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
        arView.environment.sceneUnderstanding.options.insert([.collision, .occlusion, .physics, .receivesLighting])
        arView.session.run(arConfiguration, options: [.resetTracking, .removeExistingAnchors])
        
        initGestures()
    }
    
    private func initGestures() {
        let oneFingerDoubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didOneFingerDoubleTap(sender:)))
        oneFingerDoubleTapGestureRecognizer.numberOfTapsRequired = 2
        oneFingerDoubleTapGestureRecognizer.numberOfTouchesRequired = 1
        arView.addGestureRecognizer(oneFingerDoubleTapGestureRecognizer)
    }
    
    @objc
    private func didOneFingerDoubleTap(sender: UITapGestureRecognizer) {
        print("didOneFingerDoubleTap")
        
    }
    
    public func stopSession() {
        arView.gestureRecognizers?.removeAll()
        arView.session.pause()
        arView.session.delegate = nil
    }
}
