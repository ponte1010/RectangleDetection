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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // セッション設定の作成
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // ビューのセッションを実行
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // ビューのセッションを一時停止
        sceneView.session.pause()
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("ARAnchor Added")
        
        sceneView.debugOptions = []
    }
    
    @IBAction func doubleTapped(_ sender: Any) {
        let tapRecognizer = sender as! UITapGestureRecognizer
        
        if tapRecognizer.state == .recognized {
            print("tapped")
            
            if let drawLayer = self.drawLayer {
                drawLayer.sublayers?.forEach({ layer in
                    layer.removeFromSuperlayer()
                })
            }
            
            let layer = CALayer()
            layer.bounds = sceneView.bounds
            layer.anchorPoint = CGPoint.zero
            layer.opacity = 0.5
            self.view.layer.addSublayer(layer)
            drawLayer = layer
            
            if let frame = self.sceneView.session.currentFrame {
                findRectangle(frame: frame)
            }
        }
    }
    
    // Updates selectedRectangleObservation with the the rectangle found in the given ARFrame at the given location
    fileprivate func findRectangle(frame currentFrame: ARFrame) {
        // Perform request on background thread
        DispatchQueue.global(qos: .background).async {
            let request = VNDetectRectanglesRequest(completionHandler: self.handleDetectedRectangles)
            request.maximumObservations = 1
            
            let handler = VNImageRequestHandler(cvPixelBuffer: currentFrame.capturedImage, orientation: .downMirrored, options: [:])
            do {
                try handler.perform([request])
            } catch let error as NSError {
                print("Failed to perform image request: \(error)")
                return
            }
        }
    }
    
    fileprivate func handleDetectedRectangles(request: VNRequest?, error: Error?) {
        if let nsError = error as NSError? {
            print("Rectangle Detection Error \(nsError)")
            return
        }
        // Since handlers are executing on a background thread, explicitly send draw calls to the main thread.
        DispatchQueue.main.async {
            guard let results = request?.results as? [VNRectangleObservation] else { return }
            if let drawLayer = self.drawLayer {
                self.draw(rectangles: results, onImageLayer: drawLayer)
                drawLayer.setNeedsDisplay()
            }
        }
    }
    
    fileprivate func draw(rectangles: [VNRectangleObservation], onImageLayer drawlayer: CALayer) {
        CATransaction.begin()
        
        for observation in rectangles {
            let rectLayer = shapeLayerRect(color: .red, observation: observation)
            
            // 画像の上にpathLayerを追加
            drawlayer.addSublayer(rectLayer)
        }
        
        CATransaction.commit()
    }
    
    fileprivate func shapeLayerRect(color: UIColor, observation: VNRectangleObservation) -> CAShapeLayer {
        // Create a new layer.
        let layer = CAShapeLayer()
        
        guard let drawBounds = self.drawLayer?.bounds else { return layer }
        let orientation = UIApplication.shared.statusBarOrientation
        guard let arTransform = self.sceneView.session.currentFrame?.displayTransform(for: orientation, viewportSize: drawBounds.size) else { return layer }
        let t = CGAffineTransform(scaleX: drawBounds.width, y: drawBounds.height)
        
        let convertedTopLeft = observation.topLeft.applying(arTransform).applying(t)
        let convertedTopRight = observation.topRight.applying(arTransform).applying(t)
        let convertedBottomLeft = observation.bottomLeft.applying(arTransform).applying(t)
        let convertedBottomRight = observation.bottomRight.applying(arTransform).applying(t)
        
        let linePath = UIBezierPath()
        linePath.move(to: convertedTopLeft)
        linePath.addLine(to: convertedTopRight)
        linePath.addLine(to: convertedBottomRight)
        linePath.addLine(to: convertedBottomLeft)
        linePath.addLine(to: convertedTopLeft)
        linePath.close()
        layer.strokeColor = color.cgColor
        layer.lineWidth = 2
        layer.path = linePath.cgPath
        
        return layer
    }
    
}

