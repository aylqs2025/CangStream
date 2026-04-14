/*
 * =====================================================================
 *  CangStream Framework v1.2 — AI Agent Ready
 *  Module:       http.JsonClient
 *  Description:  JSON API 高级客户端（基于 stdx.net.http.Client）
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
 * JsonClient.cj - JSON API 高级客户端
 *
 * 基于 stdx.net.http.Client 的轻量封装：
 * - 自动设置 Content-Type / Authorization 等通用 header
 * - 自动 JSON 序列化（请求体）和反序列化（响应体）
 * - 路径访问通过 cangstream.json.JsonExt 直接可用
 * - 支持 SSE 流式 POST（用于 LLM 流式回复）
 *
 * 示例：
 *   import cangstream.http.*
 *   import cangstream.json.*
 *
 *   let headers = HashMap<String, String>()
 *   headers.put("Authorization", "Bearer sk-xxx")
 *   let client = JsonClient("https://api.deepseek.com", headers, 60)
 *
 *   let req = Json.obj()
 *       .put("model", "deepseek-chat")
 *       .put("messages", buildMessages())
 *       .build()
 *
 *   let resp = client.post("/v1/chat/completions", req)
 *   let content = resp.body.pathString("choices.0.message.content") ?? ""
 */
package cangstream.http

import std.collection.*
import std.io.*
import stdx.net.http.*
import stdx.encoding.json.*

/**
 * JSON API 调用结果。
 */
public class JsonResult {
    public let status: UInt16
    public let body: JsonValue        // 已自动解析的 JSON
    public let raw: String            // 原始字符串备份

    public init(status: UInt16, body: JsonValue, raw: String) {
        this.status = status
        this.body = body
        this.raw = raw
    }

    /**
     * HTTP 状态码是否表示成功（2xx）。
     */
    public func isSuccess(): Bool {
        return status >= 200 && status < 300
    }
}

/**
 * JSON API 高级客户端。
 *
 * 内部维护一个 stdx.net.http.Client 和默认 headers，
 * 调用方只需要关心 JSON body，不用关心 Content-Type、序列化等细节。
 */
public class JsonClient {
    private let client: Client
    private let baseUrl: String
    private let defaultHeaders: HashMap<String, String>

    /**
     * 构造 JSON 客户端。
     *
     * @param baseUrl 基础 URL，如 "https://api.deepseek.com"
     * @param headers 默认请求头（如 Authorization）
     * @param timeoutSeconds 读写超时秒数（默认 60 秒）
     */
    public init(
        baseUrl: String,
        headers: HashMap<String, String>,
        timeoutSeconds!: Int64 = 60
    ) {
        this.baseUrl = baseUrl
        this.defaultHeaders = headers
        this.client = ClientBuilder()
            .readTimeout(Duration.second * timeoutSeconds)
            .writeTimeout(Duration.second * timeoutSeconds)
            .build()
    }

    /**
     * GET 请求，返回 JSON 解析结果。
     */
    public func get(path: String): JsonResult {
        let url = this.baseUrl + path
        let reqBuilder = HttpRequestBuilder().get().url(url)
        applyDefaultHeaders(reqBuilder)
        let req = reqBuilder.build()
        let rsp = client.send(req)
        return parseResponse(rsp)
    }

    /**
     * POST 请求，请求体为 JsonValue。
     */
    public func post(path: String, body: JsonValue): JsonResult {
        return postString(path, body.toJsonString())
    }

    /**
     * POST 请求，请求体为已序列化的 JSON 字符串。
     */
    public func postString(path: String, body: String): JsonResult {
        let url = this.baseUrl + path
        let reqBuilder = HttpRequestBuilder()
            .post()
            .url(url)
            .header("Content-Type", "application/json")
            .body(body)
        applyDefaultHeaders(reqBuilder)
        let req = reqBuilder.build()
        let rsp = client.send(req)
        return parseResponse(rsp)
    }

    /**
     * SSE 流式 POST。
     * 每收到一个 SSE 事件，调用 onEvent 回调。
     * 回调返回 false 时中断读取（客户端断开等场景）。
     *
     * @return 完整的拼接结果（用于事后日志/调试）
     */
    public func postStream(
        path: String,
        body: JsonValue,
        onEvent: (SseEvent) -> Bool
    ): Unit {
        let url = this.baseUrl + path
        let reqBuilder = HttpRequestBuilder()
            .post()
            .url(url)
            .header("Content-Type", "application/json")
            .header("Accept", "text/event-stream")
            .body(body.toJsonString())
        applyDefaultHeaders(reqBuilder)
        let req = reqBuilder.build()
        let rsp = client.send(req)

        // 持续从响应流读取并按 SSE 事件解析
        SseReader.read(rsp.body, onEvent)
    }

    /**
     * 关闭客户端，释放底层连接池。
     */
    public func close(): Unit {
        client.close()
    }

    /**
     * 把默认 headers 应用到请求构建器。
     */
    private func applyDefaultHeaders(builder: HttpRequestBuilder): Unit {
        for ((k, v) in defaultHeaders) {
            builder.header(k, v)
        }
    }

    /**
     * 把 HttpResponse 解析为 JsonResult（读取 body + 解析 JSON）。
     */
    private func parseResponse(rsp: HttpResponse): JsonResult {
        let raw = readAllString(rsp.body)
        let json = try {
            JsonValue.fromStr(raw)
        } catch (e: Exception) {
            // 解析失败时返回 JsonNull，但保留 raw 供调用方查看
            JsonNull()
        }
        return JsonResult(rsp.status, json, raw)
    }
}

/**
 * 把 InputStream 全部读取为 UTF-8 字符串。
 *
 * 由于响应可能很大，循环读取直到流结束。
 */
public func readAllString(stream: InputStream): String {
    let bufSize = 4096
    let result = ArrayList<UInt8>()

    while (true) {
        let buf = Array<UInt8>(bufSize, repeat: 0)
        let n = stream.read(buf)
        if (n <= 0) {
            break
        }
        for (i in 0..n) {
            result.add(buf[i])
        }
    }

    return String.fromUtf8(result.toArray())
}
