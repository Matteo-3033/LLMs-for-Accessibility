//
//  SelectableTrackedObject.swift
//  Progetto
//
//  Created by Matteo Manzoni on 25/06/24.
//

import ARKit
import RealityKit

class SelectableTrackedObject: TrackedObject {
    let indicatorView: IndicatorView
    var boundingBox: Entity?
    var selected = false
    
    init(anchor: ARAnchor, entity: Entity, anchorEntity: AnchorEntity, indicatorView: IndicatorView, onScreen: Bool = true) {
        self.indicatorView = indicatorView
        self.selected = false
        self.boundingBox = nil
        
        super.init(anchor: anchor, entity: entity, anchorEntity: anchorEntity, onScreen: onScreen)
    }
    
    func isTappedAt(point: CGPoint) -> Bool {
        return indicatorView.contains(point: point)
    }
}
