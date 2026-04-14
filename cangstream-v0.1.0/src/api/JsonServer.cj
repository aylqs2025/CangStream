/*
 * =====================================================================
 *  CangStream Framework v1.2 — AI Agent Ready
 *  Module:       api.JsonServer
 *  Description:  JSON / SSE 路由服务器（基于 stdx.net.http.Server）
 * ---------------------------------------------------------------------
 *  Author:       Li Qingsheng
 *  GitHub:       https://github.com/aylqs2025/CangStream
 *
 *  Copyright 2025 Li Qingsheng
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 * =====================================================================
 */

/**
 * JsonServer.cj - JSON / SSE 服务器
 *
 * 基于 stdx.net.http.Server 的高级封装：
 * - jsonRoute(path, handler) — 注册 JSON API 路由（自动解析请求体、序列化响应）
 * - sseRoute(path, handler)  — 注册 SSE 流式路由
 * - 同时仍可通过 rawRoute() 注册底层 HttpContext 路由
 *
 * 设计上独立于 v0.1.0 的 CangStreamApp，避免破坏现有 UI 框架；
 * 后续可被 CangStreamApp 1.2 聚合。
 *
 * 示例：
 *   import cangstream.api.*
 *   import cangstream.json.*
 *
 *   let server = JsonServer(8080)
 *
 *   server.jsonRoute("/api/echo", { req: JsonRequest =>
 *       let name = req.body.pathString("name") ?? "guest"
 *       return JsonResponse.ok(Json.obj()
 *           .put("greeting", "Hello, ${name}!")
 *           .build())
 *   })
 *
 *   server.sseRoute("/api/stream", { req: JsonRequest, sse: SseSender =>
 *       for (i in 1..=5) {
 *           sse.sendJson(Json.obj().put("tick", i).build())
 *       }
 *       sse.sendDone()
 *   })
 *
 *   server.run()
 */
package cangstream.api

import stdx.net.http.*
import stdx.log.*

/**
 * JSON / SSE 路由服务器。
 */
public class JsonServer {
    private var server: Server
    private let host: String
    private let port: Int64

    /**
     * 创建服务器。
     *
     * @param port 监听端口
     * @param host 绑定地址，默认 127.0.0.1
     */
    public init(port: Int64, host!: String = "127.0.0.1") {
        this.host = host
        this.port = port
        this.server = ServerBuilder()
            .addr(host)
            .port(UInt16(port))
            .build()
    }

    /**
     * 注册一个 JSON API 路由。
     *
     * 接收的 handler 通过 JsonRequest 拿到自动解析后的请求体，
     * 返回 JsonResponse 后会被自动写入 HttpContext 响应。
     *
     * handler 内部如果抛异常，会被捕获并返回 500 错误响应。
     */
    public func jsonRoute(path: String, handler: (JsonRequest) -> JsonResponse): Unit {
        server.distributor.register(path, { ctx: HttpContext =>
            let req = JsonRequest(ctx)
            let resp = try {
                handler(req)
            } catch (e: Exception) {
                JsonResponse.error("Internal Server Error: ${e.message}", status: 500)
            }
            ctx.responseBuilder
                .status(resp.status)
                .header("Content-Type", "application/json; charset=utf-8")
                .header("Access-Control-Allow-Origin", "*")
                .body(resp.toString())
        })
    }

    /**
     * 注册一个 SSE 流式路由。
     *
     * handler 内部应使用 SseSender 持续推送事件。
     * handler 返回后响应自动关闭。
     */
    public func sseRoute(path: String, handler: (JsonRequest, SseSender) -> Unit): Unit {
        server.distributor.register(path, { ctx: HttpContext =>
            let req = JsonRequest(ctx)
            let sse = SseSender(ctx)
            try {
                handler(req, sse)
            } catch (e: Exception) {
                // SSE 通道里的异常没法返回 HTTP 错误，只能关闭流
                ()
            }
            sse.close()
        })
    }

    /**
     * 注册原生路由（直接拿到 HttpContext，最大灵活性）。
     */
    public func rawRoute(path: String, handler: (HttpContext) -> Unit): Unit {
        server.distributor.register(path, handler)
    }

    /**
     * 启动服务（阻塞）。
     */
    public func run(): Unit {
        println("🚀 CangStream JsonServer 启动在 http://${host}:${port}")
        println("📝 按 Ctrl+C 停止服务器")
        server.logger.level = LogLevel.OFF
        server.serve()
    }

    /**
     * 关闭服务。
     */
    public func close(): Unit {
        server.close()
    }
}
