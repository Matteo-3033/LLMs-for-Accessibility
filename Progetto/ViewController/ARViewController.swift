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
    
    private var objectToSpawn: ARObject?
    private var arManager: ARManager!
    
    private let communication = CommunicationController()
    private let synthesizer = AVSpeechSynthesizer()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        
        arManager = ARManager(arView: arView)
        arManager.startSession()
        
        initGestures()
     }
    
    private func initGestures() {
        let oneFingerDoubleTapGestureRecognizer = UITapGestureRecognizer(
            target: self, action: #selector(didOneFingerDoubleTap(sender:))
        )
        oneFingerDoubleTapGestureRecognizer.numberOfTapsRequired = 2
        oneFingerDoubleTapGestureRecognizer.numberOfTouchesRequired = 1
        arView.addGestureRecognizer(oneFingerDoubleTapGestureRecognizer)
        
        let oneFingerLongTapGestureRecognizer = UILongPressGestureRecognizer(
            target: self, action: #selector(didOneFingerLongTap(sender:))
        )
        arView.addGestureRecognizer(oneFingerLongTapGestureRecognizer)
        
        let twoFingerSwipeUpGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(didTwoFingerSwipeUp(sender:)))
        twoFingerSwipeUpGestureRecognizer.direction = .up
        twoFingerSwipeUpGestureRecognizer.numberOfTouchesRequired = 2
        arView.addGestureRecognizer(twoFingerSwipeUpGestureRecognizer)
        
        let twoFingerSwipeDownGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(didTwoFingerSwipeDown(sender:)))
        twoFingerSwipeDownGestureRecognizer.direction = .down
        twoFingerSwipeDownGestureRecognizer.numberOfTouchesRequired = 2
        arView.addGestureRecognizer(twoFingerSwipeDownGestureRecognizer)
        
        let twoFingerSwipeLeftGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(didTwoFingerSwipeLeft(sender:)))
        twoFingerSwipeLeftGestureRecognizer.direction = .left
        twoFingerSwipeLeftGestureRecognizer.numberOfTouchesRequired = 2
        arView.addGestureRecognizer(twoFingerSwipeLeftGestureRecognizer)
        
        let twoFingerSwipeRightGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(didTwoFingerSwipeRight(sender:)))
        twoFingerSwipeRightGestureRecognizer.direction = .right
        twoFingerSwipeRightGestureRecognizer.numberOfTouchesRequired = 2
        arView.addGestureRecognizer(twoFingerSwipeRightGestureRecognizer)
    }
    
    @objc
    private func didOneFingerDoubleTap(sender: UITapGestureRecognizer) {
        print("didOneFingerDoubleTap")
    }
    
    @objc
    private func didOneFingerLongTap(sender: UILongPressGestureRecognizer) {
        print("didOneFingerLongTap: state \(String(sender.state.rawValue))")
        
        guard let objectToSpawn, sender.state == .began else { return }
        guard let tappedPoint = arView.raycast(
            from: sender.location(in: self.arView),
            allowing: .estimatedPlane, alignment: .horizontal
        ).first else { return }
        
        arManager.addObjectToScene(obj: objectToSpawn, transform: tappedPoint.worldTransform)
        
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    
    @objc
    private func didTwoFingerSwipeUp(sender: UISwipeGestureRecognizer) {
        print("didTwoFingerSwipeUp")
    }
    
    @objc
    private func didTwoFingerSwipeDown(sender: UISwipeGestureRecognizer) {
        print("didTwoFingerSwipeDown: frame acquisition")
        
        arManager.currentFrame { frame in
            print("Saving current frame to gallery")
            frame?.saveToGallery()
        }
    }
    
    @objc
    private func didTwoFingerSwipeLeft(sender: UISwipeGestureRecognizer) {
        print("didTwoFingerSwipeLeft: camera frame acquisition")
        
        arManager.currentCameraFrame { frame in
            print("Saving current camera frame to gallery")
            frame?.saveToGallery()
            
            guard let base64 = frame?.getBase64() else { return }
            
            communication.getDescription(
                text: "Describe this image for a blind person",
                imageBase64: base64
            ) { text, error in
                guard let text, error == nil else {
                    print("Error during request: \(error ?? "")")
                    return
                }
                print("Description from server: \(text)")
                self.speak(text: text)
            }
        }
    }
    
    @objc
    private func didTwoFingerSwipeRight(sender: UISwipeGestureRecognizer) {
        print("didTwoFingerSwipeRight: AR frame acquisition")
        
        arManager.currentARFrame { frame in
            print("Saving current AR frame to gallery")
            frame?.saveToGallery()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = false
        
        arView.gestureRecognizers?.removeAll()
        arManager.stopSession()
        arManager = nil
    }
    
    @IBAction func didTapOnAddObject(_ sender: Any) {
        print("didTapOnAddObject")
        
        var selectObjectMenu: UIHostingController<SelectObjectMenu>!
        selectObjectMenu = UIHostingController(rootView: SelectObjectMenu { obj in
            selectObjectMenu.dismiss(animated: true)
            self.objectToSpawn = obj
        })
        selectObjectMenu.modalPresentationStyle = .pageSheet
        selectObjectMenu.isModalInPresentation = false
        selectObjectMenu.sheetPresentationController?.detents = [.medium()]
        present(selectObjectMenu, animated: true)
    }
    
    
    @IBAction func didTapOnSettings(_ sender: Any) {
        print("didTapOnSettings")
        
        var settingsMenu: UIHostingController<SettingsMenu>!
        settingsMenu = UIHostingController(rootView: SettingsMenu(settings: arManager.settings) { settings in
            settingsMenu.dismiss(animated: true)
            self.arManager.settings = settings
        })
        settingsMenu.modalPresentationStyle = .pageSheet
        settingsMenu.isModalInPresentation = false
        settingsMenu.sheetPresentationController?.detents = [.large()]
        present(settingsMenu, animated: true)
    }
    
    private func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        synthesizer.stopSpeaking(at: .word)
        synthesizer.speak(utterance)
    }
}

extension UIImage {
    public func saveToGallery() {
        UIImageWriteToSavedPhotosAlbum(self, nil, nil, nil)
    }
    
    public func getBase64() -> String? {
        let data = pngData()
        
        if let data {
            return "data:image/png;base64,\(data.base64EncodedString())"
        }
        
        return nil
    }
}
