//
//  ViewController.swift
//  ARVideo
//
//  Created by Юрий Есин on 12.10.2018.
//  Copyright © 2018 Roman Esin. All rights reserved.
//

import UIKit
import SceneKit
import SpriteKit
import ARKit
import AVFoundation

class ViewController: UIViewController, ARSCNViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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
    
    var imagePicker = UIImagePickerController()
    var titles = ["video", "video2"]
    var images = [UIImage]()
    var video = SCNNode()

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var pickerView: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    func takePic() {
        imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        images.append(image!)
    }
    
    let feedback = UIImpactFeedbackGenerator(style: .medium)
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARImageAnchor else { return }
        DispatchQueue.main.async {
            self.feedback.prepare()
        }
        print("Found Image")
        
        let scaleUp = SCNAction.scale(to: 1, duration: 2)
        scaleUp.timingMode = .easeIn
        
        let fadeIn = SCNAction.fadeOpacity(to: 0.95, duration: 2)
        fadeIn.timingMode = .easeIn
        
        let move = SCNAction.moveBy(x: 0, y: 0.07, z: 0, duration: 1)
        move.timingMode = .easeIn
        
        let size = anchor.referenceImage.physicalSize
        let plane = SCNPlane(width: size.width, height: size.height)
        let planeNode = SCNNode(geometry: plane)
        planeNode.opacity = 0.7
        planeNode.eulerAngles.x = -.pi / 2
        planeNode.opacity = 0
        
        planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.white
//        planeNode.runAction(SCNAction.fadeOpacity(to: 0.7, duration: 0.5))
        plane.cornerRadius = plane.width > plane.height ? plane.width / 10 : plane.height / 10
        
//        let videoURL = Bundle.main.url(forResource: "video3", withExtension: "mp4")!
//        let videoPlayer = AVPlayer(url: videoURL)
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
        
        //Create Scene
//        let contentScene = SKScene(size: CGSize(width: resolution.width, height: resolution.height))
//        let videoNode = SKVideoNode(fileNamed: "\(videoName).mp4")
//        let videoNode = SKVideoNode(avPlayer: player)
//        videoNode.size = contentScene.size
//        videoNode.position = CGPoint(x: contentScene.size.width / 2, y: contentScene.size.height / 2)
//        videoNode.yScale = -1
//        player.isMuted = true
//        videoNode.pause()
//
//        contentScene.addChild(videoNode)
        
        //Add Video To Node
        let player = AVPlayer(url: Bundle.main.url(forResource: videoName, withExtension: "mp4")!)
        let video = self.video.copy() as! SCNNode
        let aspectRatio = resolution.width / resolution.height
        
        video.geometry = SCNPlane(width: size.height * aspectRatio, height: size.height)
       
        video.geometry?.firstMaterial?.diffuse.contents = player
//        player.play()
        
        node.addChildNode(video)
        video.scale = SCNVector3(0, 0, 0)
        video.opacity = 0
        video.position.y = 0
        
        //Add Corner Radius
        let geom = video.geometry as! SCNPlane
        geom.cornerRadius = geom.width > geom.height ? geom.width / 10 : geom.height / 10
        
        //Run Actions
        let group = SCNAction.group([scaleUp, fadeIn, move])
        video.runAction(group) {
            DispatchQueue.main.async {
                player.play()
                self.feedback.impactOccurred()
            }
        }
    }
    
    private func resolutionForLocalVideo(url: URL) -> CGSize? {
        guard let track = AVURLAsset(url: url).tracks(withMediaType: AVMediaType.video).first else { return nil }
        let size = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: abs(size.width), height: abs(size.height))
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    
}
