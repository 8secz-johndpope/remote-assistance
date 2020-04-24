//
//  OCRScanner.swift
//  RemoteAssistance
//
//  Created by Scott Carter on 1/8/20.
//  Copyright © 2020 FXPAL. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

protocol OCRDelegate: class
{
    func ocrResponse(text: String)
}

class OCRScanner: UIViewController {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!

    let options : [String]
    var foundMatch = false
    let levDistance = 2
    
    init(options: [String]) {
        self.options = options
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    weak var delegate: OCRDelegate?
    private var requests = [VNRequest]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupVision()
        
        self.title = "OCR Scanner"

        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let videoOutput = AVCaptureVideoDataOutput()

        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "buffer queue", qos: .userInteractive, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil))
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        captureSession.startRunning()
    }

    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)

        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    func setupVision() {
        let textRequest = VNDetectTextRectanglesRequest(completionHandler: self.textDetectionHandler)
        textRequest.reportCharacterBoxes = true

        if #available(iOS 13.0, *) {
            let recognizeTextRequest = VNRecognizeTextRequest(completionHandler: self.textDetectionHandler)
            //recognizeTextRequest.customWords = ["AltaLink", "ApeosPort-VII C7773" ]
            self.requests = [textRequest, recognizeTextRequest]
        } else {
            // Fallback on earlier versions
            self.requests = [textRequest]
        }
    }
    
    func textDetectionHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results else {print("no result"); return}
        
        if #available(iOS 13.0, *) {
            for o in observations {
                if let result = o as? VNRecognizedTextObservation {
                    let rObsOrig = result.topCandidates(1)[0].string
                    let rObs = rObsOrig.replacingOccurrences(of: "\\s",with:"",options:.regularExpression).lowercased()
                    
                    for string in options {
                        let rString = string.replacingOccurrences(of: "\\s",with:"",options:.regularExpression).lowercased()
                        let lev = rString.levenshtein(rObs)
                        print(rObs,rString,lev)
                        if ((lev <= levDistance) && !foundMatch) {
                            foundMatch = true
                            DispatchQueue.main.async {
                                self.captureSession.stopRunning()
                                self.navigationController?.popViewController(animated:true)
                                self.delegate?.ocrResponse(text: string)
                            }
                        }
                    }
                }
            }
        }
    }
}

extension OCRScanner: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        
        var requestOptions:[VNImageOption : Any] = [:]
        
        if let camData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            requestOptions = [.cameraIntrinsics:camData]
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: 6)!, options: requestOptions)
        
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
}

//
extension String {
    subscript(index: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: index)]
    }
}

extension String {
    public func levenshtein(_ other: String) -> Int {
        let sCount = self.count
        let oCount = other.count

        guard sCount != 0 else {
            return oCount
        }

        guard oCount != 0 else {
            return sCount
        }

        let line : [Int]  = Array(repeating: 0, count: oCount + 1)
        var mat : [[Int]] = Array(repeating: line, count: sCount + 1)

        for i in 0...sCount {
            mat[i][0] = i
        }

        for j in 0...oCount {
            mat[0][j] = j
        }

        for j in 1...oCount {
            for i in 1...sCount {
                if self[i - 1] == other[j - 1] {
                    mat[i][j] = mat[i - 1][j - 1]       // no operation
                }
                else {
                    let del = mat[i - 1][j] + 1         // deletion
                    let ins = mat[i][j - 1] + 1         // insertion
                    let sub = mat[i - 1][j - 1] + 1     // substitution
                    mat[i][j] = min(min(del, ins), sub)
                }
            }
        }

        return mat[sCount][oCount]
    }
}
