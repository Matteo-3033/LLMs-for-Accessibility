//
//  SettingsMenu.swift
//  Progetto
//
//  Created by Students on 11/06/24.
//

import SwiftUI

struct SettingsMenu : View {
    @State var settings: ARSettings
    var onSettingsSaved: (ARSettings) -> Void
    
    private var selectionColor: Color {
        Color("SelectionColor")
    }
    
    var body: some View {
        VStack {
            Form {
                Section {
                    Toggle("Show Planes", isOn: $settings.showPlanes)
                }
            }
            
            Button(action: { onSettingsSaved(settings) }) {
                Text("Save")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
