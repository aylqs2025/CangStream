# CHANGELOG

## v1.2.0 — AI Agent Ready (2026-04-11)

从"UI 框架"升级为"**全栈 Web 框架 + AI Agent 基础设施**"。零依赖（除 std/stdx），全部基于仓颉 1.0.1 stdx 已有能力做轻量增强。

### ✨ 新增模块

**`cangstream.json` — JSON 路径访问与链式构建**
- `JsonPathExt` 接口 + `extend JsonValue` 提供 `pathString / pathInt / pathFloat / pathBool / pathArray / pathObject / has` 方法
- 路径语法支持对象字段 + 数组下标：`"choices.0.message.content"`
- `Json.obj() / Json.arr()` 流畅构建器，告别 `JsonObject.put` 样板代码
- 替换 15 行嵌套 `match` → 1 行路径访问

**`cangstream.http` — JSON HTTP 客户端**
- `JsonClient` 基于 `stdx.net.http.Client`，自动序列化/反序列化 JSON
- `postStream` 支持 SSE 流式响应（LLM 场景）
- `SseReader` 状态机式 SSE 事件流解析器，支持 `data / event / id / retry` 字段
- `SseEvent.parseJson() / isDone()` 便捷方法

**`cangstream.api` — JSON / SSE 服务端**
- `JsonServer` 基于 `stdx.net.http.Server`，一行注册 JSON / SSE 路由
- `JsonRequest` 自动解析请求体为 `JsonValue`
- `JsonResponse` 提供 `ok / error / badRequest / notFound` 工厂
- `SseSender` 封装 `HttpResponseWriter`，按 SSE 协议推送事件
- 支持 chunked transfer encoding

**`cangstream.store` — JSON 文件持久化**
- `FileStore` 带内存缓存、`Mutex` 并发锁
- `load / save / update / get` 四个核心方法
- updater 模式支持函数式更新

**`cangstream.process` — 子进程执行器**
- `ProcessRunner` 基于 `std.process.launch + waitOutput`
- 捕获 exitCode / stdout / stderr
- 用 `spawn` 协程实现超时监督（仓颉 `SubProcess` 本身无 timeout 参数）
- `runShell` 便捷方法

### 🎯 设计原则

- **零重复造轮子**：所有底层能力都用 stdx 已有的（json / http / tls / process / fs / sync）
- **只做易用性增强**：接口扩展、Builder 模式、自动序列化
- **保持框架轻量**：不引入新的第三方依赖

### 💡 使用示例

```cangjie
// 调用 DeepSeek API
let llm = JsonClient("https://api.deepseek.com", headers)
let req = Json.obj()
    .put("model", "deepseek-chat")
    .put("messages", buildMessages())
    .build()

let resp = llm.post("/v1/chat/completions", req)
let content = resp.body.pathString("choices.0.message.content") ?? ""
```

```cangjie
// 启动 REST + SSE 服务器
let server = JsonServer(8080)

server.jsonRoute("/api/echo", { req =>
    return JsonResponse.ok(Json.obj()
        .put("greeting", "Hello, ${req.body.pathString("name") ?? "guest"}")
        .build())
})

server.sseRoute("/api/stream", { _, sse =>
    for (i in 1..=5) {
        sse.sendJson(Json.obj().put("tick", i).build())
    }
    sse.sendDone()
})

server.run()
```

### 🐛 兼容性

- 仓颉 cjc-version: **1.0.1+**
- 依赖 stdx: 1.0.1.1
- v0.1.0 UI 框架模块（`cangstream.core` / `components` / `server`）暂时迁移到 `legacy_v0.1/`，待 v1.3 重构后合并回来

### 📋 累计代码量

- 9 个核心模块文件
- 约 1400 行仓颉代码
- 9 个 demo 全部编译 + 运行通过
- JsonServer 经过真实 HTTP 端到端测试（4 个端点全部工作）

---

## v0.1.0 — Initial Release (2025-12-15)

- `CangStreamApp` 主类
- Streamlit 风格声明式 UI 组件（title / header / text / button / textInput / slider / metric / code / columns）
- `SessionState` 线程安全状态管理
- `HttpServerManager` HTTP 服务器封装
- 三个示例：hello_world / counter / dashboard
