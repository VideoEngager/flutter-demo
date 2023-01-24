# flutter-demo
Demonstrates usage of Kotlin and Swift SDK's with Flutter

This project is created from initial Flutter Guide shown here
https://docs.flutter.dev/development/platform-integration/platform-channels?tab=type-mappings-kotlin-tab


## Flutter implementation

1. Open with editor your `main.dart` file and add folowing imports:
```dart
import 'package:flutter/services.dart';
```

2. Declare VideoEngager channel in your Page class as shown, this channel is used for comunication between native code and flutter :
```dart
//declare VideoEngager method channel
static const platform = MethodChannel('videoengager.smartvideo.channel');
```

3. To receive events from VideoEngager SDK you can register for it with following handler function :
```dart
    //declare event handler and add Videoengager events
    Future<void> veHandler(MethodCall call) async {
        final String args = call.arguments;
        log(args);

        switch (call.method) {

        case "Ve_onError": // this method name needs to be the same from invokeMethod in Android/IOS
            log("Error received: "+args);
            break;

        case "Ve_onChatMessage": // this method name needs to be the same from invokeMethod in Android/IOS
            showDialog(context: context, builder:(BuildContext context) {
            return AlertDialog(
                title: const Text("Chat message"),
                content: Text(args),
                actions: <Widget>[
                    TextButton(
                    style: TextButton.styleFrom(
                        textStyle: Theme.of(context).textTheme.labelLarge,
                    ),
                    child: const Text('   OK   '),
                    onPressed: () { Navigator.of(context).pop();},
                    )
            ]
            );
            });
            break;

        default:
            log('no method handler for method ${call.method}');
        }
    }
```
In this example we are registering for 2 events (`Ve_onError` and `Ve_onChatMessage`) ... if you need more events you must add implementation in android activity and register for it by adding event names as case block.

 4. In `initState` ovveride method register our method handler as shown :

 ```dart
 @override
  void initState() {
    platform.setMethodCallHandler(veHandler);
    super.initState();
  }
 ```

5. Simple Video Call can be started with `ClickToVideo(CallerName:String)` method provided from platform native code and called with `platform` MethodChannel  executed from `main.dart` as shown :
```dart
....
    void clickToVideo(){
        platform.invokeMethod('ClickToVideo',nameBoxController.text);
    }
    ....
    children: <Widget>[
        ......
        TextButton(
            style: const ButtonStyle(
            backgroundColor:MaterialStatePropertyAll(Colors.blue),
            foregroundColor: MaterialStatePropertyAll(Colors.white),
            padding: MaterialStatePropertyAll(EdgeInsets.all(20))
            ),
            onPressed: clickToVideo,
            child: Text("  ..:: ClickToVideo ::..  "),
        )
        ],
....
```
###  Exposing Custom Fields in Interaction details
To make the custom fields available on the agent side, you will need to call ClickToCal method with aditional params. 
You can add up to 3 exposeable custom fields. Each field has 2 arguments : `customFieldXLabel` and `customFieldX`
For example, if you have a custom field with the name `Customer Id`, you would add the following to the params object:
````
customField1Label = "Customer Id"
customField1 = "123456745342"
````
Flutter side example implementation:
```dart
  void clickToVideoWithCustomFields(){
    final Map<String, String> customFields = {
      "name": nameBoxController.text,
      "customField1Label" : customLabelController.text,
      "customField1": customFieldController.text,
    };
    platform.invokeMethod('ClickToVideoWithCustomFields',jsonEncode(customFields));
    log(nameBoxController.text);
    log(customLabelController.text);
    log(customFieldController.text);
  }
```
Android implementation:
```kotlin
 "ClickToVideoWithCustomFields" -> {
     val customFields = Gson().fromJson<Map<String,String>>(call.arguments.toString(),Map::class.java)
     val customerName = customFields.getOrElse("name") { "Demo Visitor" }
     Toast.makeText(this,"Hello $customerName",Toast.LENGTH_SHORT).show()
     //VideoEngager.SDK_DEBUG = true //use only in development stage
     val settings = getSettings(customerName)
     settings.CustomFields = customFields 
     val smartVideo = VideoEngager(this,settings,VideoEngager.Engine.genesys)
     if(smartVideo.Connect(VideoEngager.CallType.video)){
         smartVideo.onEventListener = listener
     } else{
         channel.invokeMethod("Ve_onError", "Error from connection!")
         smartVideo.Disconnect()
     }
 }
```

## Android implementation

### Example demo App can be downloaded from here :
https://drive.google.com/file/d/1PMhqr9Mu-UO124VinBXjgtn-Dlwj5ggh

Following guide  these are steps for implementing VideoEngager SmartVideo SDK with your Flutter App:

1. Open `android` folder(project) with AndroidStudio IDE.

2. Edit `build.gradle` file and put `jcenter()` repo for `allProjects` sections as shown:
```gradle

allprojects {
    repositories {
        ...
        jcenter()
        ...
        }
}
```
and change `minSdkVersion` to `21` as shown :
```gradle
android {
    .....
    defaultConfig {
       ...
        minSdkVersion 21
       ....
    }
    .....
}
```

3. Edit `app/build.gradle` and add VideoEngager SDK dependencies as shown (please use latest version) :
```gradle
dependencies {
    ....
    implementation 'com.videoengager:smartvideo-sdk:1.15.1'
    ....
    }
```
4. Open `MainActivity.kt` and define channel as shown :
```kotlin
class MainActivity: FlutterActivity() {
   ....
    private val VE_CHANNEL_ID = "videoengager.smartvideo.channel"

    private lateinit var channel : MethodChannel
    .....
}
```

5. Also add implementation logic in `configureFlutterEngine` ovveride method as shown :
```kotlin
override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ......
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VE_CHANNEL_ID)
        channel.setMethodCallHandler {
                call, result ->
            // This method is invoked on the main thread.
            val customerName = call.arguments.toString()
            when(call.method){
                "ClickToVideo" -> {
                    Toast.makeText(this,"Hello $customerName",Toast.LENGTH_SHORT).show()
                    //VideoEngager.SDK_DEBUG = true //use only in development stage
                    val smartVideo = VideoEngager(this,getSettings(customerName),VideoEngager.Engine.genesys)
                    if(smartVideo.Connect(VideoEngager.CallType.video)){
                        smartVideo.onEventListener = listener
                    } else{
                        channel.invokeMethod("Ve_onError", "Error from connection!")
                        smartVideo.Disconnect()
                    }
                }
            }
        }
.....
}
```
You can pass additional parameters (like callerName , etc...) to the SDK by `channel.InvokeMethod()` args parameter

7. We need to declare VideoEngager event `listener` in same class as shown :
```kotlin
....
    //VideoEngager Event listener
    val listener = object : VideoEngager.EventListener(){
        override fun onError(error: Error): Boolean {
            channel.invokeMethod("Ve_onError", Gson().toJson(error))
            return super.onError(error)
        }

        override fun onMessageAndTimeStampReceived(timestamp: String, message: String) {
            channel.invokeMethod("Ve_onChatMessage",message)
        }
    }
...
```
Here we can handle and define our custom event methods to be used in flutter if we need it.

8. Test Build android project from main flutter IDE or terminal.

### Android DeepLink implementation
Implementation of deep link can be done only in native (android) side. You can read more about this here : https://docs.flutter.dev/development/ui/navigation/deep-linking

Example steps for SmartVideo shortUrl Call :
1. Open `./android/app/src/AndroidManifest.xml` and in MainActivity section put following:

```xml
        <intent-filter
            android:autoVerify="true"
            android:label="SmartVideo Call">
            <action android:name="android.intent.action.VIEW" />
            <category android:name="android.intent.category.DEFAULT" />
            <category android:name="android.intent.category.BROWSABLE" />
            <data android:scheme="https" />
            <data android:host="videome.videoengager.com" />
            <data android:host="videome.leadsecure.com" />
            <data android:pathPrefix="/ve/" />
        </intent-filter>
```

2. Add following method to `MainActivity.kt` in android project to be able to make shortUrl Call  :

```kotlin
    class MainActivity: FlutterActivity() {
        .....
         override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        .....
        //handle deep links
            if(intent.action== Intent.ACTION_VIEW && intent.data!=null){
                //VideoEngager.SDK_DEBUG = true //use only in development stage
                val smartVideo = VideoEngager(this,getSettings("Flutter App"), VideoEngager.Engine.generic)
                if(smartVideo.Connect(VideoEngager.CallType.video)) {
                    smartVideo.onEventListener = listener
                    smartVideo.VeVisitorVideoCall(intent.dataString?:"")
                }else {
                    channel.invokeMethod("Ve_onError", "Error from connection!")
                    smartVideo.Disconnect()
                }
            }
        .....
         }
        .....
    }
```

3. Send to VideoEngager following information:

      1. Your app PACKAGE NAME
      2. Your app `test` and `production` SHA-256 keys fingerprint

This information will be added to our `.well-known/assetlinks.json` for verification

You can read more about Android deep links here : https://developer.android.com/training/app-links/


4. After VideoEngager acceptance of your previous step you can verify registration with these steps :
  * Connect device (start emulator) and check adb connection
  * Open terminal and execute following :
```bash
adb shell pm get-app-links <YOUR APP PACKAGE>
```
 this will print as result following :
```bash
  <YOUR APP PACKAGE>:
    ID: fba7a16e-4873-40da-b16c-cbaea06e3a19
    Signatures: [FA:C6:17:45:DC:09:03:78:6F:B9:ED:E6:2A:96:2B:39:9F:73:48:F0:BB:6F:89:9B:83:32:66:75:91:03:3B:9C] // here will be your cert fingerprint
    Domain verification state:
      videome.leadsecure.com: verified
      videome.videoengager.com: verified
```
 If `Domain verification state:` results for `videome.leadsecure.com` and `videome.leadsecure.com` are `verified` you can now open VideoEngager ShortUrlCall links with your App.


 ## iOS implementation

You can check following files for implementation.
/ios/Podfile
/ios/Runner/info.plist
/ios/Runner/AppDelegate.swift

 1. Setup cocoapods
 ``` console
 cd ios
 pod init
 pod install
 ```

Add configurations to Debug.xcconfig
```
#include "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"
```
and to Release.xcconfig
```
#include "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"
#include "Pods/Target Support Files/Pods-Runner/Pods-Runner.profile.xcconfig"
```

2. Add SmartVideo to pod file
Open Podfile with text editor
Add following line under '# Pods for Runner'
```
pod 'SmartVideo'
```
and uncomment and change following line:
```
platform :ios, '13.0'
```

End Podfile should look like this
```
# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

target 'Runner' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Runner
  pod 'SmartVideo'

end
```

Run
``` console
pod install
```

3. Add request for Camera and Microphone permissions
Go to Runner/info.plist and add following rows:
  1. NSMicrophoneUsageDescription
  2. NSCameraUsageDescription

Then open Runner.xcworkspace and find AppDelegate file.
First impor AVKit
```
import AVKit
```

Add following line under 'didFinishLaunchingWithOptions'
```
didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
      if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
            AVCaptureDevice.requestAccess(for: .video) { _ in

            }
        }

        if AVCaptureDevice.authorizationStatus(for: .audio) != .authorized {
            AVCaptureDevice.requestAccess(for: .audio) { _ in
            }
        }
        ...
      }
```

4. Add FlutterMethodChannel
Add channel variables to AppDelelgate.
```
@objc class AppDelegate: FlutterAppDelegate {

    private let VE_CHANNEL_ID = "videoengager.smartvideo.channel"

    var veChannel: FlutterMethodChannel? = nil
    ...
```
Then iniialize them
```
didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        ...
        let rootViewController : FlutterViewController = window?.rootViewController as! FlutterViewController
        self.veChannel = FlutterMethodChannel(name: VE_CHANNEL_ID,
                                              binaryMessenger: rootViewController as! FlutterBinaryMessenger)
        ...
  }
```

5. Add SmartVideo
First import SmartVideo
```
import SmartVideoSDK
```

Then add channel handle of flutter.
```
didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
    ...
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
    ...
```

And at last extend AppDelegate with SmartVideoDelegate
```
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
```
