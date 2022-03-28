//
//  ViewController.swift
//  ARPoster
//
//  Created by H.W. Hsiao on 2022/3/28.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate
{
    @IBOutlet var sceneView: ARSCNView!
    
    let videoPlayer: AVPlayer? = {
        if let url = Bundle.main.url(forResource: "WaterActivitiesInTaiwan", withExtension: "mp4")
        {
            return AVPlayer(url: url)
        } else {
            return nil
        }
    }()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.videoPlayer?.currentItem, queue: .main)
        { [weak self] notification in
            // 影片播完後回到0秒
            self?.videoPlayer?.seek(to: .zero)
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: Bundle.main) else {
            fatalError("Failed to load the reference images")
        }
        
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()
        
        configuration.trackingImages = referenceImages
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor)
    {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        
        // 根據圖片實際大小生成plane
        let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
        
        // 用plane裝videoPlayer
        plane.firstMaterial?.diffuse.contents = self.videoPlayer
        
        // 用plane生成node，調整node角度，將node加上畫面
        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles.x = -.pi / 2
        node.addChildNode(planeNode)
        
        self.videoPlayer?.play()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor)
    {
        if let pointOfView = sceneView.pointOfView
        {
            if sceneView.isNode(node, insideFrustumOf: pointOfView)
            {
                // 圖片還在螢幕範圍內，若影片沒有播放，則播放影片
                if videoPlayer?.rate == 0.0
                {
                    videoPlayer?.play()
                }
            }
            else
            {
                // 圖片移出螢幕後暫停播放影片
                videoPlayer?.pause()
            }
        }
    }
    
}
