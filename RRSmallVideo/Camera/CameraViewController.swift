//
//  CameraViewController.swift
//  RRSmallVideo
//
//  Created by Ron on 2017/3/15.
//  Copyright © 2017年 Ron. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class CameraViewController: UIViewController, UIImagePickerControllerDelegate, AVCaptureFileOutputRecordingDelegate {

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var tempImageView: UIImageView!
    @IBOutlet weak var takePhotoButton: UIButton!
    @IBOutlet weak var quiteButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var sureButton: UIButton!
    
    var captureSession: AVCaptureSession?           // 负责输入和输出设置之间的数据传递
    var videoInput: AVCaptureDeviceInput?           // 负责从AVCaptureDevice获得输入数据
    var imageOutput: AVCaptureStillImageOutput?     // 照片输出
    var movieOutput: AVCaptureMovieFileOutput?      // 视频输出
    var previewlayer: AVCaptureVideoPreviewLayer?   // 拍摄预览层
    
    var movieSaveURL: URL?
    var moviePalyer: AVPlayerLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        takePhotoButton.layer.cornerRadius = 30
        takePhotoButton.layer.masksToBounds = true
        cancelButton.layer.cornerRadius = 30
        cancelButton.layer.masksToBounds = true
        sureButton.layer.cornerRadius = 30
        sureButton.layer.masksToBounds = true
        
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = AVCaptureSessionPreset1280x720 // 设置分辨率
        
        // 获得相机设备
        let videoDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        if videoDevice == nil {
            print("摄像头错误")
        }
        
        var error: NSError?
        
        do {
            videoInput = try AVCaptureDeviceInput.init(device: videoDevice)
        } catch let avError as NSError {
            error = avError
            videoInput = nil
        }
        
        // 获取音频输入
        
        let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
        if audioDevice == nil {
            print("音频错误")
        }
        var audioInput: AVCaptureDeviceInput?
        do {
            audioInput = try AVCaptureDeviceInput.init(device: audioDevice)
        } catch let avError as NSError {
            error = avError
            audioInput = nil
        }
        
        if (error == nil && captureSession?.canAddInput(videoInput) != nil) {
            captureSession?.addInput(videoInput)
            
            captureSession?.addInput(audioInput)
            
            imageOutput = AVCaptureStillImageOutput()
            imageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            
            movieOutput = AVCaptureMovieFileOutput()
            
            if captureSession?.canAddOutput(imageOutput) != nil {
                captureSession?.addOutput(imageOutput)
                captureSession?.addOutput(movieOutput)
                
                previewlayer = AVCaptureVideoPreviewLayer.init(session: captureSession)
                previewlayer?.frame = cameraView.bounds
                previewlayer?.videoGravity = AVLayerVideoGravityResizeAspect
                previewlayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait
                
                cameraView.layer.addSublayer(previewlayer!)
                
                captureSession?.startRunning()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func didPressTakePhoto() {
        if let videoConnection = imageOutput?.connection(withMediaType: AVMediaTypeVideo) {
            videoConnection.videoOrientation = AVCaptureVideoOrientation.portrait
            imageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (sampleBuffer, error) in
                if sampleBuffer != nil {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    let dataProvider = CGDataProvider.init(data: imageData as! CFData)
                    let cgImageRef = CGImage.init(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
                    let image = UIImage.init(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.right)
                    
                    self.tempImageView.image = image
                    self.tempImageView.isHidden = false
                }
            })
        }
    }
    
    func didStartRecord() {
        if (movieOutput?.isRecording)! {
            movieOutput?.stopRecording()
            
            return;
        }
        
        if let videoConnection = movieOutput?.connection(withMediaType: AVMediaTypeVideo) {
            if videoConnection.isVideoStabilizationSupported {
                videoConnection.preferredVideoStabilizationMode = .auto
            }
        }
        let filePath: String = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first!
        movieSaveURL = URL.init(fileURLWithPath: filePath + "/movie.mov")
        
        movieOutput?.startRecording(toOutputFileURL: movieSaveURL, recordingDelegate: self)
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        movieSaveURL = outputFileURL
        takePhotoFinish(true)
        let avPlayer = AVPlayer.init(url: outputFileURL)
        moviePalyer = AVPlayerLayer.init(player: avPlayer)
        moviePalyer?.frame = cameraView.bounds
        moviePalyer?.videoGravity = AVLayerVideoGravityResizeAspect
        previewlayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait
        cameraView.layer.addSublayer(moviePalyer!)
        avPlayer.play()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //set force
        
    }
    
    @IBOutlet weak var cancelButtonCenter: NSLayoutConstraint!
    @IBOutlet weak var sureButtonCenter: NSLayoutConstraint!
    
    func takePhotoFinish(_ show: Bool) {
        if show {
            self.cancelButton.isHidden = false
            self.sureButton.isHidden = false
            self.takePhotoButton.isHidden = true
            self.quiteButton.isHidden = true

            UIView.animate(withDuration: 0.5, animations: {
                self.cancelButtonCenter.constant -= 100
                self.sureButtonCenter.constant += 100
                self.view.layoutIfNeeded()
            }) { (finish) in
                
            }
        } else {
            self.cancelButton.isHidden = true
            self.sureButton.isHidden = true
            
            self.cancelButtonCenter.constant = 0
            self.sureButtonCenter.constant = 0
            
            self.takePhotoButton.isHidden = false
            self.quiteButton.isHidden = false
        }
    }
    
    
    /// take photo button - TouchUpInside
    @IBAction func onClickTakePhotoButton(_ sender: Any) {
        if isRecording {
            captureSession?.stopRunning()
        } else {
            didPressTakePhoto()
            takePhotoFinish(true)
        }
    }
    
    /// save the photo
    @IBAction func onClickSureButton(_ sender: Any) {
        if isRecording {
            albumSaveVideo(movieSaveURL!)
        } else {
          albumSavePhoto(tempImageView.image!)
        }
    }
    
    /// give up current photo
    @IBAction func onClickCancelButton(_ sender: Any) {
        if isRecording {
            do {
                try FileManager.default.removeItem(at: movieSaveURL!)
            } catch let error as NSError {
                print(error)
            }
        }
        readyForTakeNewPhoto()
    }
    
    /// dismiss button
    @IBAction func onClickQuitButton(_ sender: Any) {
        self.dismiss(animated: true) { 
            
        }
    }
    
    func readyForTakeNewPhoto() {
        if isRecording {
           isRecording = false
            moviePalyer?.removeFromSuperlayer()
            moviePalyer = nil
        }
        takePhotoFinish(false)
        
        tempImageView.isHidden = true
        tempImageView.image = nil
        
        captureSession?.startRunning()
    }
    
    deinit {
        print("[TEST] - CameraViewController Release")
    }
    
    // MARK: - Private
    func albumSavePhoto(_ photo: UIImage) {
        PHPhotoLibrary.shared().performChanges({ 
            PHAssetChangeRequest.creationRequestForAsset(from: photo)
        }) { (success, error) in
            print("success : \(success), error : \(error)")
            
            DispatchQueue.main.async {
                self.readyForTakeNewPhoto()
            }
        }
    }
    
    func albumSaveVideo(_ videoURL: URL) {
        PHPhotoLibrary.shared().performChanges({ 
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
        }) { (success, error) in
            print("success : \(success), error : \(error)")
            
            do {
                try FileManager.default.removeItem(at: videoURL)
            } catch let error as NSError {
                print(error)
            }
            
            DispatchQueue.main.async {
                self.readyForTakeNewPhoto()
            }
        }
        
    }
    
    // MARK - Movie
    let maxMovieDuration = 10
    
    var isRecording = Bool()
    
    /// Long press for record video
    @IBAction func onLongPressCameraButton(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            print("began")
            if !isRecording {
                isRecording = true
                didStartRecord()
            }
        case .ended:
            print("ended")
            if isRecording {
                captureSession?.stopRunning()
            }
        default: break
        }
    }
}
