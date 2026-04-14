/**
 * SseSender.cj - 服务器端 SSE 事件推送
 *
 * 包装 stdx.net.http.HttpResponseWriter，按 Server-Sent Events 协议
 * 向浏览器推送实时事件。
 *
 * 用途：LLM 流式响应、实时数据推送、聊天通知等。
 *
 * 使用模式：
 *   server.sseRoute("/api/chat/stream", { req: JsonRequest, sse: SseSender =>
 *       sse.sendJson(Json.obj().put("delta", "hello").build())
 *       sse.sendJson(Json.obj().put("delta", " world").build())
 *       sse.sendDone()
 *   })
 */
package cangstream.api

import stdx.net.http.*
import stdx.encoding.json.*

/**
 * SSE 事件推送器。
 *
 * ⚠ 注意：必须在 sseRoute handler 内部使用。
 *    handler 一旦返回，response 自动关闭。
 */
public class SseSender {
    private let writer: HttpResponseWriter
    private var closed: Bool

    public init(ctx: HttpContext) {
        // 设置 SSE 必需的响应头 + chunked transfer
        ctx.responseBuilder
            .status(200)
            .header("Content-Type", "text/event-stream; charset=utf-8")
            .header("Cache-Control", "no-cache")
            .header("Connection", "keep-alive")
            .header("Transfer-Encoding", "chunked")
            .header("X-Accel-Buffering", "no")
        this.writer = HttpResponseWriter(ctx)
        this.closed = false
    }

    /**
     * 发送一条 SSE 事件，仅 data 字段。
     */
    public func send(data: String): Unit {
        if (closed) { return }
        let payload = "data: " + data + "\n\n"
        writer.write(payload.toArray())
    }

    /**
     * 发送一条带 event 名的 SSE 事件。
     */
    public func sendEvent(event: String, data: String): Unit {
        if (closed) { return }
        let payload = "event: " + event + "\ndata: " + data + "\n\n"
        writer.write(payload.toArray())
    }

    /**
     * 发送一个 JSON 对象作为事件 data。
     */
    public func sendJson(json: JsonValue): Unit {
        send(json.toJsonString())
    }

    /**
     * 发送 [DONE] 标记，符合 OpenAI / DeepSeek 流式约定。
     */
    public func sendDone(): Unit {
        send("[DONE]")
    }

    /**
     * 发送一条注释行（: 开头），用于 keep-alive 心跳。
     */
    public func sendComment(comment: String): Unit {
        if (closed) { return }
        let payload = ": " + comment + "\n\n"
        writer.write(payload.toArray())
    }

    /**
     * 标记发送器关闭。后续 send 调用会被静默忽略。
     */
    public func close(): Unit {
        this.closed = true
    }

    /**
     * 是否已关闭。
     */
    public func isClosed(): Bool {
        return closed
    }
}
