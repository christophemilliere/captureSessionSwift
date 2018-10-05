//
//  ViewController.swift
//  DemosCapture
//
//  Created by Christophe on 03/10/2018.
//  Copyright © 2018 Christophe. All rights reserved.
//

import UIKit

import AVFoundation
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var ui_startSession: UIButton!
    @IBOutlet weak var ui_preview: UIView!
    
    @IBOutlet weak var ui_infoLabel: UILabel!
    @IBOutlet weak var ui_titleLabel: UILabel!
    
    let captureSession = AVCaptureSession()
    lazy var imageRecognitionRequest: VNRequest = {
        let model = try! VNCoreMLModel(for: Inceptionv3().model)
        let request = VNCoreMLRequest(model: model, completionHandler: self.imageRecognitionHandler)
        return request
    }()
    
    func imageRecognitionHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNClassificationObservation],
        let bestGuess = observations.first else { return }
        
        var finalIdentifier = bestGuess.identifier
        
        if finalIdentifier.contains("hotdog") {
            finalIdentifier = "hotdog"
        } else {
            let commaIndex = finalIdentifier.index(of: ",") ?? finalIdentifier.endIndex
            finalIdentifier = finalIdentifier[..<commaIndex] + "(not a hotdog)"
        }
        DispatchQueue.main.async {
            if bestGuess.confidence > 0.6 {
                self.ui_titleLabel.text = finalIdentifier
                self.ui_infoLabel.text = " Problabilité \(bestGuess.confidence)"
            }
            self.ui_infoLabel.text = "Recherche en cours..."
        }
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func startSessionButtonPressed(_ sender: Any) {
        if captureSession.isRunning {
            captureSession.stopRunning()
            ui_startSession.setTitle("Démarrer la capture", for: .normal)
        } else {
            if captureSession.inputs.count == 0 {
                configureCaptureSession()
                ui_startSession.setTitle("Arréter la capture", for: .normal)
            }
            // 4 - Démarrer la session
            captureSession.startRunning()
            ui_startSession.setTitle("Arréter la capture", for: .normal)
        }
    }
    
    func configureCaptureSession() {
        // 1 - Configurer les entrées
        if let camera = AVCaptureDevice.default(for: AVMediaType.video),
            let cameraFeed = try? AVCaptureDeviceInput(device: camera) {
            captureSession.addInput(cameraFeed)
            
            // 2 - Configurer les sorties
            let outputFeed = AVCaptureVideoDataOutput()
            outputFeed.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated))
            captureSession.addOutput(outputFeed)
            
            // 3 - Configurer l'aperçu
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = ui_preview.bounds
            ui_preview.layer.addSublayer(previewLayer)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelbufer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelbufer, orientation: CGImagePropertyOrientation.up, options: [:])
        do {
            try imageRequestHandler.perform([imageRecognitionRequest])
        } catch {
            print(error.localizedDescription)
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    }


}

