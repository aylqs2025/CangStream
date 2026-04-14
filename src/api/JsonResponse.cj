/**
 * JsonResponse.cj - JSON API 响应封装
 *
 * 简单的不可变响应数据结构。由 JsonRoute 自动写回 HttpContext。
 */
package cangstream.api

import stdx.encoding.json.*

/**
 * JSON API 响应对象。
 */
public class JsonResponse {
    public let status: UInt16
    public let body: JsonValue

    public init(body: JsonValue, status!: UInt16 = 200) {
        this.body = body
        this.status = status
    }

    /**
     * 200 OK + JSON 数据。
     */
    public static func ok(data: JsonValue): JsonResponse {
        return JsonResponse(data, status: 200)
    }

    /**
     * 200 OK + 简单消息体 {"message": ...}。
     */
    public static func okMessage(message: String): JsonResponse {
        let obj = JsonObject()
        obj.put("message", JsonString(message))
        return JsonResponse(obj, status: 200)
    }

    /**
     * 错误响应（默认 500），消息体 {"error": ...}。
     */
    public static func error(message: String, status!: UInt16 = 500): JsonResponse {
        let obj = JsonObject()
        obj.put("error", JsonString(message))
        return JsonResponse(obj, status: status)
    }

    /**
     * 400 Bad Request。
     */
    public static func badRequest(message: String): JsonResponse {
        return error(message, status: 400)
    }

    /**
     * 404 Not Found。
     */
    public static func notFound(message!: String = "Not Found"): JsonResponse {
        return error(message, status: 404)
    }

    /**
     * 序列化为字符串。
     */
    public func toString(): String {
        return body.toJsonString()
    }
}
