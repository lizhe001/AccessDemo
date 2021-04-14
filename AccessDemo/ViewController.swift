//
//  ViewController.swift
//  AccessDemo
//
//  Created by 李哲 on 2021/1/13.
//

import UIKit
import CoreBluetooth
import AVFoundation
import Photos

enum AccessDemoType : Int{
    case microphone = 0
    case camera
    case bluetooth
    case interNet
    case location
    case nfc
    case photosUsage
    case photosAddtion
    case faceId
    case notification

    case none
}

let cellIdentifier = "NormalCell"
class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    //MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.textLabel?.text = self.dataArr[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch AccessDemoType(rawValue: indexPath.row) {
        case .microphone:
            isPrepareOfAVCaptureAudioDevice { (status) in
                print(status)
            }
        case .camera:
            isPrepareOfAVCaptureVideoDevice { (status) in
                print(status)
            }
        case .bluetooth:
            self.bleAccess()
        case .interNet:
            self.ping()
        case .location:
            self.checkLocationStatus()
        case .photosUsage:
            self.checkPhotosLibraryUsageStatus()
        case .photosAddtion:
            self.checkPhotosLibraryAddtionStatus()
        case .faceId:
            self.requetAuthor()
        case .nfc:
            if self.checkNFCReaderAvailable(){
                //YES
                print("NFCReader is available")
            }else{
                //NO
                print("NFCReader is not available")
            }
        case .notification:
            self.checkNotificationAvailable()
        default:
            break
        }
    }
    

    var tableView : UITableView!
    var dataArr = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.title = "AccessDemo"
        self.view.backgroundColor = .white
        
        self.dataArr = ["Microphone","Camera","Bluetooth","InterNet","Location","NFC","PhotosUsage","PhotosAddOnly","FaceID","Notification"]
        
        self.tableView = UITableView(frame: self.view.bounds)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.tableFooterView = UIView()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        self.view.addSubview(self.tableView)
    
    }
    
    func ping(){
        var request = URLRequest(url: URL(string: "http://www.baidu.com")!)
        request.timeoutInterval = 10
        request.allowsCellularAccess = true
        let session = URLSession.shared
        let task = URLSession.shared.dataTask(with: request) { (data, respone, error) in
            if error != nil{
                print("false")
            }else{
                print(data)
            }
        }
        task.resume()
    }
    
    func bleAccess(){
        //蓝牙
        cbManager = CBCentralManager(delegate: self, queue: nil)
        cbManager.isScanning
        if #available(iOS 13.0, *) {
            switch cbManager.authorization{
            case .restricted:
                print("设备蓝牙有问题，被限制使用")
            case .denied:
                print("被用户拒绝了")
            case .notDetermined:
                print("用户无权使用蓝牙，可能是系统设置原因")
            case .allowedAlways:
                print("用户已授权")
            default:
                print("啥也不是~~~~~")
            }
        }
    }
}


//MARK: 蓝牙
var cbManager : CBCentralManager!
extension ViewController:CBCentralManagerDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .resetting:
            print("服务连接中断，正在重连")
        case .unsupported:
            print("设备不支持")
        case .unauthorized:
            if #available(iOS 13.0, *) {
                switch central.authorization {
                case .restricted:
                    print("设备蓝牙有问题，被限制使用")
                case .denied:
                    print("被用户拒绝了")
                default:
                    print("啥也不是~~~~~")
                }
            } else {
                print("用户未授权")
            }
        case .poweredOff:
            print("蓝牙未打开")
        case .poweredOn:
            print("蓝牙已打开")
            
        default:
            print("啥也不是~~~~~")
        }
    }
}

//MARK: 麦克风及相机
extension ViewController{
    
    private func isPrepareOfAVCaptureAudioDevice(_ completionHandler: @escaping (Bool) -> Void) {
        let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if audioStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) {
                completionHandler($0)
            }
            return
        }
        completionHandler(audioStatus == .authorized)
    }
    
    private func isPrepareOfAVCaptureVideoDevice(_ completionHandler: @escaping (Bool) -> Void) {
        let videoStatus = AVCaptureDevice.authorizationStatus(for: .video)

        if videoStatus == .notDetermined{
            AVCaptureDevice.requestAccess(for: .video) {
                completionHandler($0)
            }
            return
        }
        completionHandler(videoStatus == .authorized)
    }
}

//MARK: 图库相关
extension ViewController{
    
    func checkPhotosLibraryUsageStatus(){
        if #available(iOS 14, *) {
            let readWriteStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            print(readWriteStatus)
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { (status) in
                self.handleRequestStatus(status: status)
            }
        } else {
            let readWriteStatus = PHPhotoLibrary.authorizationStatus()
            print(readWriteStatus)
            PHPhotoLibrary.requestAuthorization { (status) in
                self.handleRequestStatus(status: status)
            }
        }
    }
    
    func checkPhotosLibraryAddtionStatus(){
        if #available(iOS 14, *) {
            let readWriteStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            print(readWriteStatus)
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { [self] (status) in
                handleRequestStatus(status: status)
            }
        } else {
            let readWriteStatus = PHPhotoLibrary.authorizationStatus()
            print(readWriteStatus)
            PHPhotoLibrary.requestAuthorization { (status) in
                self.handleRequestStatus(status: status)
            }
        }
    }
    
    func handleRequestStatus(status:PHAuthorizationStatus){
        switch status {
        case .notDetermined:
            print("The user hasn't determined this app's access.")
        case .restricted:
            print("The system restricted this app's access.")
        case .denied:
            print("The user explicitly denied this app's access.")
        case .authorized:
            print("The user authorized this app to access Photos data.")
        case .limited:
            print("The user authorized this app for limited Photos access.")
        @unknown default:
            fatalError()
        }
    }
}

//MARK: 定位相关
import CoreLocation
extension ViewController{
    func checkLocationStatus(){
        let locationManager = CLLocationManager()
        if #available(iOS 14.0, *) {
            let status = locationManager.authorizationStatus
            self.requestLocationAuthor(status: status)
        } else {
            let status = CLLocationManager.authorizationStatus()
            self.requestLocationAuthor(status: status)
        }
    }
    
    func requestLocationAuthor(status:CLAuthorizationStatus){
        let locationManager = CLLocationManager()

        switch status {
        case .authorizedAlways:
            print("The user authorized this app is authorizedAlways.")
        case .authorizedWhenInUse:
            print("The user authorized this app is authorizedWhenInUse.")
        case .denied:
            print("The user authorized this app is denied.")
        case .notDetermined://根据需求二选一
//            locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
            
        case .restricted:
            print("The user authorized this app is restricted.")

        default:
            fatalError()
        }
    }
}


//MARK: FaceId TouchId 本地认证相关
import LocalAuthentication
var context = LAContext()
extension ViewController{

    func requetAuthor(){
        /*
        请求设备本地解锁认证（密码，faceID，TouchID），LAPolicy有两种枚举类型，deviceOwnerAuthenticationWithBiometrics仅调用设备设置的touchid或faceID进行认证，deviceOwnerAuthentication会根据设备设置的解锁方式进行请求，默认是设备密码认证，即使在没有设置生物学识别信息(指纹、面部特征)的情况下也可以使用
         canEvaluatePolicy()方法用来检查认证方式是否可用，也可用来标记状态
         evaluatePolicy()方法用来进行认证方法调用
        */
            context = LAContext()
            context.localizedCancelTitle = "设置title"

            var error: NSError?
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                let reason = "设置具体描述"
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason ) { success, error in
                    if success {
                        DispatchQueue.main.async { [unowned self] in
                           print("认证成功")
                        }
                    } else {
                        print(error?.localizedDescription ?? "认证失败")
                    }
                }
            } else {
                print(error?.localizedDescription ?? "无法调用系统认证方式")
            }
        }
}

//MARK: NFC相关
import CoreNFC
extension ViewController{
    func checkNFCReaderAvailable() -> Bool{
       return NFCNDEFReaderSession.readingAvailable
    }
}

//MARK: 通知相关
import CoreNFC
extension ViewController{
    
    func requestNotificationAuthorize(){
        if #available(iOS 10, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [UNAuthorizationOptions.alert,UNAuthorizationOptions.badge,.sound]) { (isAuthor, error) in
                if error == nil{
                    print(isAuthor)
                }
            }
        }else{
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func checkNotificationAvailable(){
        if #available(iOS 10, *) {
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                print(settings.authorizationStatus)
                switch settings.authorizationStatus{
                case .authorized:
                    print("已授权")
                case .denied:
                    print("用户拒绝消息通知")
                case .notDetermined:
                    print("未确定消息权限")
                //这两个是新的，没有做深入探究
                case .ephemeral:
                    print("ephemeral")
                case .provisional:
                    print("provisional")

                default:
                    break
                }
            }
        }else{
            let isRegistered = UIApplication.shared.isRegisteredForRemoteNotifications
            print(isRegistered)
        }
    }
}

