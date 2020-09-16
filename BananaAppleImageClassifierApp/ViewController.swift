//
//  ViewController.swift
//  BananaAppleImageClassifierApp
//
//  Created by masato on 16/9/2020.
//  Copyright © 2020 Masato Miyai. All rights reserved.
//
// ------------ How to get Video through AVCaptureSession --------------
//import AVKit
////MARK: Preperation : "Privacy - Camera Usage Description" is needed in info.plist
////MARK:- 1. AVCaptureDevice
////MARK:- 2. AVCaptureDeviceInput
////MARK:- 3. AVCaptureSession
////MARK:- 4. AVCaptureOutput
////MARK:- 5. AVCaptureVideoPreviewLayer
////MARK:- 6. imageView get AVCaptureVideoPreviewLayer
// ----------------------------------------------------------------------

import UIKit
import AVFoundation
import Vision



class ViewController: UIViewController {

    var captureSession = AVCaptureSession()

    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: AppleOrBanana_2().model)

            print("model: ", model)

            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })

            return request
        } catch {
            fatalError("Failde to load Vision ML model: \(error)")
        }
    }()


    lazy var imageView: UIImageView = {
        var imageView = UIImageView()
        imageView.backgroundColor = .orange
        return imageView
    }()

    lazy var uiLabel: UILabel = {
        var uiLabel = UILabel()
        uiLabel.text = "Test"
        // uiLabel.backgroundColor = .blue
        return uiLabel
    }()


    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")

        view.backgroundColor = .cyan
        view.addSubview(imageView)
        view.addSubview(uiLabel)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("viewDidLayoutSubviews")

        imageView.anchor(top: view.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 0, left: 0, bottom: 0, right: 0), size: CGSize(width: view.frame.width, height: view.frame.height * 2 / 3))

        uiLabel.anchor(top: imageView.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 0, left: 0, bottom: 0, right: 0), size: CGSize(width: view.frame.width, height: view.frame.height / 3))
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidAppear")

        captureLiveVideo()
    }


    func captureLiveVideo() {
        print("this is captureLiveVideo function")


        //MARK:- 1. AVCaptureDevice
        print("1. Create a capture device")
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            fatalError("Failed to initialize the camera device")
        }

        //MARK:- 2. AVCaptureDeviceInput
        print("2. Define the device input and output")
        guard let deviceInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            fatalError("Failed to retrieve the device input for camera")
        }

        //MARK:- 4. AVCaptureOutput
        let deviceOutput = AVCaptureVideoDataOutput()
        deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))

        //MARK:- 3. AVCaptureSession
        captureSession.sessionPreset = .photo

        // AVCaptureDeviceInput --> AVCaptureSession
        captureSession.addInput(deviceInput)

        // AVCaptureSession --> AVCaptureDeviceInput
        captureSession.addOutput(deviceOutput)

        //MARK:- 5. AVCaptureVideoPreviewLayer
        print("3. Add a video layer to the image view")
        let cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill

        print("4. set frame")
        cameraPreviewLayer.frame = imageView.layer.frame

        //MARK:- 6. imageView get AVCaptureVideoPreviewLayer
        imageView.layer.addSublayer(cameraPreviewLayer)

        print("5. before captureSettion startRunning")
        captureSession.startRunning()
    }


    // Update the UI with the results of the classification.
    func processClassifications(for request: VNRequest, error: Error?) {

        DispatchQueue.main.async {
            guard let results = request.results else {
                print("Unable to classify image.")
                return
            }

            // The 'results' will always be 'VNClassificationObservation', as specified by the Core ML model in this project.
            let classifications = results as! [VNClassificationObservation]

            if classifications.isEmpty {
                print("Nothing recognized!")
            } else {
                // Display top classifications ranked by confidence in the UI.
                guard let bestAnswer = classifications.first else { return }
                var predictedResult = bestAnswer.identifier

                if predictedResult == "Others" {
                    predictedResult = "🙅‍♀️"
                }

                // uiLabel.text get predictedResult
                self.uiLabel.text = predictedResult

                // get Top 3 element as Array
                let topClassifications = classifications.prefix(3)
                let descriptions = topClassifications.map { classification in

                    // Formats the classification for display; e.g. "(0.37) cliff, drop, drop-off".
                    return String(format: "  (%.2f) %@", classification.confidence, classification.identifier)
                }
                print("Classification:\n" + descriptions.joined(separator: "\n"))
            }
        }
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("6. captureOutput")

        connection.videoOrientation = .portrait

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("this is pixelBuffer else")
            return
        }

        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

        do {
            try imageRequestHandler.perform([self.classificationRequest])
        } catch {
            print(error)
        }
    }
}
