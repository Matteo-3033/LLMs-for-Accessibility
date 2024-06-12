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
    
    var body: some View {
        VStack {
            Form {
                Section {
                    Toggle("Show Planes", isOn: $settings.showPlanes)
                    Toggle("Show Borders", isOn: $settings.showBorders)
                }
                Section("Border Width") {
                    Slider(
                        value: $settings.borderWidth,
                        in: 1...20,
                        step: 1
                    ) {
                        Text("Width")
                    }
                }
                Section("Colors") {
                    ColorPicker("Selected Object", selection: $settings.selectedColor)
                    ColorPicker("Background Objects", selection: $settings.backgroundColor)
                }
                Section("Preview") {
                    ZStack(alignment: .topLeading) {
                        Rectangle()
                            .fill(.clear)
                            .frame(width: 60, height: 85)
                            .border(settings.selectedColor, width: CGFloat(settings.showBorders ? settings.borderWidth : 0))
                            .padding(.top, 70)
                            .padding(.leading, 25)
                        Rectangle()
                            .fill(.clear)
                            .frame(width: 65, height: 110)
                            .border(settings.backgroundColor, width: CGFloat(settings.showBorders ? settings.borderWidth : 0))
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
