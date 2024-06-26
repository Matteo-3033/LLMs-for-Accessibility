//
//  SelectionMarker.swift
//  Progetto
//
//  Created by Matteo Manzoni on 25/06/24.
//

import ARKit
import RealityKit

class SelectionMarker: TrackedObject {
    init(anchor: ARAnchor, anchorEntity: AnchorEntity, onScreen: Bool = true, cameraPosition: simd_float3? = nil) {
        //let sphereMesh = MeshResource.generateSphere(radius: 0.1)
        let material = SimpleMaterial(
            color: UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.8),
            roughness: MaterialScalarParameter(floatLiteral: 0),
            isMetallic: false
        )
        //let entity = ModelEntity(mesh: material, materials: [sphereMaterial])
        
        let entity = try! Entity.loadModel(named: "marker")
        entity.model?.materials = [material]
        entity.transform.scale *= 2
        if let cameraPosition {
            anchorEntity.look(at: cameraPosition, from: anchor.transform.position, relativeTo: nil)
        }
        
        anchorEntity.addChild(entity)
        
        super.init(anchor: anchor, entity: entity, anchorEntity: anchorEntity, onScreen: onScreen)
    }
}
