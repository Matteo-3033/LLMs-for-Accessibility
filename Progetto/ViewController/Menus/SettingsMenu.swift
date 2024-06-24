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
                
                Section("Border Width") {
                    Slider(
                        value: $settings.borderWidth,
                        in: 15...35,
                        step: 1
                    ) {
                        Text("Width")
                    }
                }
                                
                Section("Preview") {
                    ZStack(alignment: .topLeading) {
                        Rectangle()
                            .fill(.clear)
                            .frame(width: 60, height: 85)
                            .border(selectionColor, width: CGFloat(settings.borderWidth))
                            .padding(.top, 70)
                            .padding(.leading, 25)
                        Rectangle()
                            .fill(.clear)
                            .frame(width: 65, height: 110)
                            .border(selectionColor, width: CGFloat(settings.borderWidth))
                            .padding(.top, 85)
                            .padding(.leading, 220)
                    }
                    .frame(width: 300, height: 240, alignment: .topLeading)
                    .background(Image("livingroom").resizable())
                }
            }
            
            Button(action: { onSettingsSaved(settings) }) {
                Text("Save")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
