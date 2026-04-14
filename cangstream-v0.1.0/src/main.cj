/*
 * =====================================================================
 *  CangStream Framework v1.2 — AI Agent Ready
 *  Module:       main
 *  Description:  CangStream 1.2 集成 demo（9 个模块演示）
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
 * main.cj - CangStream 1.2 完整演示
 *
 * 演示 4 个新增模块：
 * 1. JsonExt：JsonValue 路径访问扩展
 * 2. JsonBuilder：链式构建 JSON
 * 3. JsonClient：JSON API 高级客户端（编译验证，不真实调用）
 * 4. SseReader：SSE 事件流解析器
 */
package cangstream

import std.collection.*
import std.io.*
import stdx.encoding.json.*
import cangstream.json.*
import cangstream.http.*
import cangstream.api.*
import cangstream.store.*
import cangstream.process.*

main() {
    println("==================================================")
    println("  CangStream 1.2 - JsonExt + JsonBuilder Demo")
    println("==================================================\n")

    // ========== 演示 1：链式构建 JSON ==========
    println(">>> [1] 链式构建 JSON")
    let req = Json.obj()
        .put("model", "deepseek-chat")
        .put("temperature", 0.75)
        .put("max_tokens", 1500)
        .put("stream", false)
        .put("messages", Json.arr()
            .add(Json.obj()
                .put("role", "system")
                .put("content", "你是仓颉编程语言专家"))
            .add(Json.obj()
                .put("role", "user")
                .put("content", "什么是 CangStream？")))
        .build()

    println("构建的请求体：")
    println(req.toJsonString(0, indent: "  "))
    println()

    // ========== 演示 2：路径访问 ==========
    println(">>> [2] 路径访问")

    // 模拟一个 DeepSeek API 响应
    let respBody = ##"
{
    "id": "chat-12345",
    "object": "chat.completion",
    "model": "deepseek-chat",
    "choices": [
        {
            "index": 0,
            "message": {
                "role": "assistant",
                "content": "CangStream 是一个仓颉 Web 框架。"
            },
            "finish_reason": "stop"
        }
    ],
    "usage": {
        "prompt_tokens": 50,
        "completion_tokens": 20,
        "total_tokens": 70
    }
}
"##

    let resp = Json.parse(respBody)

    // 用路径访问深层字段
    let content = resp.pathString("choices.0.message.content") ?? "(无内容)"
    let model = resp.pathString("model") ?? "(未知)"
    let totalTokens = resp.pathInt("usage.total_tokens") ?? 0
    let finishReason = resp.pathString("choices.0.finish_reason") ?? ""

    println("模型：${model}")
    println("回复内容：${content}")
    println("Token 使用：${totalTokens}")
    println("结束原因：${finishReason}")
    println()

    // ========== 演示 3：has + 默认值 ==========
    println(">>> [3] 路径存在性检查")
    println("has(\"choices.0.message\")  = ${resp.has("choices.0.message")}")
    println("has(\"choices.99.message\") = ${resp.has("choices.99.message")}")
    println("has(\"error\")              = ${resp.has("error")}")
    println()

    // ========== 演示 4：对比原生 stdx 写法 ==========
    println(">>> [4] 对比原生 stdx 写法")
    println("【原生 stdx】：取 choices[0].message.content")

    // 原生写法（暴露问题：每层都是 Option）
    var nativeContent = ""
    let choices = resp.asObject().get("choices")
    match (choices) {
        case Some(c) =>
            let arr = c.asArray()
            match (arr.get(0)) {
                case Some(item) =>
                    let msg = item.asObject().get("message")
                    match (msg) {
                        case Some(m) =>
                            match (m.asObject().get("content")) {
                                case Some(v) => nativeContent = v.asString().getValue()
                                case None => ()
                            }
                        case None => ()
                    }
                case None => ()
            }
        case None => ()
    }
    println("  → 结果：${nativeContent}")
    println("  → 代码：~15 行嵌套 match")
    println()

    println("【CangStream 1.2】：一行")
    let smartContent = resp.pathString("choices.0.message.content") ?? ""
    println("  → 结果：${smartContent}")
    println("  → 代码：1 行")
    println()

    // ========== 演示 5：SseReader 解析 ==========
    println(">>> [5] SseReader：解析 SSE 事件流")

    // 模拟一段 DeepSeek 流式响应（用 ByteArrayStream 包装）
    let sseRaw = "data: {\"choices\":[{\"delta\":{\"content\":\"Cang\"}}]}\n\n" +
                 "data: {\"choices\":[{\"delta\":{\"content\":\"Stream\"}}]}\n\n" +
                 "data: {\"choices\":[{\"delta\":{\"content\":\" 1.2\"}}]}\n\n" +
                 "data: [DONE]\n\n"

    let stream = ByteArrayStream(sseRaw.toArray())

    // 用引用类型 SseState 在 lambda 中保存可变状态
    let state = SseState()
    SseReader.read(stream, { ev =>
        state.count++
        if (ev.isDone()) {
            println("  事件 ${state.count}: [DONE] 流结束")
            return false
        }
        match (ev.parseJson()) {
            case Some(json) =>
                let delta = json.pathString("choices.0.delta.content") ?? ""
                state.combined = state.combined + delta
                println("  事件 ${state.count}: delta=\"${delta}\"")
            case None =>
                println("  事件 ${state.count}: (无法解析)")
        }
        return true
    })

    println("  拼接结果：${state.combined}")
    println()

    // ========== 演示 6：JsonClient 类型验证 ==========
    println(">>> [6] JsonClient API 演示（不真实调用）")
    let headers = HashMap<String, String>()
    headers.add("Authorization", "Bearer sk-fake-key")

    // 仅创建实例验证类型，不真实调用
    let llm = JsonClient("https://api.deepseek.com", headers, timeoutSeconds: 30)
    println("  ✓ JsonClient 创建成功（baseUrl=https://api.deepseek.com）")
    println("  ✓ 默认 headers: Authorization 已注入")
    println("  ✓ 调用方式：")
    println("       let resp = llm.post(\"/v1/chat/completions\", reqBody)")
    println("       let content = resp.body.pathString(\"choices.0.message.content\") ?? \"\"")
    llm.close()
    println("  ✓ JsonClient 已关闭")
    println()

    // ========== 演示 7：JsonServer 注册路由（编译验证） ==========
    println(">>> [7] JsonServer：注册 JSON / SSE 路由（编译验证）")

    let server = JsonServer(8080)

    // 注册一个 JSON API 路由
    server.jsonRoute("/api/echo", { req: JsonRequest =>
        let name = req.body.pathString("name") ?? "guest"
        return JsonResponse.ok(Json.obj()
            .put("greeting", "Hello, ${name}!")
            .put("method", req.method)
            .build())
    })
    println("  ✓ 注册 POST /api/echo  → JSON API")

    // 注册一个返回错误的路由
    server.jsonRoute("/api/error", { _: JsonRequest =>
        return JsonResponse.badRequest("示例错误响应")
    })
    println("  ✓ 注册 POST /api/error → 400 错误响应")

    // 注册一个 SSE 流式路由
    server.sseRoute("/api/stream", { _: JsonRequest, sse: SseSender =>
        for (i in 1..=5) {
            sse.sendJson(Json.obj()
                .put("tick", i)
                .put("message", "心跳 ${i}")
                .build())
        }
        sse.sendDone()
    })
    println("  ✓ 注册 GET  /api/stream → SSE 心跳流")

    // 关闭服务器（不调用 run，避免阻塞 demo）
    server.close()
    println("  ✓ 服务器已关闭（demo 不启动监听，避免阻塞）")
    println()

    println("  💡 真实启动方式：")
    println("       let server = JsonServer(8080)")
    println("       server.jsonRoute(\"/api/echo\", { req => ... })")
    println("       server.run()  // 阻塞监听")
    println()

    // ========== 演示 8：FileStore 持久化 ==========
    println(">>> [8] FileStore：JSON 文件持久化")

    let storePath = "test_config.json"
    let store = FileStore(storePath)
    store.load()

    // 第一次写入
    store.save(Json.obj()
        .put("api_key", "sk-fake-key-123")
        .put("model", "deepseek-chat")
        .put("temperature", 0.75)
        .put("max_tokens", 1500)
        .build())
    println("  ✓ 写入 ${storePath}")

    // 重新读取
    let store2 = FileStore(storePath)
    store2.load()
    let loadedKey = store2.get().pathString("api_key") ?? ""
    let loadedModel = store2.get().pathString("model") ?? ""
    println("  ✓ 重新加载：api_key=${loadedKey}, model=${loadedModel}")

    // 部分更新
    store2.update({ json =>
        Json.obj()
            .put("api_key", json.pathString("api_key") ?? "")
            .put("model", "deepseek-reasoner")  // 改模型
            .put("temperature", json.pathFloat("temperature") ?? 0.5)
            .put("max_tokens", json.pathInt("max_tokens") ?? 1000)
            .put("updated_at", "2026-04-11")     // 新字段
            .build()
    })
    println("  ✓ 部分更新：model → deepseek-reasoner, +updated_at")

    // 验证更新
    let store3 = FileStore(storePath)
    store3.load()
    println("  ✓ 验证：")
    println("       model = ${store3.get().pathString("model") ?? "(none)"}")
    println("       updated_at = ${store3.get().pathString("updated_at") ?? "(none)"}")
    println()

    // ========== 演示 9：ProcessRunner 子进程 ==========
    println(">>> [9] ProcessRunner：子进程执行")

    let runner = ProcessRunner(timeoutSeconds: 5)

    // 测试 1：echo 命令
    let echoResult = runner.run("cmd", ["/c", "echo", "Hello", "from", "Cangjie"])
    println("  [测试 1] cmd /c echo Hello from Cangjie")
    println("    退出码: ${echoResult.exitCode}")
    println("    成功: ${echoResult.isSuccess()}")
    println("    stdout: ${echoResult.stdout.trimAscii()}")
    println("    耗时: ${echoResult.elapsedMs}ms")
    println()

    // 测试 2：echo 多行
    let multiResult = runner.run("cmd", ["/c", "echo line1 && echo line2 && echo line3"])
    println("  [测试 2] cmd /c echo line1 && echo line2 && echo line3")
    println("    退出码: ${multiResult.exitCode}")
    println("    输出: ${multiResult.stdout.trimAscii()}")
    println()

    // 测试 3：失败的命令
    let failResult = runner.run("cmd", ["/c", "exit", "42"])
    println("  [测试 3] cmd /c exit 42")
    println("    退出码: ${failResult.exitCode}")
    println("    成功: ${failResult.isSuccess()}")
    println()

    println("==================================================")
    println("  Demo 完成 ✓ (9 个模块)")
    println("==================================================")
}

/**
 * SSE 测试用的可变状态容器（class 是引用类型，可在 lambda 中修改字段）。
 */
class SseState {
    var count: Int64 = 0
    var combined: String = ""
}

/**
 * 简易内存字节流，用于测试 SseReader（不依赖真实网络）。
 */
class ByteArrayStream <: InputStream {
    private let data: Array<UInt8>
    private var pos: Int64

    init(data: Array<UInt8>) {
        this.data = data
        this.pos = 0
    }

    public func read(buf: Array<UInt8>): Int64 {
        let remaining = data.size - pos
        if (remaining <= 0) {
            return 0
        }
        let n = if (buf.size < remaining) { buf.size } else { remaining }
        for (i in 0..n) {
            buf[i] = data[pos + i]
        }
        pos += n
        return n
    }
}
