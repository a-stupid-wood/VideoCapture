//
//  ViewController.swift
//  VideoCapture
//
//  Created by 王凯彬 on 2017/11/5.
//  Copyright © 2017年 WKB. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    fileprivate lazy var videoQueue = DispatchQueue.global()
    fileprivate lazy var audioQueue = DispatchQueue.global()
    
    fileprivate lazy var session : AVCaptureSession = AVCaptureSession()
    fileprivate lazy var previewLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
    
    fileprivate var videoOutput : AVCaptureVideoDataOutput?
    fileprivate var videoInput : AVCaptureDeviceInput?
    fileprivate var movieOutput : AVCaptureMovieFileOutput?
}

//MARK:- 视频的开始采集&停止采集
extension ViewController {
    @IBAction func startCapture() {
        //1.设置视频的输入&输出
        setupVideo()
        
        //2.设置音频的输入&输出
        setupAudio()
        
        //3.添加写入文件的output
        let movieOutput = AVCaptureMovieFileOutput()
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        }
        self.movieOutput = movieOutput
        
        //设置写入的稳定性
        let connection = movieOutput.connection(with: .video)
        connection?.preferredVideoStabilizationMode = .auto
        
        
        //4.给用户一个预览图层(可选)
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        
        //5.开始采集
        session.startRunning()
        
        //6.开始讲采集到的画面写入到文件中
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/abc.mp4"
        let url = URL(fileURLWithPath: path)
        movieOutput.startRecording(to: url, recordingDelegate: self)
    }
    
    @IBAction func stopCapture() {
        
        movieOutput?.stopRecording()
        
        session.stopRunning()
        previewLayer.removeFromSuperlayer()
    }
    
    @IBAction func switchScene() {
        //1.获取当前的镜头
        guard var position = videoInput?.device.position else { return }
        
        //2.获取当前应该显示的镜头
        position = position == .front ? .back : .front
        
        //3.根据当前镜头创建新的device
        let devices = AVCaptureDevice.devices(for: .video)
        guard let device = devices.filter({$0.position == position}).first else { return }
        
        //4.根据新的device创建新的device
        guard let videoInput = try? AVCaptureDeviceInput(device: device) else { return }
        
        //5.在session中切换Input
        session.beginConfiguration()
        session.removeInput(self.videoInput!)
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        session.commitConfiguration()
        self.videoInput = videoInput
        
        
    }
}

extension ViewController {
    fileprivate func setupVideo() {
        //1.给捕捉会话设置输入源(摄像头)
        //1.1.获取摄像头设备
        let devices = AVCaptureDevice.devices(for: .video)
        guard let device = devices.filter({$0.position == .front}).first else { return }
        
        //1.2.通过device创建AVCaptureInput对象
        guard let videoInput = try? AVCaptureDeviceInput(device: device) else { return }
        self.videoInput = videoInput
        
        //1.3.将input添加到会话中
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        
        //2.给捕捉会话设置输出源
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        //3.获取video对应的videoOutput
        self.videoOutput = videoOutput
    }
    
    fileprivate func setupAudio() {
        //1.设置音频的输入(话筒)
        //1.1.获取话筒设备
        guard let device = AVCaptureDevice.default(for: .audio) else { return }
        
        //1.2.根据device创建AVCaptureInput
        guard let audioInput = try? AVCaptureDeviceInput(device: device) else { return }
        
        //1.3.将input添加到会话中
        if session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }
        
        //2.给会话设置音频输出源
        let audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: audioQueue)
        if session.canAddOutput(audioOutput) {
            session.addOutput(audioOutput)
        }
    }
}

//MARK:- 遵守AVCaptureVideoDataOutputSampleBufferDelegate协议 获取数据
extension ViewController : AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if connection == self.videoOutput?.connection(with: .video) {
            print("已经采集到视频数据")
        }else {
            print("已经采集到音频数据")
        }
    }
}

extension ViewController : AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("开始写入")
    }
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("结束写入")
    }
    
    
}
