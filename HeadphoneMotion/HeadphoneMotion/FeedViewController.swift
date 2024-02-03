//
//  FeedViewController.swift
//  HeadphoneMotion
//
//  Created by yangjie.layer on 2024/2/3.
//

import UIKit
import CoreMotion
import SceneKit

class FeedViewController: UIViewController {
    
    private var items: [UIColor] = [.red, .orange, .yellow, .green, .blue, .purple]
    private lazy var collectionView = {
        // 设置 collectionView 的布局
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout:layout)

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        return collectionView
    }()
    
    private let manager = CMHeadphoneMotionManager()
    
    fileprivate var cubeNode: SCNNode!
    
    fileprivate var disableChangePage = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupManager()
    }
    
    deinit {
        manager.stopDeviceMotionUpdates()
    }
    
    private func setupUI() {
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
        setUpScene()
    }
    
    private func setupManager() {
        guard manager.isDeviceMotionAvailable else {
            print("Device Motion is not Available.")
            return
        }
        manager.startDeviceMotionUpdates(to: OperationQueue.main) { [weak self] deviceMotion, error in
            guard let self, error == nil else {
                print("Start device motion updates failed.")
                return
            }
            self.changePageIfNeed(from: deviceMotion)
            self.updateNodeRotate(from: deviceMotion)
        }
    }
}

// MARK: - ChangePage

extension FeedViewController {
    
    func changePageIfNeed(from deviceMotion: CMDeviceMotion?) {
        guard let deviceMotion, disableChangePage == false else {
            return
        }
        disableChangePage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.disableChangePage = false
        }
        let pitch = (180 / Double.pi) * deviceMotion.attitude.pitch
        print(pitch)
        if pitch > 10 {
            // Up
            if let current = collectionView.indexPathsForVisibleItems.first, current.item < items.count {
                collectionView.scrollToItem(at: IndexPath(item: current.item + 1, section: 0), at: .bottom, animated: true)
            }
        } else if pitch < -10 {
            // Down
            if let current = collectionView.indexPathsForVisibleItems.first, current.item > 0 {
                collectionView.scrollToItem(at: IndexPath(item: current.item - 1, section: 0), at: .top, animated: true)
            }
        }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout

extension FeedViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        cell.contentView.backgroundColor = items[indexPath.item]
        return cell
    }
}

// MARK: - SceneKit

extension FeedViewController {
    
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
            scnView.widthAnchor.constraint(equalToConstant: 200),
            scnView.heightAnchor.constraint(equalToConstant: 200),
            scnView.rightAnchor.constraint(equalTo: view.rightAnchor),
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
