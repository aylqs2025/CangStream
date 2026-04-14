//****************************************************************
//* CangStream Framework v1.0
//* Module: HttpServer
//* Author: Li Qingsheng
//* Organization: Zhejiang University of Media and Communications
//* Creation Date: 2025-12-15
//* Description: Thread-safe state management with mutex protection
//****************************************************************
// HTTP 服务器实现
package cangstream.server

import stdx.net.http.*
import stdx.log.*
import std.collection.*
import std.convert.*
import cangstream.core.*

public class HttpServerManager {
    private var server: Server
    private let port: Int64
    
    public init(port: Int64) {
        this.port = port
        this.server = ServerBuilder()
            .addr("127.0.0.1")
            .port(UInt16(port))
            .build()
    }
    
    public func registerRoute(path: String, handler: (HttpContext) -> Unit) {
        server.distributor.register(path, handler)
    }
    
    public func start() {
        println("🚀 CangStream 应用启动在 http://127.0.0.1:${port}")
        println("📝 按 Ctrl+C 停止服务器\n")
        
        server.logger.level = LogLevel.OFF
        server.serve()
    }
}

// JSON 解析辅助函数
public func extractJsonValue(json: String, startPos: Int64): String {
    var result = ""
    var i = startPos
    let jsonBytes = json.toUtf8()
    let quoteChar: UInt8 = 34  // ASCII '"'
    
    while (i < jsonBytes.size && jsonBytes[i] != quoteChar) {
        result += String.fromUtf8(Array<UInt8>(1, item: jsonBytes[i]))
        i++
    }
    return result
}