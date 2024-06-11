//
//  AddObjectMenu.swift
//  Progetto
//
//  Created by Students on 11/06/24.
//

import SwiftUI

struct SelectObjectMenu : View {
    var onObjectSelectedCallback: (ARObject) -> Void
    
    var body: some View {
        VStack {
            List(ARObject.getObjects()) { obj in
                Button(action: { onObjectSelectedCallback(obj)}) {
                    Text(obj.modelName)
                }
            }.navigationTitle("Objects")
        }
    }
}
