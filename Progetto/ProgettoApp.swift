//
//  ProgettoApp.swift
//  Progetto
//
//  Created by Students on 10/06/24.
//

import SwiftUI
import UIKit

struct ARViewControllerRepresentable: UIViewControllerRepresentable {
    typealias UIViewControllerType = ARViewController
    
    func makeUIViewController(context: Context) -> ARViewController {
        return ARViewController()
    }
    
    func updateUIViewController(_ viewController: ARViewController, context: Self.Context) {
        
    }
}

@main
struct ProgettoApp: App {
    var body: some Scene {
        WindowGroup {
            ARViewControllerRepresentable()
        }
    }
}
