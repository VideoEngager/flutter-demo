import UIKit
import Flutter
import AVKit
import SmartVideoSDK

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    private let VE_CHANNEL_ID = "videoengager.smartvideo.channel"
    
    var veChannel: FlutterMethodChannel? = nil
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let rootViewController : FlutterViewController = window?.rootViewController as! FlutterViewController
        self.veChannel = FlutterMethodChannel(name: VE_CHANNEL_ID,
                                              binaryMessenger: rootViewController as! FlutterBinaryMessenger)
        
        
        SmartVideo.delegate = self
        
        self.veChannel?.setMethodCallHandler({ [weak self](call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            
            
            
            let customerName = (call.arguments as? String) ?? ""
            switch call.method {
            case "ClickToVideo":
                
                let memberInfo = ["displayName": customerName] as [String : Any]
                let engine = GenesysEngine(environment: .live, configurations: self?.config(), memberInfo: memberInfo)
                SmartVideo.connect(engine: engine, isVideo: true, lang: "en_US")
                
            default:
                // 4
                result(FlutterMethodNotImplemented)
            }
        })
        
        if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
            AVCaptureDevice.requestAccess(for: .video) { _ in
                    
            }
        }
        
        if AVCaptureDevice.authorizationStatus(for: .audio) != .authorized {
            AVCaptureDevice.requestAccess(for: .audio) { _ in
            }
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func config() -> GenesysConfigurations {
        return GenesysConfigurations(environment: .live,
                                     organizationID: "c4b553c3-ee42-4846-aeb1-f0da3d85058e",
                                     deploymentID: "973f8326-c601-40c6-82ce-b87e6dafef1c",
                                     tenantId: "0FphTk091nt7G1W7",
                                     environmentURL: "https://api.mypurecloud.com",
                                     queue: "Support",
                                     engineUrl: "videome.videoengager.com")
    }
}

extension AppDelegate: SmartVideoDelegate {
    func failedEstablishCommunicationChannel(type: SmartVideoSDK.SmartVideoCommunicationChannelType) {
        
    }

    func callStatusChanged(status: SmartVideoSDK.SmartVideoCallStatus) {
        
    }

    func didEstablishCommunicationChannel(type: SmartVideoCommunicationChannelType) {
        
        let outgoingCallVC = OutgoingCallVC()
        outgoingCallVC.modalPresentationStyle = .fullScreen
        if let vc = window?.rootViewController as? FlutterViewController {
            vc.present(outgoingCallVC, animated: true, completion: nil)
        }
    }
    
    func errorHandler(error: SmartVideoError) {
        debug("SmartVideo Communication error. Error is: \(error.error)", level: .error, type: .genesys)
        DispatchQueue.main.async {
            SmartVideo.callManager.hangupAndEnd()
            
            let alert = UIAlertController(title: "Error", message: error.error, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.window?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
}
