//
//  ViewController.swift
//  ArGame
//
//  Created by Nik on 2/13/21.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {
    
    lazy var targetColor: UIColor = greenButtonOutlet.backgroundColor!
    var player: AVAudioPlayer?
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var greenButtonOutlet: UIButton!
    @IBOutlet weak var purpleButtonOutlet: UIButton!
    @IBOutlet weak var orangeButtonOutlet: UIButton!
    @IBOutlet weak var pinkButtonOutlet: UIButton!
    @IBOutlet weak var blueButtonOutlet: UIButton!
    @IBOutlet weak var yellowButtonOutlet: UIButton!
    
    func OpacityForButtons () {
        greenButtonOutlet.alpha = 0.2
        purpleButtonOutlet.alpha = 0.2
        orangeButtonOutlet.alpha = 0.2
        pinkButtonOutlet.alpha = 0.2
        blueButtonOutlet.alpha = 0.2
        yellowButtonOutlet.alpha = 0.2
        greenButtonOutlet.layer.borderWidth = 0
        purpleButtonOutlet.layer.borderWidth = 0
        orangeButtonOutlet.layer.borderWidth = 0
        pinkButtonOutlet.layer.borderWidth = 0
        blueButtonOutlet.layer.borderWidth = 0
        yellowButtonOutlet.layer.borderWidth = 0
    }
    
    @IBAction func buttonAction(_ sender: UIButton) {
        OpacityForButtons()
        sender.alpha = 1
        sender.layer.borderWidth = 2
        sender.layer.borderColor = UIColor.white.cgColor
        targetColor = sender.backgroundColor!
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        fireBall(color: targetColor)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        greenButtonOutlet.layer.cornerRadius = 15
        purpleButtonOutlet.layer.cornerRadius = 15
        orangeButtonOutlet.layer.cornerRadius = 15
        pinkButtonOutlet.layer.cornerRadius = 15
        blueButtonOutlet.layer.cornerRadius = 15
        yellowButtonOutlet.layer.cornerRadius = 15
        
        OpacityForButtons()
        greenButtonOutlet.alpha = 1
        greenButtonOutlet.layer.borderWidth = 2
        greenButtonOutlet.layer.borderColor = UIColor.white.cgColor
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.scene.physicsWorld.contactDelegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        addTargetNodes ()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func playSound(sound : String, format: String) {
        guard let url = Bundle.main.url(forResource: sound, withExtension: format) else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            guard let player = player else { return }
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func getUserVector() -> (SCNVector3, SCNVector3) {
        if let frame = self.sceneView.session.currentFrame {
            let mat = SCNMatrix4(frame.camera.transform)
            let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33)
            let pos = SCNVector3(mat.m41, mat.m42, mat.m43)
            return (dir, pos)
        }
        return (SCNVector3(0, 0, -1), SCNVector3(0, 0, -0.2))
    }
    
    func createBall(color : UIColor)->SCNNode{
        let ballGeometry = SCNSphere(radius: 0.2)
        let material = SCNMaterial()
        material.diffuse.contents = color
        let ballNode = SCNNode(geometry: ballGeometry)
        ballNode.geometry?.materials = [material]
        ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        ballNode.physicsBody?.isAffectedByGravity = false
        
        ballNode.name = "ball"
        ballNode.physicsBody?.categoryBitMask = CollisionCategory.missileCategory.rawValue
        ballNode.physicsBody?.collisionBitMask = CollisionCategory.targetCategory.rawValue
        
        return ballNode
    }
    
    
    func fireBall(color : UIColor){
        var node = SCNNode()
        node = createBall(color: color)
        let (direction, position) = self.getUserVector()
        node.position = position
        var nodeDirection = SCNVector3()
        nodeDirection  = SCNVector3(direction.x*4,direction.y*4,direction.z*4)
        node.physicsBody?.applyForce(nodeDirection, at: SCNVector3(0.1,0,0), asImpulse: true)
        playSound(sound: "explosion", format: "wav")
        
        node.physicsBody?.applyForce(nodeDirection , asImpulse: true)
        sceneView.scene.rootNode.addChildNode(node)
    }
    
    func addTargetNodes(){
        let colors: [UIColor] = [greenButtonOutlet.backgroundColor!, purpleButtonOutlet.backgroundColor!, orangeButtonOutlet.backgroundColor!, pinkButtonOutlet.backgroundColor!, blueButtonOutlet.backgroundColor!, yellowButtonOutlet.backgroundColor!]
        
        for _ in 1...100 {
            
            let boxGeometry = SCNBox(width: 0.5, height: 0.5, length: 0.5, chamferRadius: 0)
            let material = SCNMaterial()
            material.diffuse.contents = colors.randomElement()
            let node = SCNNode(geometry: boxGeometry)
            node.geometry?.materials = [material]
            
            node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
            node.physicsBody?.isAffectedByGravity = false
            node.position = SCNVector3(randomFloat(min: -10, max: 10),randomFloat(min: -4, max: 5),randomFloat(min: -10, max: 10))
            let action : SCNAction = SCNAction.rotate(by: .pi, around: SCNVector3(0, 1, 0), duration: 1.0)
            let forever = SCNAction.repeatForever(action)
            node.runAction(forever)
            
            node.physicsBody?.categoryBitMask = CollisionCategory.targetCategory.rawValue
            node.physicsBody?.contactTestBitMask = CollisionCategory.missileCategory.rawValue
            
            sceneView.scene.rootNode.addChildNode(node)
        }
    }
    
    func randomFloat(min: Float, max: Float) -> Float {
        return (Float(arc4random()) / 4294967296) * (max - min) + min
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        if contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.targetCategory.rawValue
            || contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.targetCategory.rawValue {
            
            if (contact.nodeA.geometry!.materials.first!.diffuse.contents as! UIColor == contact.nodeB.geometry!.materials.first!.diffuse.contents as! UIColor) {
                DispatchQueue.main.async {
                    contact.nodeA.removeFromParentNode()
                    contact.nodeB.removeFromParentNode()
                }
                playSound(sound: "1", format: "m4a")
            }else{
                DispatchQueue.main.async {
                    if let name = contact.nodeA.name, name == "ball" {
                        contact.nodeA.removeFromParentNode()
                    }else{
                        contact.nodeB.removeFromParentNode()
                    }
                }
                playSound(sound: "monkey", format: "mp3")
            }
        }
    }
    
}
struct CollisionCategory: OptionSet {
    let rawValue: Int
    static let missileCategory = CollisionCategory (rawValue: 1 << 0)
    static let targetCategory = CollisionCategory (rawValue: 1 << 1)
}
