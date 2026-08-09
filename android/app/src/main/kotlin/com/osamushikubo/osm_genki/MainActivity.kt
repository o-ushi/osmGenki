package com.osamushikubo.osm_genki

import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.media.ToneGenerator
import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val SOUND_CHANNEL = "com.osamushikubo.osm_genki/system_sound"
    private val RINGTONE_CHANNEL = "com.osamushikubo.osm_genki/ringtones"

    private var offlineSpeechCapture: OfflineSpeechCapture? = null
    private var offlineSpeechProgressSink: EventChannel.EventSink? = null
    private var ringtonePlayer: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        offlineSpeechCapture = OfflineSpeechCapture(
            this,
            Handler(Looper.getMainLooper()),
        ) { progress ->
            offlineSpeechProgressSink?.success(progress)
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            OfflineSpeechCapture.CHANNEL,
        ).setMethodCallHandler { call, result ->
            offlineSpeechCapture?.handle(call, result) ?: result.notImplemented()
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            OfflineSpeechCapture.PROGRESS_CHANNEL,
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                offlineSpeechProgressSink = events
            }

            override fun onCancel(arguments: Any?) {
                offlineSpeechProgressSink = null
            }
        })

        // osmWashabeと同じ仕組み：カウントダウン終了チャイム用のシステムサウンド再生。
        // iOSと違いAndroidにはシステムサウンドIDのカタログが無いため、soundIdの値に
        // 関わらず固定のビープ音を鳴らす。
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SOUND_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method == "play") {
                playNotificationSound()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        // osmWashabeと同じ仕組み：端末の通知音一覧・試聴（タイマー音設定用）。
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            RINGTONE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getRingtones" -> result.success(getAlarmRingtones())
                "getDefaultRingtone" -> result.success(getDefaultNotificationRingtone())
                "play" -> {
                    val uri = call.arguments as? String ?: run {
                        result.success(null); return@setMethodCallHandler
                    }
                    playRingtoneUri(uri)
                    result.success(null)
                }
                "stop" -> {
                    stopRingtonePlayer()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun playNotificationSound() {
        try {
            // STREAM_MUSICで鳴らすことでTTSの音量と一致させる。
            val toneGen = ToneGenerator(AudioManager.STREAM_MUSIC, 100)
            toneGen.startTone(ToneGenerator.TONE_PROP_BEEP2, 700)
            Handler(Looper.getMainLooper()).postDelayed({ toneGen.release() }, 1200)
        } catch (_: Exception) {}
    }

    // 端末の既定の通知音（iOSの「三連音」に相当するAndroid側の実体）を解決する。
    // これが無いと、未選択時にジェネリックなビープ音（playNotificationSound）しか鳴らせない。
    private fun getDefaultNotificationRingtone(): Map<String, String>? {
        return try {
            val uri = RingtoneManager.getActualDefaultRingtoneUri(
                applicationContext,
                RingtoneManager.TYPE_NOTIFICATION,
            ) ?: return null
            val title = RingtoneManager.getRingtone(applicationContext, uri)
                ?.getTitle(applicationContext) ?: return null
            mapOf("uri" to uri.toString(), "title" to title)
        } catch (_: Exception) {
            null
        }
    }

    private fun getAlarmRingtones(): List<Map<String, String>> {
        val list = mutableListOf<Map<String, String>>()
        try {
            val mgr = RingtoneManager(applicationContext)
            mgr.setType(RingtoneManager.TYPE_NOTIFICATION)
            val cursor = mgr.cursor
            while (cursor.moveToNext()) {
                val title = cursor.getString(RingtoneManager.TITLE_COLUMN_INDEX)
                val uri = mgr.getRingtoneUri(cursor.position).toString()
                list.add(mapOf("uri" to uri, "title" to title))
            }
            cursor.close()
        } catch (_: Exception) {}
        return list
    }

    private fun playRingtoneUri(uriString: String) {
        stopRingtonePlayer()
        try {
            ringtonePlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                setDataSource(applicationContext, Uri.parse(uriString))
                setVolume(1.0f, 1.0f)
                prepare()
                setOnCompletionListener { mp ->
                    mp.release()
                    ringtonePlayer = null
                }
                start()
            }
        } catch (_: Exception) {
            ringtonePlayer = null
        }
    }

    private fun stopRingtonePlayer() {
        ringtonePlayer?.stop()
        ringtonePlayer?.release()
        ringtonePlayer = null
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        offlineSpeechCapture?.onRequestPermissionsResult(requestCode, grantResults)
    }

    override fun onDestroy() {
        stopRingtonePlayer()
        offlineSpeechCapture?.dispose()
        offlineSpeechCapture = null
        super.onDestroy()
    }
}
