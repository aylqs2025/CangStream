/*
 * =====================================================================
 *  CangStream Framework v1.2 — AI Agent Ready
 *  Module:       api.JsonResponse
 *  Description:  JSON API 响应封装（ok / error / badRequest 工厂）
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
