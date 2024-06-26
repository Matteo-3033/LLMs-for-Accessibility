//
//  SelectionMarker.swift
//  Progetto
//
//  Created by Matteo Manzoni on 25/06/24.
//

import ARKit
import RealityKit

class SelectionMarker: TrackedObject {
    init(anchor: ARAnchor, anchorEntity: AnchorEntity, onScreen: Bool = true, cameraPosition: simd_float3? = nil, distance: Float? = nil) {
        let material = SimpleMaterial(
            color: UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.8),
            roughness: MaterialScalarParameter(floatLiteral: 0),
            isMetallic: true
        )
        
        let entity = try! Entity.loadModel(named: "marker")
        entity.model?.materials = [material]
        
        if let cameraPosition {
            anchorEntity.look(at: cameraPosition, from: anchor.transform.position, relativeTo: nil)
        }
        if let distance {
            anchorEntity.transform.scale = SIMD3<Float>(repeating: 4 * distance)
        }
        
        anchorEntity.addChild(entity)
        
        super.init(anchor: anchor, entity: entity, anchorEntity: anchorEntity, onScreen: onScreen)
    }
}
