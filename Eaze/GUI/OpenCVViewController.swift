//
//  OpenCVViewController.swift
//  Eaze
//
//  Created by John Silvester on 11/2/16.
//  Copyright © 2016 Hangar42. All rights reserved.
//

import UIKit
import AVFoundation

class OpenCVViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet var sizeLabel: UILabel!
    @IBOutlet var xYLabel: UILabel!
    // セッション
    var mySession : AVCaptureSession!
    // カメラデバイス
    var myDevice : AVCaptureDevice!
    // 出力先
    var myOutput : AVCaptureVideoDataOutput!
    
    // 顔検出オブジェクト
    let detector = Detector()


    override func viewDidLoad() {
        super.viewDidLoad()
       // OpenCVWrapper.startVideoWithView(imageView)
       
        // Do any additional setup after loading the view.
        
        
        if initCamera() {
            // 撮影開始
            mySession.startRunning()
        }
        
        
    }
    @IBAction func backClicked(sender: AnyObject) {
        
          self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        OpenCVWrapper.cameraStart()
        
        
    }

    @IBAction func clicked(sender: AnyObject) {
        
       
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    
    func initCamera() -> Bool {
        // セッションの作成.
        mySession = AVCaptureSession()
        
        // 解像度の指定.
        mySession.sessionPreset = AVCaptureSessionPresetMedium
        
        
        // デバイス一覧の取得.
        let devices = AVCaptureDevice.devices()
        
        // バックカメラをmyDeviceに格納.
        for device in devices {
            if(device.position == AVCaptureDevicePosition.Back){
                //                if(device.position == AVCaptureDevicePosition.Back){
                myDevice = device as! AVCaptureDevice
            }
        }
        if myDevice == nil {
            return false
        }
        
        // バックカメラからVideoInputを取得.
        var myInput: AVCaptureDeviceInput! = nil
        do {
            myInput = try AVCaptureDeviceInput(device: myDevice) as AVCaptureDeviceInput
        } catch let error {
            print(error)
        }
        
        // セッションに追加.
        if mySession.canAddInput(myInput) {
            mySession.addInput(myInput)
        } else {
            return false
        }
        
        // 出力先を設定
        myOutput = AVCaptureVideoDataOutput()
        myOutput.videoSettings = [ kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_32BGRA) ]
        
        
        
        // FPSを設定
        do {
            try myDevice.lockForConfiguration()
            
            myDevice.activeVideoMinFrameDuration = CMTimeMake(1, 15)
            myDevice.unlockForConfiguration()
        } catch let error {
            print("lock error: \(error)")
            return false
        }
        
        // デリゲートを設定
        let queue: dispatch_queue_t = dispatch_queue_create("myqueue",  nil)
        myOutput.setSampleBufferDelegate(self, queue: queue)
        
        
        // 遅れてきたフレームは無視する
        myOutput.alwaysDiscardsLateVideoFrames = true
        
        // セッションに追加.
        if mySession.canAddOutput(myOutput) {
            mySession.addOutput(myOutput)
        } else {
            return false
        }
        
        // カメラの向きを合わせる
        for connection in myOutput.connections {
            if let conn = connection as? AVCaptureConnection {
                if conn.supportsVideoOrientation {
                    conn.videoOrientation = AVCaptureVideoOrientation.LandscapeLeft
                }
            }
        }
        
        return true
    }
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!)
    {
        dispatch_sync(dispatch_get_main_queue(), {
            // grabbing image
            let image = CameraUtil.imageFromSampleBuffer(sampleBuffer)
            
            // flipping image
            let flippedImage = UIImage(CGImage: image.CGImage!, scale: image.scale, orientation: .Right)
            // checking for faces
            let faceImage = self.detector.recognizeFace(flippedImage)
            //reflipping images up
            let flippedImage2 = UIImage(CGImage: faceImage.CGImage!, scale: faceImage.scale, orientation: .Left)
            
          
            //grabing rect
            let centerRect = self.detector.grabImage();
            
            xYLabel.text = NSString(format: "X: %f    Y: %f",centerRect.origin.x,centerRect.origin.y) as String
            
             sizeLabel.text = NSString(format: "Size: %f ",centerRect.size.width) as String
            
            self.imageView.image = flippedImage2
        })
    }
    
}
