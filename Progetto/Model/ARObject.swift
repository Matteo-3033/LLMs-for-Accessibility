//
//  ARObject.swift
//  Progetto
//
//  Created by Students on 11/06/24.
//

import RealityKit
import Foundation

struct ARObject: Identifiable {
    var id: Int
    var modelName: String
    
    init(modelName: String) {
        self.modelName = modelName
        self.id = modelName.hashValue
    }
    
    static var models: [ARObject]?
    
    public func load() -> Entity? {
        return try? Entity.loadModel(named: modelName)
    }
    
    static func getObjects() -> [ARObject] {
        if models == nil {
            let filemanager = FileManager.default
            let path = Bundle.main.resourcePath
            
            if let path, let files = try? filemanager.contentsOfDirectory(atPath: path) {
                models = files
                    .filter { $0.lowercased().hasSuffix(".usdz") && $0 != "marker.usdz" }
                    .map { ARObject(
                        modelName: $0.replacingOccurrences(of: ".usdz", with: "")
                    ) }
            } else { models = [] }
        }
        
        return models!
    }
}
