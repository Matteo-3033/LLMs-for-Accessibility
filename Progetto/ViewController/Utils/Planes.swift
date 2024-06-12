//
//  Planes.swift
//  AccessibleAR
//
//  Created by Kristian Keller on 22/04/24.
//

import ARKit
import RealityKit

func addPlaneEntity(with anchor: ARPlaneAnchor, to view: ARView) {
    let planeAnchorEntity = AnchorEntity(.plane([.any],
                                    classification: [.any],
                                    minimumBounds: [0.5, 0.5]))
    let planeModelEntity = createPlaneModelEntity(with: anchor)
    planeAnchorEntity.name = anchor.identifier.uuidString + "_anchor"
    planeModelEntity.name = anchor.identifier.uuidString + "_model"
    planeAnchorEntity.addChild(planeModelEntity)
    view.scene.addAnchor(planeAnchorEntity)
}

func createPlaneModelEntity(with anchor: ARPlaneAnchor) -> ModelEntity {
    var planeMesh: MeshResource
    var color: UIColor
    
    if anchor.alignment == .horizontal {
        color = UIColor.blue.withAlphaComponent(0.5)
        planeMesh = .generatePlane(width: anchor.planeExtent.width, depth: anchor.planeExtent.height)
    } else if anchor.alignment == .vertical {
        color = UIColor.yellow.withAlphaComponent(0.5)
        planeMesh = .generatePlane(width: anchor.planeExtent.width, height: anchor.planeExtent.height)
    } else {
        fatalError("Anchor is not ARPlaneAnchor")
    }
    
    return ModelEntity(mesh: planeMesh, materials: [SimpleMaterial(color: color, roughness: 0.25, isMetallic: false)])
}

func removePlaneEntity(with anchor: ARPlaneAnchor, from arView: ARView) {
    guard let planeAnchorEntity = arView.scene.findEntity(named: anchor.identifier.uuidString+"_anchor") else { return }
    arView.scene.removeAnchor(planeAnchorEntity as! AnchorEntity)
}

func updatePlaneEntity(with anchor: ARPlaneAnchor, in view: ARView, isEnabled: Bool) {
    var planeMesh: MeshResource
    guard let entity = view.scene.findEntity(named: anchor.identifier.uuidString+"_model") else { return }
    let modelEntity = entity as! ModelEntity
    if anchor.alignment == .horizontal {
        planeMesh = .generatePlane(width: anchor.planeExtent.width, depth: anchor.planeExtent.height)
    } else if anchor.alignment == .vertical {
        planeMesh = .generatePlane(width: anchor.planeExtent.width, height: anchor.planeExtent.height)
    } else {
        fatalError("Anchor is not ARPlaneAnchor")
    }
    modelEntity.model!.mesh = planeMesh
    modelEntity.isEnabled = isEnabled
}
