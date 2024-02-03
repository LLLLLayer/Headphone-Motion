//
//  CoreMotionViewController.swift
//  HeadphoneMotion
//
//  Created by yangjie.layer on 2024/2/3.
//

import UIKit
import CoreMotion
import SceneKit

class CoreMotionViewController: UIViewController {
    
    private let manager = CMHeadphoneMotionManager()
    
    private let textView: UITextView = {
        let view = UITextView()
        view.text = "Waiting..."
        view.isEditable = false
        view.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        view.layer.cornerRadius = 8
        view.backgroundColor = UIColor.systemGray.withAlphaComponent(0.5)
        return view
    }()
    
    fileprivate var cubeNode: SCNNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        guard manager.isDeviceMotionAvailable else {
            print("Device Motion is not Available.")
            return
        }
        manager.delegate = self
        manager.startDeviceMotionUpdates(to: OperationQueue.main) { [weak self] deviceMotion, error in
            guard let self, error == nil else {
                print("Start device motion updates failed.")
                return
            }
            self.printData(from: deviceMotion)
            self.updateNodeRotate(from: deviceMotion)
        }
    }
    
    deinit {
        manager.stopDeviceMotionUpdates()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            textView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            textView.heightAnchor.constraint(equalToConstant: 300)
        ])
        setUpScene()
    }
}

extension CoreMotionViewController: CMHeadphoneMotionManagerDelegate {
    
    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        print("headphoneMotionManagerDidConnect")
    }
    
    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        print("headphoneMotionManagerDidDisconnect")
    }
    
    private func printData(from deviceMotion: CMDeviceMotion?) {
        guard let deviceMotion else {
            print("Device motion is empty.")
            return
        }
        let text = """
            Attitude:
                pitch: \((180/Double.pi)*deviceMotion.attitude.pitch)
                roll: \((180/Double.pi)*deviceMotion.attitude.roll)
                yaw: \((180/Double.pi)*deviceMotion.attitude.yaw)
            Rotation Rate:
                x: \((180/Double.pi)*deviceMotion.rotationRate.x)
                y: \((180/Double.pi)*deviceMotion.rotationRate.y)
                z: \((180/Double.pi)*deviceMotion.rotationRate.z)
            Gravitational Acceleration:
                x: \(deviceMotion.gravity.x)
                y: \(deviceMotion.gravity.y)
                z: \(deviceMotion.gravity.z)
            User Acceleration:
                x: \(deviceMotion.userAcceleration.x)
                y: \(deviceMotion.userAcceleration.y)
                z: \(deviceMotion.userAcceleration.z)
            Magnetic Field:
                field: \(deviceMotion.magneticField.field)
                accuracy: \(deviceMotion.magneticField.accuracy)
            Heading:
                \(deviceMotion.heading)
            Sensor Location:
                \(deviceMotion.sensorLocation.rawValue)
            """
        print(text)
        textView.text = text
    }
}

// MARK: - SceneKit

extension CoreMotionViewController {
    
    func updateNodeRotate(from deviceMotion: CMDeviceMotion?) {
        guard let deviceMotion else {
            return
        }
        let data = deviceMotion.attitude
        cubeNode.eulerAngles = SCNVector3(-data.pitch, -data.yaw, -data.roll)
    }
    
    func setUpScene() {
        let scnView = SCNView(frame: CGRect.zero)
        scnView.backgroundColor = UIColor.clear
        scnView.showsStatistics = true
        scnView.allowsCameraControl = false
        view.addSubview(scnView)
        scnView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scnView.widthAnchor.constraint(equalToConstant: 400),
            scnView.topAnchor.constraint(equalTo: textView.bottomAnchor),
            scnView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scnView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        let scene = SCNScene()
        scnView.scene = scene
        
        // Adding a camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
        scene.rootNode.addChildNode(cameraNode)
        
        // Adding an omnidirectional light source to the scene
        let omniLight = SCNLight()
        omniLight.type = .omni
        let omniLightNode = SCNNode()
        omniLightNode.light = omniLight
        omniLightNode.position = SCNVector3(x: 10, y: 10, z: 10)
        scene.rootNode.addChildNode(omniLightNode)
        
        // Adding a light source to your scene that illuminates from all directions.
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor.darkGray
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        scene.rootNode.addChildNode(ambientLightNode)
        
        // Adding a cube(head) to a scene
        let cube:SCNGeometry = SCNBox(width: 5, height: 5, length: 5, chamferRadius: 1)
        let eye:SCNGeometry = SCNSphere(radius: 0.5)
        let leftEye = SCNNode(geometry: eye)
        let rightEye = SCNNode(geometry: eye)
        leftEye.position = SCNVector3(x: 0.8, y: 0.8, z: 2.5)
        rightEye.position = SCNVector3(x: -0.8, y: 0.8, z: 2.5)
        
        let nose:SCNGeometry = SCNSphere(radius: 0.3)
        let noseNode = SCNNode(geometry: nose)
        noseNode.position = SCNVector3(x: 0, y: 0, z: 3)
        
        let mouth:SCNGeometry = SCNBox(width: 2, height: 0.2, length: 0.2, chamferRadius: 0.4)
        let mouthNode = SCNNode(geometry: mouth)
        mouthNode.position = SCNVector3(x: 0, y: -1, z: 3)
        
        cubeNode = SCNNode(geometry: cube)
        cubeNode.addChildNode(leftEye)
        cubeNode.addChildNode(rightEye)
        cubeNode.addChildNode(noseNode)
        cubeNode.addChildNode(mouthNode)
        cubeNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(cubeNode)
    }
}

