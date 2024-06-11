//
//  ARViewController.swift
//  Progetto
//
//  Created by Students on 10/06/24.
//

import SwiftUI
import RealityKit
import ARKit

class ARViewController: UIViewController {
    
    @IBOutlet weak var arView: ARView!
    @IBOutlet weak var addObject: UIButton!
    @IBOutlet weak var settings: UIButton!
    
    var selectedObject: ARObject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func didTapOnAddObject(_ sender: Any) {
        print("didTapOnAddObject")
        
        var selectObjectMenu: UIHostingController<SelectObjectMenu>!
        selectObjectMenu = UIHostingController(rootView: SelectObjectMenu { obj in
            selectObjectMenu.dismiss(animated: true)
            self.selectedObject = obj
        })
        selectObjectMenu.modalPresentationStyle = .pageSheet
        selectObjectMenu.isModalInPresentation = false
        selectObjectMenu.sheetPresentationController?.detents = [.medium()]
        present(selectObjectMenu, animated: true)
    }
    
    
    @IBAction func didTapOnSettings(_ sender: Any) {
        print("didTapOnSettings")
        
        let settingsMenu = UIHostingController(rootView: SettingsMenu())
        settingsMenu.modalPresentationStyle = .pageSheet
        settingsMenu.isModalInPresentation = false
        settingsMenu.sheetPresentationController?.detents = [.large()]
        present(settingsMenu, animated: true)
        
    }
}
