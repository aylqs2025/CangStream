/**
 * JsonRequest.cj - JSON API 请求封装
 *
 * 把 stdx.net.http.HttpContext 中的请求体自动解析为 JsonValue，
 * 让 handler 可以直接通过路径访问字段，无需手动读取 InputStream + 解析。
 */
package cangstream.api

import std.collection.*
import std.io.*
import stdx.net.http.*
import stdx.encoding.json.*

/**
 * JSON API 请求对象，包装 HttpContext 的请求部分。
 */
public class JsonRequest {
    public let method: String
    public let path: String
    public let body: JsonValue        // 已自动解析为 JSON（解析失败为 JsonNull）
    public let raw: String            // 原始请求体字符串
    public let headers: HttpHeaders
    public let context: HttpContext   // 原始 HttpContext，紧急情况下可直接访问

    public init(ctx: HttpContext) {
        this.context = ctx
        this.method = ctx.request.method
        this.path = ctx.request.url.path
        this.headers = ctx.request.headers

        // 读取请求体并尝试解析 JSON
        let bodyStr = readRequestBody(ctx)
        this.raw = bodyStr

        if (bodyStr.size == 0) {
            this.body = JsonNull()
        } else {
            this.body = try {
                JsonValue.fromStr(bodyStr)
            } catch (e: Exception) {
                JsonNull()
            }
        }
    }

    /**
     * 取请求头第一个值。
     */
    public func header(name: String): ?String {
        return headers.getFirst(name)
    }
}

/**
 * 把 HttpContext 的请求 body 完整读取为字符串。
 *
 * 由于 stdx.net.http 的 InputStream.read 单次最多读 buf.size 字节，
 * 需要循环读取直到 EOF。
 */
func readRequestBody(ctx: HttpContext): String {
    let stream = ctx.request.body
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

    if (result.size == 0) {
        return ""
    }
    return String.fromUtf8(result.toArray())
}
