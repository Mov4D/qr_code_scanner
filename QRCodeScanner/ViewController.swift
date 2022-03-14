//
//  ViewController.swift
//  QRCodeScanner
//
//  Created by Vadim Aleshin on 14.03.2022.
//

import UIKit
import AVFoundation

final class ViewController: UIViewController {
    
    private var video = AVCaptureVideoPreviewLayer()
    private let session = AVCaptureSession()
    private let alert = UIAlertController(title: "QR Code",
                                          message: nil,
                                          preferredStyle: .actionSheet)
    private let backgroundViewQr: UIView = makeBackgroundViewQr()
    
    @IBOutlet private weak var qrAlertButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(backgroundViewQr)
        
        qrAlertButton.layer.cornerRadius = qrAlertButton.frame.height / 5
        qrAlertButton.addTarget(self, action: #selector(showAlert), for: .touchUpInside)
        
        alert.addAction(UIAlertAction(title: "Перейти",
                                      style: .default,
                                      handler: { (action) in
            
            guard let url = URL(string: self.alert.message ?? "") else { return }
            UIApplication.shared.openURL(url)
        }))
        
        setupVideo()
        startRunning()
    }
    
    @objc private func showAlert(_ sender: UIAlertController) {
        self.present(alert, animated: true, completion: nil)
    }
    
    func setupVideo() {
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            session.addInput(input)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        
        video = AVCaptureVideoPreviewLayer(session: session)
        video.frame = view.frame
        video.fillMode = .both
    }
    
    func startRunning() {
        view.layer.insertSublayer(video, at: 0)
        session.startRunning()
    }
    
}

extension ViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        
        guard metadataObjects.count > 0 else { return }
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let qrBounds = video.transformedMetadataObject(for: object)?.bounds
        else { return }
        
        backgroundViewQr.frame = CGRect(x: qrBounds.minX - 7.5,
                                        y: qrBounds.minY - 7.5,
                                        width: qrBounds.width + 15,
                                        height: qrBounds.height + 15)
        
        if object.type == AVMetadataObject.ObjectType.qr {
            self.alert.message = object.stringValue
        }
    }
}

// MARK: - Factory

extension ViewController {
    private static func makeBackgroundViewQr() -> UIView {
        let view = UIView()
        view.layer.opacity = 0.9
        view.layer.borderColor = UIColor.systemOrange.cgColor
        view.layer.borderWidth = 3
        view.layer.cornerRadius = 10
        return view
    }
}
