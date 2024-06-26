//
//  TrackedObject.swift
//  AccessibleAR
//
//  Created by Kristian Keller on 08/08/23.
//

import ARKit
import RealityKit

class TrackedObject {
    let anchor: ARAnchor
    let entity: Entity
    let anchorEntity: AnchorEntity
    
    var onScreen = true
    
    var identifier: UUID {
        anchor.identifier
    }
    
    init(anchor: ARAnchor, entity: Entity, anchorEntity: AnchorEntity, onScreen: Bool = true) {
        self.anchor = anchor
        self.entity = entity
        self.anchorEntity = anchorEntity
        self.onScreen = onScreen
    }
    
    func equal(_ otherTrackedObject: TrackedObject?) -> Bool {
        if let otherTrackedObject = otherTrackedObject {
            return identifier == otherTrackedObject.identifier
        }
        return false
    }
}
