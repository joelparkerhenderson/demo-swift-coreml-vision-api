import UIKit
import AVFoundation // Provide AVCaptureDevice, AVCaptureVideoDataOutput, etc.
import Vision //

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
        view.addSubview(modelPredictionLabel)
        setupModelPredictionLabel()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    let modelPredictionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Label"
        label.font = label.font.withSize(30)
        return label
    }()
    
    func setupModelPredictionLabel() {
        modelPredictionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        modelPredictionLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
    }
    
    func setupCaptureSession() {

        // Get a reference to the rear view camera.
        // Use a DiscoverySession to query available
        // capture devices based on search criteria.
        let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices
        
        // The AVCaptureSession object handles capture activity and manages
        // the flow of data between input devices (such as the camera) and outputs.
        let captureSession = AVCaptureSession()
    
        // get capture device, add device input to capture session
        do {
            // The first available device will be the rear facing camera.
            if let captureDevice = availableDevices.first {
                // Ceate a new AVCaptureDeviceInput using our capture device,
                // and add it to the capture session.
                captureSession.addInput(try AVCaptureDeviceInput(device: captureDevice))
            }
        } catch {
            print(error.localizedDescription)
        }
        
        // setup output, add output to our capture session
        
        // AVCaptureVideoDataOutput is an output that captures video.
        // It also provides access to the frames being captured for
        // processing with a delegate method we will see later.
        let captureOutput = AVCaptureVideoDataOutput()
        captureSession.addOutput(captureOutput)

        // Add capture session output as a sublayer to the view controllers’ view.
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.frame
        view.layer.addSublayer(previewLayer)

        // Starts the flow from inputs to outputs.
        captureSession.startRunning()
        
        // To analyze what the camera is seeing, we need access
        // to the frames being captured by the camera.
        //
        // Conforming to the AVCaptureVideoDataOutputSampleBufferDelegate
        // gives an interface for interation, and gives a notification
        // every time a frame is captured by the camera.
        //
        // Each time a frame is captured, the delegate is notified by
        // calling captureOutput() which does image analysis with CoreML.
        captureOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
 
        // Create a VNCoreMLModel which is essentially a
        // CoreML model used with the vision framework.
        // We create it with a Resnet50 Model.
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else { return }

        // Create our vision request. In the completion handler,
        // we update the onscreen UILabel with the identifier
        // returned by the model.
        let request = VNCoreMLRequest(model: model) { (finishedRequest, error) in
            guard let results = finishedRequest.results as? [VNClassificationObservation] else { return }
            guard let Observation = results.first else { return }
            DispatchQueue.main.async(execute: {
                self.modelPredictionLabel.text = "\(Observation.identifier)"
            })
        }
        
        // Convert the frame from a CMSampleBuffer to a CVPixelBuffer,
        // which is the format that our model needs for analysis.
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Executes the Vision request with a VNImageRequestHandler
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }

}

