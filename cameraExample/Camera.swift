//
//  Camera.swift
//  cameraExample
//
//  Created by MacBook on 07/07/2025.
//

import SwiftUI
import AVFoundation
import Combine

struct CameraView: UIViewControllerRepresentable {
    
    var takePhotoTrigger: PassthroughSubject<Void, Never>

    func makeUIViewController(context: Context) -> CameraViewController {
            let controller = CameraViewController()
            
            // Subskrypcja wyzwalacza zdjęcia
            context.coordinator.controller = controller
            context.coordinator.subscribe(to: takePhotoTrigger)

            return controller
        }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
            // Nic nie robimy, bo kamera się nie zmienia
        }

       func makeCoordinator() -> Coordinator {
           Coordinator()
       }

       class Coordinator {
           var controller: CameraViewController?

           private var cancellable: AnyCancellable?

           func subscribe(to trigger: PassthroughSubject<Void, Never>) {
               cancellable = trigger.sink { [weak self] in
                   self?.controller?.capturePhoto()
               }
           }
       }
   }
class CameraViewController: UIViewController {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var photoOutput: AVCapturePhotoOutput?

    override func viewDidLoad() {
        super.viewDidLoad()
        checkCameraPermission { [weak self] granted in
            if granted {
                DispatchQueue.main.async {
                    self?.setupCamera()
                }
            }
        }
    }

    func setupCamera() {
        captureSession = AVCaptureSession()
        
        // UI Setup (Preview)
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = self.view.bounds
        self.view.layer.insertSublayer(previewLayer, at: 0)
        self.previewLayer = previewLayer

        // Konfiguracja sprzętu na tle
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, let session = self.captureSession else { return }

            session.beginConfiguration()

            // SZUKAMY TYLKO PRZEDNIEJ KAMERY
            let deviceDiscovery = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera],
                mediaType: .video,
                position: .front
            )

            guard let selfieCamera = deviceDiscovery.devices.first,
                  let input = try? AVCaptureDeviceInput(device: selfieCamera),
                  session.canAddInput(input) else {
                print("❌ Selfie camera not found")
                return
            }

            session.addInput(input)

            let output = AVCapturePhotoOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                self.photoOutput = output
            }

            session.commitConfiguration()
            session.startRunning()
        }
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        // W trybie selfie warto dodać automatyczne lustrzane odbicie, aby zdjęcie wyglądało tak jak na podglądzie
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    // Helper do uprawnień pozostał bez zmian
    func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: completion(true)
        case .notDetermined: AVCaptureDevice.requestAccess(for: .video) { completion($0) }
        default: completion(false)
        }
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), var image = UIImage(data: data) else { return }
        
        // Opcjonalnie: odbicie lustrzane, aby zdjęcie było identyczne z tym co widzisz na ekranie
        if let cgImage = image.cgImage {
            image = UIImage(cgImage: cgImage, scale: image.scale, orientation: .leftMirrored)
        }

        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        print("✅ Selfie zapisane!")
    }
}
