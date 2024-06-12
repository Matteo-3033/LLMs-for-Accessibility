//
//  ARObjectAnchor.swift
//  Progetto
//
//  Created by Students on 12/06/24.
//

import ARKit
import RealityKit
import SwiftUI
import Foundation

class ARObjectAnchor: ARAnchor {
    private static let OBJ_KEY = "ObjKey"
    
    private static var count = 0
    
    var obj: ARObject
    
    init(obj: ARObject, transform: simd_float4x4) {
        self.obj = obj
        
        let name = "ARObjectAnchor_\(ARObjectAnchor.count)"
        ARObjectAnchor.count += 1
        
        super.init(name: name, transform: transform)
    }
    
    required init(anchor: ARAnchor) {
        if let objAnchor = anchor as? ARObjectAnchor {
            obj = objAnchor.obj
        } else { obj = ARObject(modelName: "") }
        
        super.init(anchor: anchor)
    }
    
    required init?(coder aDecoder: NSCoder) {
        let modelName = aDecoder.decodeObject(
            of: NSString.self, forKey: ARObjectAnchor.OBJ_KEY
        ) as String? ?? ""
        
        self.obj = ARObject(modelName: modelName)
        super.init(coder: aDecoder)
    }

    override func encode(with aCoder: NSCoder) {
        aCoder.encode(obj.modelName, forKey: ARObjectAnchor.OBJ_KEY)
        super.encode(with: aCoder)
    }
}
