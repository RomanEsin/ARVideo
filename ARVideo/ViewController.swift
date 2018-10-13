//
//  ViewController.swift
//  ARVideo
//
//  Created by Roman Esin on 12.10.2018.
//  Copyright © 2018 Roman Esin. All rights reserved.
//

import UIKit
import SceneKit
import SpriteKit
import ARKit
import AVFoundation

class ViewController: UIViewController, ARSCNViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var imagePicker = UIImagePickerController()
    var titles = ["video", "video2"]
    var images = [UIImage]()
    var video = SCNNode()

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var pickerView: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Image Picker Setup
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        
        pickerView.dataSource = self
        pickerView.delegate = self
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        video = sceneView.scene.rootNode.childNode(withName: "video", recursively: true)!
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()
        
        let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil)!
        configuration.trackingImages = referenceImages
        
        //For Tracking Selected Images
//        if !self.images.isEmpty {
//            for image in self.images {
//                let images = ARReferenceImage((image.cgImage)!, orientation: CGImagePropertyOrientation.up, physicalWidth: (image.size.width))
//                referenceImages.update(with: images)
//            }
//        }
        
        // Run the view's session
        configuration.maximumNumberOfTrackedImages = 2
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    //TODO: - Option To Choose What Images To Track
    func takePic() {
        imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    //MARK: - Image Picker Controller
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        images.append(image!)
    }
    
    //MARK:- Did Add Node For Anchor
    var imageIsDetected = false
    var isDetected: Bool {
        get {
            return imageIsDetected
        }
        set {
            imageIsDetected = newValue
            if newValue {
                
            } else {
                
            }
        }
    }
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARImageAnchor else { return }
        
    }
    let feedback = UIImpactFeedbackGenerator(style: .medium)
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARImageAnchor else { return }
        isDetected = true
        DispatchQueue.main.async {
            self.feedback.prepare()
        }
        
        //Setup PlaneNode
        let size = anchor.referenceImage.physicalSize
        let plane = SCNPlane(width: size.width, height: size.height)
        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles.x = -.pi / 2
        planeNode.opacity = 0
        
        planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        plane.cornerRadius = plane.width > plane.height ? plane.width / 10 : plane.height / 10
        
        var videoName = ""
        if anchor.referenceImage.name == "airpods" {
            videoName = "airpods"
        } else if anchor.referenceImage.name == "physics" {
            videoName = "video3"
        } else if anchor.referenceImage.name == "history" {
            let alert = UIAlertController(title: "Ну Ты Вообщеееее", message: "Выкидывай эту хрень из дому", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                alert.dismiss(animated: true, completion: nil)
            }))
            present(alert, animated: true, completion: nil)
            return
        } else {
            videoName = "video"
        }
        //Get Video Resolution
        let resolution = resolutionForLocalVideo(url: Bundle.main.url(forResource: videoName, withExtension: "mp4")!)!
        
        //Add Video To Node
        let player = AVPlayer(url: Bundle.main.url(forResource: videoName, withExtension: "mp4")!)
        let video = self.video.copy() as! SCNNode
        let aspectRatio = resolution.width / resolution.height
        
        video.geometry = SCNPlane(width: size.height * aspectRatio, height: size.height)
       
        video.geometry?.firstMaterial?.diffuse.contents = player
        
        node.addChildNode(video)
        video.scale = SCNVector3(0, 0, 0)
        video.opacity = 0
        video.position.y = 0
        
        //Add Corner Radius
        let geom = video.geometry as! SCNPlane
        geom.cornerRadius = geom.width > geom.height ? geom.width / 10 : geom.height / 10
        
        //Run Actions
        let scaleUp = SCNAction.scale(to: 1, duration: 2)
        scaleUp.timingMode = .easeIn
        
        let fadeIn = SCNAction.fadeOpacity(to: 0.98, duration: 2)
        fadeIn.timingMode = .easeIn
        
        let move = SCNAction.moveBy(x: 0, y: 0.07, z: 0, duration: 1)
        move.timingMode = .easeIn
        
        let group = SCNAction.group([scaleUp, fadeIn, move])
        video.runAction(group) {
            DispatchQueue.main.async {
                player.play()
                self.feedback.impactOccurred()
            }
        }
    }
    
    //MARK: - Get Resolution Of Video By URL
    private func resolutionForLocalVideo(url: URL) -> CGSize? {
        guard let track = AVURLAsset(url: url).tracks(withMediaType: AVMediaType.video).first else { return nil }
        let size = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: abs(size.width), height: abs(size.height))
    }
    
    //MARK: - Setup Delegate Methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    @IBAction func reset(_ sender: UIButton) {
        viewWillAppear(true)
    }
    
    @IBAction func takeImage(_ sender: UIButton) {
        //        takePic()
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return titles.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return titles[row]
    }
}
