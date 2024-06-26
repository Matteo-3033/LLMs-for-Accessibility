//
//  ARManager.swift
//  Progetto
//
//  Created by Students on 12/06/24.
//

import ARKit
import RealityKit
import SwiftUI
import Metal

struct ARSettings {
    var showPlanes: Bool = false
}

class ARManager: NSObject, ARSessionDelegate {
    var settings = ARSettings()
    private var arView: ARView
    private let arConfiguration: ARConfiguration
    
    private var objs: [UUID: TrackedObject] = [:]
    
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
        
        let indicatorView = IndicatorView()
        indicatorView.backgroundColor = .clear
        indicatorView.layer.opacity = 0
        arView.addConstrained(subview: indicatorView)
        
        arView.session.add(anchor: arAnchor)
        arView.scene.addAnchor(anchorEntity)
        
        objs[arAnchor.identifier] = SelectableTrackedObject(
            anchor: arAnchor,
            entity: model,
            anchorEntity: anchorEntity,
            indicatorView: indicatorView
        )
    }
    
    public func stopSession() {
        arView.session.pause()
        arView.session.delegate = nil
        objs.removeAll()
    }
    
    private func updateObjAnchor(anchor: ARObjectAnchor, camera: ARCamera) {
    }
    
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        frame.anchors.forEach { anchor in
            if let objAnchor = anchor as? ARObjectAnchor {
                updateObjAnchor(anchor: objAnchor, camera: frame.camera)
            }
            
            if let planeAnchor = anchor as? ARPlaneAnchor {
                updatePlaneEntity(with: planeAnchor, in: arView, isEnabled: settings.showPlanes)
            }
            
            guard let obj = objs[anchor.identifier] else { return }
            
            let projection = arView.project(anchor.transform.position)!
            obj.onScreen = arView.bounds.contains(projection)
            
            let boundingBox = obj.entity.visualBounds(relativeTo: nil)
            let boundingBoxMaxProjection = arView.project(boundingBox.max)
            let boundingBoxMinProjection = arView.project(boundingBox.min)
            let projectedDistanceBoundingBoxExtremes = boundingBoxMinProjection?.distanceFrom(boundingBoxMaxProjection!)
            let sizeOfObjectOnScreen = projectedDistanceBoundingBoxExtremes ?? 0
            
            if obj.onScreen, let obj = obj as? SelectableTrackedObject {
                if obj.onScreen {
                    let centerX = projection.x
                    let centerY = projection.y
                    obj.indicatorView.xTopLeft = centerX - (sizeOfObjectOnScreen / 2)
                    obj.indicatorView.yTopLeft = centerY - (sizeOfObjectOnScreen / 2)
                    obj.indicatorView.height = sizeOfObjectOnScreen
                    obj.indicatorView.width = sizeOfObjectOnScreen
                }
            } else if let obj = obj as? SelectionMarker {
                obj.anchorEntity.look(at: frame.camera.transform.position, from: anchor.transform.position, relativeTo: nil)
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
                let (entity, anchorEntity) = addPlaneEntity(with: planeAnchor, to: arView)
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
    
    public func getAnchorAt(point: CGPoint) -> ARAnchor? {
        return objs.values.filter {
            $0 is SelectableTrackedObject
        }.map {
            $0 as! SelectableTrackedObject
        }.first {
            $0.onScreen && !$0.selected && $0.isTappedAt(point: point)
        }?.anchor
    }
    
    public func select(anchor: ARAnchor) -> TrackedObject? {
        guard 
            let obj = objs[anchor.identifier] as? SelectableTrackedObject,
            !obj.selected
        else { return nil }
        
        let boundingBox = obj.entity.visualBounds(relativeTo: nil)
        let size = boundingBox.max - boundingBox.min
        
        let boxMesh = MeshResource.generateBox(size: size, cornerRadius: 0.05)
        let boxMaterial = SimpleMaterial(color: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3), isMetallic: false)
        let boundingBoxEntity = ModelEntity(mesh: boxMesh, materials: [boxMaterial])
        
        obj.anchorEntity.addChild(boundingBoxEntity)
        boundingBoxEntity.transform.translation.y = size.y / 2
        boundingBoxEntity.transform.rotation = obj.anchorEntity.transform.rotation
        
        obj.selected = true
        obj.boundingBox = boundingBoxEntity
        
        return obj
    }
    
    public func select(transform: simd_float4x4) -> TrackedObject? {
        let arAnchor = ARAnchor(transform: transform)
        let anchorEntity = AnchorEntity(world: arAnchor.transform)
        
        let obj = SelectionMarker(
            anchor: arAnchor,
            anchorEntity: anchorEntity,
            onScreen: true,
            cameraPosition: arView.cameraTransform.translation
        )
        objs[arAnchor.identifier] = obj
        
        arView.session.add(anchor: arAnchor)
        arView.scene.addAnchor(anchorEntity)
        
        return obj
    }
    
    public func deselect(obj: TrackedObject) {
        guard let obj = objs[obj.identifier]
        else { return }
        
        if let obj = obj as? SelectableTrackedObject {
            guard obj.selected, let box = obj.boundingBox else { return }
            
            obj.selected = false
            obj.anchorEntity.removeChild(box)
            obj.boundingBox = nil
        } else {
            arView.scene.removeAnchor(obj.anchorEntity)
            arView.session.remove(anchor: obj.anchor)
        }
    }
}
