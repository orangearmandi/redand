package com.example.redand

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "vpn_channel"
    private val PACKET_CHANNEL = "packet_channel"
    private val VPN_REQUEST_CODE = 100

    companion object {
        private var eventSink: EventChannel.EventSink? = null

        fun sendPacketInfo(info: Map<String, Any>) {
            Handler(Looper.getMainLooper()).post {
                eventSink?.success(info)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val vpnChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        val packetChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, PACKET_CHANNEL)

        packetChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        vpnChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startVpn" -> {
                    Log.d("MainActivity", "Starting VPN")
                    val bufferSize = call.argument<Int>("bufferSize") ?: 32767
                    val vpnAddress = call.argument<String>("vpnAddress") ?: "10.0.0.2"
                    val vpnPrefixLength = call.argument<Int>("vpnPrefixLength") ?: 24
                    val dnsServer = call.argument<String>("dnsServer") ?: "8.8.8.8"
                    val routeAddress = call.argument<String>("routeAddress") ?: "0.0.0.0"
                    val routePrefixLength = call.argument<Int>("routePrefixLength") ?: 0
                    val sessionName = call.argument<String>("sessionName") ?: "RedAnd VPN"

                    val intent = VpnService.prepare(this)
                    if (intent != null) {
                        Log.d("MainActivity", "VPN prepare intent not null, starting activity")
                        startActivityForResult(intent, VPN_REQUEST_CODE)
                    } else {
                        Log.d("MainActivity", "VPN already prepared, starting service")
                        val serviceIntent = Intent(this, MyVpnService::class.java).apply {
                            putExtra("bufferSize", bufferSize)
                            putExtra("vpnAddress", vpnAddress)
                            putExtra("vpnPrefixLength", vpnPrefixLength)
                            putExtra("dnsServer", dnsServer)
                            putExtra("routeAddress", routeAddress)
                            putExtra("routePrefixLength", routePrefixLength)
                            putExtra("sessionName", sessionName)
                        }
                        ContextCompat.startForegroundService(this, serviceIntent)
                    }
                    result.success(true)
                }
                "stopVpn" -> {
                    Log.d("MainActivity", "Stopping VPN service")
                    stopService(Intent(this, MyVpnService::class.java))
                    result.success(true)
                }
                "testTraffic" -> {
                    Log.d("MainActivity", "Testing traffic by generating simulated IN packet")
                    // Generate a simulated incoming packet
                    val simulatedPacket = mutableMapOf<String, Any>(
                        "version" to 4,
                        "ihl" to 5,
                        "tos" to 0,
                        "totalLength" to 60,
                        "id" to 12345,
                        "flags" to 0,
                        "fragmentOffset" to 0,
                        "ttl" to 64,
                        "protocol" to 6, // TCP
                        "checksum" to 0,
                        "source" to "192.168.1.100", // Simulated external IP
                        "sourceHost" to "simulated.external.host",
                        "destination" to "10.0.0.2", // VPN IP
                        "destHost" to "",
                        "sourcePort" to 443,
                        "destPort" to 8080,
                        "seq" to 1234567890L,
                        "ack" to 0L,
                        "tcpFlags" to "SYN",
                        "window" to 65535,
                        "length" to 60,
                        "timestamp" to System.currentTimeMillis(),
                        "payload" to "48656C6C6F20576F726C64", // "Hello World" in hex
                        "payloadLength" to 11,
                        "hasMorePayload" to false
                    )
                    sendPacketInfo(simulatedPacket)
                    Log.d("MainActivity", "Simulated IN packet sent")
                    result.success(true)
                }
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        Log.d("MainActivity", "onActivityResult: requestCode=$requestCode, resultCode=$resultCode")
        if (requestCode == VPN_REQUEST_CODE && resultCode == Activity.RESULT_OK) {
            Log.d("MainActivity", "VPN permission granted, starting service")
            val intent = Intent(this, MyVpnService::class.java)
            ContextCompat.startForegroundService(this, intent)
        } else {
            Log.d("MainActivity", "VPN permission denied or cancelled")
        }
    }
}
