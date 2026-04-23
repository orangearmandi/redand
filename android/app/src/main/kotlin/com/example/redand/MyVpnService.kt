package com.example.redand

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.VpnService
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.InetAddress

class MyVpnService : VpnService() {

    private var running = false
    private var thread: Thread? = null
    private var inputStream: FileInputStream? = null
    private var outputStream: FileOutputStream? = null

    // VPN Configuration parameters
    private var bufferSize = 32767
    private var vpnAddress = "10.0.0.2"
    private var vpnPrefixLength = 24
    private var dnsServer = "8.8.8.8"
    private var routeAddress = "0.0.0.0"
    private var routePrefixLength = 0
    private var sessionName = "RedAnd VPN"

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("MyVpnService", "onStartCommand called")

        // Read configuration from intent
        intent?.let {
            bufferSize = it.getIntExtra("bufferSize", 32767)
            vpnAddress = it.getStringExtra("vpnAddress") ?: "10.0.0.2"
            vpnPrefixLength = it.getIntExtra("vpnPrefixLength", 24)
            dnsServer = it.getStringExtra("dnsServer") ?: "8.8.8.8"
            routeAddress = it.getStringExtra("routeAddress") ?: "0.0.0.0"
            routePrefixLength = it.getIntExtra("routePrefixLength", 0)
            sessionName = it.getStringExtra("sessionName") ?: "RedAnd VPN"
        }

        Log.d("MyVpnService", "Configuration: bufferSize=$bufferSize, vpnAddress=$vpnAddress, sessionName=$sessionName")

        if (!running) {
            running = true
            startForeground()
            thread = Thread { runVpn() }
            thread?.start()
        } else {
            Log.d("MyVpnService", "Service already running")
        }
        return START_STICKY
    }

    private fun startForeground() {
        val channelId = "vpn_channel"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "VPN Service", NotificationManager.IMPORTANCE_LOW)
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
        val notification: Notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("VPN Active")
            .setContentText("Monitoring network traffic")
            .setSmallIcon(android.R.drawable.ic_secure) // Use a default icon
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(1, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(1, notification)
        }
    }

    private fun runVpn() {
        Log.d("MyVpnService", "runVpn started")
        val builder = Builder()
            .addAddress(vpnAddress, vpnPrefixLength)
            .addDnsServer(dnsServer)
            .addRoute(routeAddress, routePrefixLength)

        val iface = builder.setSession(sessionName).establish()

        if (iface == null) {
            Log.e("MyVpnService", "Failed to establish VPN interface")
            return
        }

        Log.d("MyVpnService", "VPN interface established")

        inputStream = FileInputStream(iface.fileDescriptor)   // Paquetes entrantes
        outputStream = FileOutputStream(iface.fileDescriptor) // Paquetes salientes

        val buffer = ByteArray(bufferSize)

        while (running) {
            try {
                val length = inputStream?.read(buffer) ?: -1
                if (length > 0) {
                    Log.d("MyVpnService", "Received packet length: $length")
                    // Procesar el paquete IP
                    val packetInfo = parseIpPacket(buffer, length)
                    if (packetInfo != null) {
                        Log.d("MyVpnService", "Parsed packet: $packetInfo")
                        MainActivity.sendPacketInfo(packetInfo)
                    }
                    // Para outgoing, escribir de vuelta si es necesario
                    outputStream?.write(buffer, 0, length)
                } else if (length == -1) {
                    // Stream closed
                    break
                }
            } catch (e: Exception) {
                Log.e("MyVpnService", "Error reading packet", e)
                break
            }
        }

        inputStream?.close()
        outputStream?.close()
        inputStream = null
        outputStream = null
    }

    private fun parseIpPacket(buffer: ByteArray, length: Int): Map<String, Any>? {
        if (length < 20) return null // Header mínimo

        val ihl = (buffer[0].toInt() and 0xF) * 4
        val version = (buffer[0].toInt() shr 4) and 0xF
        if (version != 4) return null // Solo IPv4 por ahora

        val tos = buffer[1].toInt() and 0xFF
        val totalLength = ((buffer[2].toInt() and 0xFF) shl 8) or (buffer[3].toInt() and 0xFF)
        val id = ((buffer[4].toInt() and 0xFF) shl 8) or (buffer[5].toInt() and 0xFF)
        val flags = (buffer[6].toInt() and 0xE0) shr 5
        val fragmentOffset = ((buffer[6].toInt() and 0x1F) shl 8) or (buffer[7].toInt() and 0xFF)
        val ttl = buffer[8].toInt() and 0xFF
        val protocol = buffer[9].toInt() and 0xFF
        val checksum = ((buffer[10].toInt() and 0xFF) shl 8) or (buffer[11].toInt() and 0xFF)
        val sourceIp = InetAddress.getByAddress(byteArrayOf(buffer[12], buffer[13], buffer[14], buffer[15])).hostAddress
        val destIp = InetAddress.getByAddress(byteArrayOf(buffer[16], buffer[17], buffer[18], buffer[19])).hostAddress

        val sourceHost = try {
            InetAddress.getByName(sourceIp).hostName
        } catch (e: Exception) {
            ""
        }
        val destHost = try {
            InetAddress.getByName(destIp).hostName
        } catch (e: Exception) {
            ""
        }

        val result = mutableMapOf<String, Any>(
            "version" to version,
            "ihl" to ihl,
            "tos" to tos,
            "totalLength" to totalLength,
            "id" to id,
            "flags" to flags,
            "fragmentOffset" to fragmentOffset,
            "ttl" to ttl,
            "protocol" to protocol,
            "checksum" to checksum,
            "source" to sourceIp,
            "sourceHost" to sourceHost,
            "destination" to destIp,
            "destHost" to destHost,
            "length" to length,
            "timestamp" to System.currentTimeMillis()
        )

        var payloadOffset = ihl

        if (protocol == 6 && length >= ihl + 20) { // TCP
            val tcpOffset = ihl
            val sourcePort = ((buffer[tcpOffset].toInt() and 0xFF) shl 8) or (buffer[tcpOffset + 1].toInt() and 0xFF)
            val destPort = ((buffer[tcpOffset + 2].toInt() and 0xFF) shl 8) or (buffer[tcpOffset + 3].toInt() and 0xFF)
            val seq = ((buffer[tcpOffset + 4].toLong() and 0xFF) shl 24) or ((buffer[tcpOffset + 5].toLong() and 0xFF) shl 16) or ((buffer[tcpOffset + 6].toLong() and 0xFF) shl 8) or (buffer[tcpOffset + 7].toLong() and 0xFF)
            val ack = ((buffer[tcpOffset + 8].toLong() and 0xFF) shl 24) or ((buffer[tcpOffset + 9].toLong() and 0xFF) shl 16) or ((buffer[tcpOffset + 10].toLong() and 0xFF) shl 8) or (buffer[tcpOffset + 11].toLong() and 0xFF)
            val dataOffset = ((buffer[tcpOffset + 12].toInt() and 0xF0) shr 4) * 4
            val flags = buffer[tcpOffset + 13].toInt() and 0x3F
            val window = ((buffer[tcpOffset + 14].toInt() and 0xFF) shl 8) or (buffer[tcpOffset + 15].toInt() and 0xFF)
            val tcpChecksum = ((buffer[tcpOffset + 16].toInt() and 0xFF) shl 8) or (buffer[tcpOffset + 17].toInt() and 0xFF)
            val urgentPointer = ((buffer[tcpOffset + 18].toInt() and 0xFF) shl 8) or (buffer[tcpOffset + 19].toInt() and 0xFF)
            result["sourcePort"] = sourcePort
            result["destPort"] = destPort
            result["seq"] = seq
            result["ack"] = ack
            result["tcpDataOffset"] = dataOffset
            result["tcpFlags"] = flags
            result["window"] = window
            result["tcpChecksum"] = tcpChecksum
            result["urgentPointer"] = urgentPointer
        } else if (protocol == 17 && length >= ihl + 8) { // UDP
            val udpOffset = ihl
            val sourcePort = ((buffer[udpOffset].toInt() and 0xFF) shl 8) or (buffer[udpOffset + 1].toInt() and 0xFF)
            val destPort = ((buffer[udpOffset + 2].toInt() and 0xFF) shl 8) or (buffer[udpOffset + 3].toInt() and 0xFF)
            val udpLength = ((buffer[udpOffset + 4].toInt() and 0xFF) shl 8) or (buffer[udpOffset + 5].toInt() and 0xFF)
            val udpChecksum = ((buffer[udpOffset + 6].toInt() and 0xFF) shl 8) or (buffer[udpOffset + 7].toInt() and 0xFF)
            result["sourcePort"] = sourcePort
            result["destPort"] = destPort
            result["udpLength"] = udpLength
            result["udpChecksum"] = udpChecksum
        } else if (protocol == 1 && length >= ihl + 4) { // ICMP
            val icmpOffset = ihl
            val type = buffer[icmpOffset].toInt() and 0xFF
            val code = buffer[icmpOffset + 1].toInt() and 0xFF
            val icmpChecksum = ((buffer[icmpOffset + 2].toInt() and 0xFF) shl 8) or (buffer[icmpOffset + 3].toInt() and 0xFF)
            result["icmpType"] = type
            result["icmpCode"] = code
            result["icmpChecksum"] = icmpChecksum
            payloadOffset = ihl + 4
        }

        // Extract payload (first 256 bytes max for performance)
        val maxPayloadBytes = 256
        if (length > payloadOffset) {
            val payloadLength = minOf(length - payloadOffset, maxPayloadBytes)
            val payload = ByteArray(payloadLength)
            System.arraycopy(buffer, payloadOffset, payload, 0, payloadLength)
            result["payload"] = payload.joinToString("") { String.format("%02X", it) }
            result["payloadLength"] = payloadLength
            result["hasMorePayload"] = (length - payloadOffset) > maxPayloadBytes
        } else {
            result["payload"] = ""
            result["payloadLength"] = 0
            result["hasMorePayload"] = false
        }

        return result
    }

    override fun onDestroy() {
        Log.d("MyVpnService", "onDestroy called")
        running = false
        thread?.interrupt()
        try {
            inputStream?.close()
            outputStream?.close()
        } catch (e: Exception) {
            Log.e("MyVpnService", "Error closing streams", e)
        }
        inputStream = null
        outputStream = null
        super.onDestroy()
    }
}