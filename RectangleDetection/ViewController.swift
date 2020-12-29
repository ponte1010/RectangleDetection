//
//  ViewController.swift
//  RectangleDetection
//
//  Created by miwa on 2020/12/26.
//

import UIKit
import SceneKit
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    
    // バウンディングボックスのパスを描画するレイヤー
    var drawLayer: CALayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ビューのデリゲートを設定
        sceneView.delegate = self
        
        // fpsやタイミング情報などの統計情報を表示
        sceneView.showsStatistics = true
        
        // 新しいシーンの作成
        let scene = SCNScene()
        
        // シーンをビューに設定
        sceneView.scene = scene
    }


}

