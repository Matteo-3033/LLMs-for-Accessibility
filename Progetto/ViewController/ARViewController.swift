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
    
    private var prompts: [String: Any]!
    
    private var session: [(String, String, String)] = []
    
    let objectSelectedNotification = NSNotification.Name(rawValue: "objectSelected")
    private var selection: [ARAnchor] = []
    
    private enum LLMGeneralPrompt: String {
        case full = "full_prompt"
        case ar = "ar_prompt"
        case world = "real_world_prompt"
        
        public func getText(_ prompts: [String: Any]) -> String {
            return prompts[rawValue] as! String
        }
    }
    
    private enum LLMQuestionPrompt: String, CaseIterable {
        case background = "background"
        case foreground = "foreground"
        case obstacles = "obstacles"
        case color = "color"
        
        public func getPrompt(_ prompts: [String: Any]) -> (String, String) {
            let array = prompts[rawValue] as! [String]
            return (array[0], array[1])
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        
        arManager = ARManager(arView: arView)
        arManager.startSession()
        
        initPrompts()
        initGestures()
    }
    
    private func initPrompts() {
        guard let pListPath = Bundle.main.path(
            forResource: "prompts", ofType: "plist"
        ) else { return }
        
        guard let data = FileManager.default.contents(
            atPath: pListPath
        ) else { return }
        
        guard let plist = try? PropertyListSerialization.propertyList(
            from: data, options: .mutableContainers, format: nil
        ) as? [String: Any] else { return }
        
        prompts = plist
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
        
        guard let transform = arView.raycast(
            from: sender.location(in: self.arView),
            allowing: .estimatedPlane, alignment: .any
        ).first?.worldTransform else { return }
            
        let anchor = arManager.getNearestAnchor(transform: transform)
        if let anchor, !selection.contains(where: { $0.identifier == anchor.identifier }) {
            selection.append(anchor)
            NotificationCenter.default.post(name: objectSelectedNotification, object: nil, userInfo: nil)
        }
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
        showQuestionsAlert()
    }
    
    @objc
    private func didTwoFingerSwipeDown(sender: UISwipeGestureRecognizer) {
        print("didTwoFingerSwipeDown: frame acquisition")
        
        arManager.currentFrame { frame in
            guard let frame else { return }
            self.getImageDescription(text: LLMGeneralPrompt.full.getText(self.prompts), image: frame)
        }
    }
    
    @objc
    private func didTwoFingerSwipeLeft(sender: UISwipeGestureRecognizer) {
        print("didTwoFingerSwipeLeft: camera frame acquisition")
        
        arManager.currentCameraFrame { frame in
            guard let frame else { return }
            self.getImageDescription(text: LLMGeneralPrompt.world.getText(self.prompts), image: frame)
        }
    }
    
    @objc
    private func didTwoFingerSwipeRight(sender: UISwipeGestureRecognizer) {
        print("didTwoFingerSwipeRight: AR frame acquisition")
        	
        arManager.currentARFrame { frame in
            guard let frame else { return }
            self.getImageDescription(text: LLMGeneralPrompt.ar.getText(self.prompts), image: frame)
        }
    }
    
    private func showQuestionsAlert() {
        let alert = UIAlertController(title: "Choose question", message: "Please select a question to ask", preferredStyle: .actionSheet)
        
        for p in LLMQuestionPrompt.allCases {
            let (question, prompt) = p.getPrompt(prompts)
            
            alert.addAction(UIAlertAction(title: question, style: .default) { action in
                alert.dismiss(animated: true)
                self.handleQuestion(question: p, prompt: prompt)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Custom question", style: .default) { action in
            self.arManager.currentFrame { frame in
                guard let frame else { return }
                alert.dismiss(animated: true)
                self.showCustomQuestionAlert(image: frame)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(alert, animated: true)
    }
    
    private func showCustomQuestionAlert(image: UIImage) {
        let alert = UIAlertController(title: "Custom Question", message: "Please enter your question", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Enter your question"
        }
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { action in
            if let textField = alert.textFields?.first, let question = textField.text, !question.isEmpty {
                alert.dismiss(animated: true)
                self.getImageDescription(text: question, image: image)
            }
        }

        alert.addAction(confirmAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(alert, animated: true)
    }
    
    private func handleQuestion(question: LLMQuestionPrompt, prompt: String) {
        let method: Selector? = switch question {
        case .color: #selector(handleColorQuestion(notification:))
        default: nil
        }
        
        if let method {
            NotificationCenter.default.addObserver(self, selector: method, name: objectSelectedNotification, object: nil)
        } else {
            arManager.currentFrame { frame in
                guard let frame else { return }
                self.getImageDescription(text: prompt, image: frame)
            }
        }
    }
    
    @objc
    private func handleColorQuestion(notification: NSNotification) {
        guard let obj = selection.first else { return }
        selection.removeAll()
        NotificationCenter.default.removeObserver(self)
        
        
        
    }
    
    private func getImageDescription(text prompt: String, image: UIImage) {
        image.saveToGallery()
        
        guard let base64 = image.getBase64() else { return }
        
        print("Prompt: \(prompt)")
        communication.getDescription(
            text: prompt,
            imageBase64: base64
        ) { text, error in
            guard let text, error == nil else {
                print("Error during request: \(error ?? "")")
                return
            }
            print("Description from server: \(text)")
            self.speak(text: text)
            
            self.session.append((
                prompt,
                text,
                base64
            ))
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
    
    @IBAction func didTapOnSave(_ sender: Any) {
        print("didTapOnSave")
        
        DispatchQueue.global(qos: .background).async {
            var content = ""
            for tuple in self.session {
                content += "\(tuple.0),\n \(tuple.1),\n \(tuple.2)\n\n"
            }
        
            if let documentDirectory = FileManager.default.urls(
                for: .documentDirectory, in: .userDomainMask
            ).first {
                let currentDate = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
                let timestamp = dateFormatter.string(from: currentDate)

                let fileName = "session_\(timestamp)"
                
                let fileURL = URL(
                    fileURLWithPath: fileName, relativeTo: documentDirectory
                ).appendingPathExtension("txt")
                
                do {
                    try content.write(to: fileURL, atomically: true, encoding: .utf8)
                    print("File written successfully to \(fileURL.path)")
                    
                    DispatchQueue.main.async {
                        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                        self.present(activityViewController, animated: true, completion: nil)
                    }
                } catch {
                    print("Failed to write file: \(error)")
                }
            } else {
                print("Failed to find the document directory")
            }
        }
        
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
        let data = jpegData(compressionQuality: 0.5)
        
        if let data {
            return "data:image/jpeg;base64,\(data.base64EncodedString())"
        }
        
        return nil
    }
}
