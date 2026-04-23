package com.example.redand

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import java.io.FileInputStream
import java.io.IOException
import java.net.InetAddress

class MyVpnService : VpnService() {

    // Traffic permissions (logical filtering)
    private var allowIn = true
    private var allowOut = true

    @Volatile private var running = false
    private var thread: Thread? = null
    @Volatile private var isServiceStopping = false

    private var tunInterface: ParcelFileDescriptor? = null
    private var inputStream: FileInputStream? = null

    // VPN Configuration parameters
    private var bufferSize = 65535
    private var vpnAddress = "10.0.0.2"
    private var vpnPrefixLength = 32
    private var dnsServer = "8.8.8.8"
    private var routeAddress = "0.0.0.0"
    private var routePrefixLength = 0
    private var sessionName = "RedAnd Sniffer"

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand called with intent: ${intent?.action}, flags: $flags, startId: $startId")

        // Verificar si es una acción de parada
        if (intent?.action == ACTION_STOP_VPN) {
            Log.d(TAG, "Received stop action, shutting down service")
            forceStopService()
            return START_NOT_STICKY
        }

        intent?.let {
            bufferSize = it.getIntExtra("bufferSize", 65535).coerceIn(1500, 65535)
            vpnAddress = it.getStringExtra("vpnAddress") ?: "10.0.0.2"
            vpnPrefixLength = it.getIntExtra("vpnPrefixLength", 32).coerceIn(0, 32)
            dnsServer = it.getStringExtra("dnsServer") ?: "8.8.8.8"
            routeAddress = it.getStringExtra("routeAddress") ?: "0.0.0.0"
            routePrefixLength = it.getIntExtra("routePrefixLength", 0).coerceIn(0, 32)
            sessionName = it.getStringExtra("sessionName") ?: "RedAnd Sniffer"
            allowIn = it.getBooleanExtra("allowIn", true)
            allowOut = it.getBooleanExtra("allowOut", true)
        }

        if (running) {
            Log.d(TAG, "Service already running")
            return START_NOT_STICKY
        }

        running = true
        startForegroundCompat()

        thread = Thread { runVpnLoop() }.apply { name = "RedAndVpnThread"; start() }

        return START_NOT_STICKY
    }

    private fun forceStopService() {
        Log.d(TAG, "forceStopService called - INITIATING IMMEDIATE TERMINATION")
        
        // Detener inmediatamente el foreground
        stopForeground(STOP_FOREGROUND_REMOVE)
        
        // Forzar la terminación
        isServiceStopping = true
        running = false
        
        // **CLAVE: Cerrar el TUN primero para desbloquear la lectura**
        forceCloseTun()
        
        // Esperar brevemente para que el hilo responda al cierre
        try {
            Thread.sleep(200)
        } catch (e: Exception) {
            Log.e(TAG, "Error during sleep", e)
        }
        
        // Forzar interrupción del hilo
        thread?.interrupt()
        
        // Cerrar recursos restantes
        cleanupTun()
        
        // Esperar a que el hilo termine
        try {
            thread?.join(1000) // Esperar 1 segundo
            if (thread?.isAlive == true) {
                Log.w(TAG, "Thread still alive after 1s, continuing anyway")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error waiting for thread", e)
        }
        
        // Detener el servicio
        stopSelf()
    }

    private fun startForegroundCompat() {
        val channelId = "vpn_channel"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "VPN Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        val openAppIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        val notification: Notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("VPN Active")
            .setContentText("Capturing packets (no forwarding)")
            .setSmallIcon(android.R.drawable.ic_secure)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()

        startForeground(1, notification)
    }

    private fun runVpnLoop() {
        Log.d(TAG, "runVpnLoop started")
        Log.d(TAG, "Service running state: $running, thread interrupted: ${Thread.currentThread().isInterrupted}, stopping: $isServiceStopping")

        try {
            val builder = Builder()
                .setSession(sessionName)
                .addAddress(vpnAddress, vpnPrefixLength)
                .addDnsServer(dnsServer)
                .addRoute(routeAddress, routePrefixLength)

            // If you want to exclude your own app from VPN capture:
            // builder.addDisallowedApplication(packageName)

            tunInterface = builder.establish()
            if (tunInterface == null) {
                Log.e(TAG, "Failed to establish VPN interface")
                running = false
                stopSelf()
                return
            }

            inputStream = FileInputStream(tunInterface!!.fileDescriptor)

            val buffer = ByteArray(bufferSize)

            while (running && !Thread.currentThread().isInterrupted && !isServiceStopping) {
                val length = try {
                    inputStream!!.read(buffer)
                } catch (e: IOException) {
                    // Verificar si el error es porque el TUN fue cerrado
                    if (e.message?.contains("closed") == true || !running || isServiceStopping) {
                        Log.d(TAG, "TUN closed or service stopping, exiting gracefully: ${e.message}")
                    } else {
                        Log.e(TAG, "Error reading TUN", e)
                    }
                    break
                } catch (e: InterruptedException) {
                    Log.d(TAG, "Thread interrupted during read")
                    break
                } catch (e: Exception) {
                    Log.e(TAG, "Unexpected error reading TUN", e)
                    break
                }

                if (length <= 0) {
                    Log.d(TAG, "Read returned length <= 0: $length")
                    continue
                }
                
                // Verificar estado después de cada lectura
                if (!running || isServiceStopping || Thread.currentThread().isInterrupted) {
                    Log.d(TAG, "Service stopping after read, breaking")
                    break
                }

                val packetInfo = parseIpv4Packet(buffer, length) ?: continue

                // NOTE: "IN/OUT" is not reliably inferable just by comparing to vpnAddress.
                // We'll keep a best-effort heuristic, but don't rely on it for correctness.
                val src = packetInfo["source"] as String
                val dst = packetInfo["destination"] as String
                val isFromDevice = src != vpnAddress && dst != vpnAddress
                // Heuristic: treat packets whose src is NOT the TUN IP as "OUT"
                // (in practice TUN traffic is mostly "outgoing" from apps)
                val allow = when {
                    isFromDevice -> allowOut
                    else -> allowIn || allowOut
                }

                if (allow) {
                    MainActivity.sendPacketInfo(packetInfo)
                }
            }
        } catch (t: Throwable) {
            Log.e(TAG, "Fatal error in VPN loop", t)
        } finally {
            cleanupTun()
            Log.d(TAG, "runVpnLoop finished")
        }
    }

    private fun cleanupTun() {
        try {
            Log.d(TAG, "Starting TUN cleanup")
            
            // Cerrar input stream PRIMERO para desbloquear la lectura
            inputStream?.close()
            inputStream = null
            
            // Pequeña pausa para que el cierre tenga efecto
            Thread.sleep(100)
            
            // Cerrar TUN interface
            tunInterface?.close()
            tunInterface = null
            
            Log.d(TAG, "TUN cleanup completed")
        } catch (e: Exception) {
            Log.e(TAG, "Error cleaning up TUN", e)
        }
    }
    
    private fun forceCloseTun() {
        Log.d(TAG, "Force closing TUN to unblock thread")
        try {
            // Cerrar el input stream primero (esto debería causar IOException en read())
            inputStream?.close()
            inputStream = null
            
            // Esperar un momento
            Thread.sleep(50)
            
            // Cerrar el TUN interface
            tunInterface?.close()
            tunInterface = null
            
            Log.d(TAG, "TUN force closed")
        } catch (e: Exception) {
            Log.e(TAG, "Error force closing TUN", e)
        }
    }

    private fun parseIpv4Packet(buffer: ByteArray, length: Int): Map<String, Any>? {
        if (length < 20) return null

        val vihl = buffer[0].toInt() and 0xFF
        val version = (vihl ushr 4) and 0x0F
        if (version != 4) return null

        val ihl = (vihl and 0x0F) * 4
        if (ihl < 20 || length < ihl) return null

        val totalLength = ((buffer[2].toInt() and 0xFF) shl 8) or (buffer[3].toInt() and 0xFF)
        // totalLength can be smaller than the read length; clamp
        val effectiveLength = minOf(length, totalLength.coerceAtLeast(ihl))

        val ttl = buffer[8].toInt() and 0xFF
        val protocol = buffer[9].toInt() and 0xFF

        val sourceIp = InetAddress.getByAddress(byteArrayOf(buffer[12], buffer[13], buffer[14], buffer[15])).hostAddress
        val destIp = InetAddress.getByAddress(byteArrayOf(buffer[16], buffer[17], buffer[18], buffer[19])).hostAddress

        val result = mutableMapOf<String, Any>(
            "version" to 4,
            "ihl" to ihl,
            "totalLength" to totalLength,
            "ttl" to ttl,
            "protocol" to protocol,
            "source" to sourceIp,
            "destination" to destIp,
            "length" to effectiveLength,
            "timestamp" to System.currentTimeMillis()
        )

        // Transport headers
        if (protocol == 6 && effectiveLength >= ihl + 20) { // TCP
            val off = ihl
            val sourcePort = ((buffer[off].toInt() and 0xFF) shl 8) or (buffer[off + 1].toInt() and 0xFF)
            val destPort = ((buffer[off + 2].toInt() and 0xFF) shl 8) or (buffer[off + 3].toInt() and 0xFF)
            result["sourcePort"] = sourcePort
            result["destPort"] = destPort
        } else if (protocol == 17 && effectiveLength >= ihl + 8) { // UDP
            val off = ihl
            val sourcePort = ((buffer[off].toInt() and 0xFF) shl 8) or (buffer[off + 1].toInt() and 0xFF)
            val destPort = ((buffer[off + 2].toInt() and 0xFF) shl 8) or (buffer[off + 3].toInt() and 0xFF)
            result["sourcePort"] = sourcePort
            result["destPort"] = destPort
        }

        // Payload preview (hex) limited
        val payloadOffset = ihl
        val maxPayloadBytes = 256
        if (effectiveLength > payloadOffset) {
            val payloadLength = minOf(effectiveLength - payloadOffset, maxPayloadBytes)
            val sb = StringBuilder(payloadLength * 2)
            for (i in 0 until payloadLength) {
                sb.append(String.format("%02X", buffer[payloadOffset + i]))
            }
            result["payload"] = sb.toString()
            result["payloadLength"] = payloadLength
            result["hasMorePayload"] = (effectiveLength - payloadOffset) > maxPayloadBytes
        } else {
            result["payload"] = ""
            result["payloadLength"] = 0
            result["hasMorePayload"] = false
        }

        return result
    }

    override fun onDestroy() {
        Log.d(TAG, "onDestroy called - starting service shutdown sequence")
        isServiceStopping = true
        running = false
        
        try {
            unregisterReceiver(stopReceiver)
            Log.d(TAG, "StopReceiver unregistered")
        } catch (e: Exception) {
            Log.w(TAG, "Error unregistering receiver", e)
        }
        
        stopForeground(STOP_FOREGROUND_REMOVE)
        cleanupTun()
        
        // Interrumpir el hilo
        thread?.interrupt()
        
        // Esperar a que el hilo termine con timeout
        try {
            thread?.join(2000) // Esperar hasta 2 segundos
            if (thread?.isAlive == true) {
                Log.w(TAG, "Thread still alive after interrupt, forcing stop")
                // Forzar la parada del hilo como último recurso
                thread?.stop()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error waiting for thread to finish", e)
        }
        
        thread = null
        isServiceStopping = false
        Log.d(TAG, "onDestroy completed - service fully stopped")
        super.onDestroy()
    }

    companion object {
        private const val TAG = "MyVpnService"
        const val ACTION_STOP_VPN = "com.example.redand.STOP_VPN"
        const val ACTION_FORCE_STOP_VPN = "com.example.redand.FORCE_STOP_VPN"
    }

    private val stopReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            Log.d(TAG, "StopReceiver received: ${intent.action}")
            when (intent.action) {
                ACTION_FORCE_STOP_VPN -> {
                    Log.d(TAG, "Force stop received - terminating service immediately")
                    forceStopService()
                }
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "onCreate called")
        
        // Registrar el broadcast receiver
        val filter = IntentFilter().apply {
            addAction(ACTION_FORCE_STOP_VPN)
        }
        registerReceiver(stopReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        Log.d(TAG, "StopReceiver registered")
    }
}