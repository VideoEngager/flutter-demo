package com.example.veflutdemo

import android.content.Intent
import android.widget.Toast
import com.google.gson.Gson
import com.videoengager.sdk.VideoEngager
import com.videoengager.sdk.model.Error
import com.videoengager.sdk.model.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    private val VE_CHANNEL_ID = "videoengager.smartvideo.channel"

    private lateinit var channel:MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VE_CHANNEL_ID)
        channel.setMethodCallHandler {
                call, result ->
            // This method is invoked on the main thread.
            when(call.method){
                "ClickToVideo" -> {
                    val customerName = call.arguments.toString()
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
            }
        }

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
    }

    fun getSettings(customerName:String):Settings{
        return Settings(
            OrganizationId = "c4b553c3-ee42-4846-aeb1-f0da3d85058e",
            DeploymentId = "973f8326-c601-40c6-82ce-b87e6dafef1c",
            VideoengagerUrl = "https://videome.videoengager.com",
            TennathId = "0FphTk091nt7G1W7",
            Environment = "https://api.mypurecloud.com",
            Queue = "Support",
            AgentShortURL = "mobiledev",
            MyNickname = customerName,
            MyFirstName = customerName,
            MyLastName = "",
            MyEmail = "test@test.com",
            MyPhone = "",
            Language = VideoEngager.Language.ENGLISH
        )
    }

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
}


