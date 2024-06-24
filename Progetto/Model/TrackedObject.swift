//
//  TrackedObject.swift
//  AccessibleAR
//
//  Created by Kristian Keller on 08/08/23.
//

import ARKit
import RealityKit

class TrackedObject {
    let identifier: UUID
    let anchor: ARAnchor
    let entity: Entity
    let anchorEntity: AnchorEntity
    
    let indicatorView: IndicatorView
    
    var onScreen = true
    var selected = false
    
    init(anchor: ARAnchor, entity: Entity, anchorEntity: AnchorEntity, indicatorView: IndicatorView, onScreen: Bool = true, selected: Bool = false) {
        self.identifier = anchor.identifier
        self.anchor = anchor
        self.entity = entity
        self.anchorEntity = anchorEntity
        self.indicatorView = indicatorView
        self.onScreen = onScreen
        self.selected = selected
    }
    
    func equal(_ otherTrackedObject: TrackedObject?) -> Bool {
        if let otherTrackedObject = otherTrackedObject {
            return identifier == otherTrackedObject.identifier
        }
        return false
    }
    
    func isTappedAt(point: CGPoint) -> Bool {
        return indicatorView.contains(point: point)
    }
}
