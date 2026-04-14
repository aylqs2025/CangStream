# CangStream (仓穹)

## 仓穹——源自仓颉，广阔如穹的 Web 框架与 AI Agent 基础设施

<div align="center">

![CangStream](https://img.shields.io/badge/CangStream-v1.2.0-purple?style=for-the-badge)
![Cangjie](https://img.shields.io/badge/Cangjie-1.0.1+-blue?style=for-the-badge)
![License](https://img.shields.io/badge/License-Apache%202.0-green?style=for-the-badge)

**🚀 纯仓颉编写的 Web 框架 + AI Agent 基础设施**

JSON · HTTP · SSE · 路由 · 持久化 · 子进程 —— 一个依赖，全栈覆盖

[快速开始](#-快速开始) · [模块文档](#-模块文档) · [示例](#-示例) · [CHANGELOG](CHANGELOG.md)

</div>

---

## ✨ 特性

- 🎯 **零重复造轮子** — 所有底层能力都基于仓颉 `stdx` 已有模块，只做易用性增强
- 🧠 **AI Agent Ready** — 内置 JSON API 客户端、SSE 流式解析、子进程沙箱，开箱即用
- ⚡ **轻量封装** — 用接口扩展、链式 Builder、自动序列化让 API 极致简洁
- 🔒 **线程安全** — 内置 `Mutex` 保护共享状态
- 📦 **单依赖** — 除 `std` / `stdx` 外无任何第三方依赖

## 🎯 适用场景

- 🤖 **AI Agent / LLM 应用** — 调用 DeepSeek / OpenAI / 通义千问等大模型 API
- 🔧 **JSON / REST API 服务器** — 轻量级微服务、内部工具后端
- 🌊 **SSE 实时推送** — 聊天流式回复、实时通知、进度推送
- 🧪 **CI / 沙箱工具** — 执行外部命令并捕获输出
- 📂 **配置管理工具** — 小型应用的 JSON 持久化

---

## 📦 快速开始

### 安装要求

```bash
# 仓颉编译器版本
cangjie >= 1.0.1
```

### 克隆 + 构建

```bash
git clone https://github.com/aylqs2025/CangStream.git
cd CangStream
cjpm build
cjpm run  # 运行 9 个模块 demo
```

### 在你的项目里引用

方式一：本地路径引用（将 `CangStream` 目录作为子模块）

```toml
# 你的 cjpm.toml
[dependencies]
cangstream = { path = "../CangStream" }
```

方式二：直接 clone 到你的项目并修改包路径

---

## 📚 模块文档

CangStream 1.2 包含 **5 大模块**：

### 1. `cangstream.json` — JSON 路径访问与链式构建

```cangjie
import stdx.encoding.json.*
import cangstream.json.*

// ====== 链式构建（替代手写 JsonObject.put） ======
let req = Json.obj()
    .put("model", "deepseek-chat")
    .put("temperature", 0.75)
    .put("messages", Json.arr()
        .add(Json.obj().put("role", "user").put("content", "你好")))
    .build()

// ====== 路径访问（替代 15 行嵌套 match） ======
let resp = JsonValue.fromStr(httpBody)
let content = resp.pathString("choices.0.message.content") ?? ""
let tokens = resp.pathInt("usage.total_tokens") ?? 0
```

**API：**
- `Json.obj()` / `Json.arr()` / `Json.parse(s)` / `Json.str / int / float / bool`
- `JsonObjBuilder.put(key, value)` 支持 String/Int64/Float64/Bool/JsonValue/嵌套 Builder
- `extend JsonValue` 新增 `path / pathString / pathInt / pathFloat / pathBool / pathArray / pathObject / has`

### 2. `cangstream.http` — JSON HTTP 客户端

```cangjie
import cangstream.json.*
import cangstream.http.*
import std.collection.*

let headers = HashMap<String, String>()
headers.add("Authorization", "Bearer sk-xxx")
let client = JsonClient("https://api.deepseek.com", headers, timeoutSeconds: 60)

// ====== 普通请求 ======
let resp = client.post("/v1/chat/completions", req)
let content = resp.body.pathString("choices.0.message.content") ?? ""

// ====== SSE 流式请求（LLM 流式回复） ======
client.postStream("/v1/chat/completions", req, onEvent: { ev: SseEvent =>
    if (ev.isDone()) { return false }
    let delta = ev.parseJson()?.pathString("choices.0.delta.content") ?? ""
    print(delta)
    return true
})
```

**API：**
- `JsonClient(baseUrl, defaultHeaders, timeoutSeconds)`
- `client.get(path)` / `client.post(path, body)` / `client.postStream(path, body, onEvent)`
- `JsonResult.status / body / raw / isSuccess()`
- `SseReader.read(stream, onEvent)` 独立解析器
- `SseEvent.event / data / parseJson() / isDone()`

### 3. `cangstream.api` — JSON / SSE 服务端

```cangjie
import cangstream.json.*
import cangstream.api.*

let server = JsonServer(8080)

// JSON API 路由
server.jsonRoute("/api/echo", { req: JsonRequest =>
    let name = req.body.pathString("name") ?? "guest"
    return JsonResponse.ok(Json.obj()
        .put("greeting", "Hello, ${name}!")
        .build())
})

// SSE 流式路由
server.sseRoute("/api/stream", { _: JsonRequest, sse: SseSender =>
    for (i in 1..=10) {
        sse.sendJson(Json.obj().put("tick", i).build())
    }
    sse.sendDone()
})

server.run()  // 阻塞，监听端口 8080
```

**API：**
- `JsonServer(port, host!: String = "127.0.0.1")`
- `server.jsonRoute(path, handler)` — `(JsonRequest) -> JsonResponse`
- `server.sseRoute(path, handler)` — `(JsonRequest, SseSender) -> Unit`
- `server.rawRoute(path, handler)` — 底层 `(HttpContext) -> Unit`
- `JsonRequest.body / raw / method / path / headers`
- `JsonResponse.ok / error / badRequest / notFound`
- `SseSender.send / sendEvent / sendJson / sendDone / sendComment / close`

### 4. `cangstream.store` — JSON 文件持久化

```cangjie
import cangstream.json.*
import cangstream.store.*

let store = FileStore("data/config.json")
store.load()

// 读
let apiKey = store.get().pathString("api_key") ?? ""

// 整体保存
store.save(Json.obj().put("api_key", "sk-new").build())

// 部分更新
store.update({ json =>
    Json.obj()
        .put("api_key", json.pathString("api_key") ?? "")
        .put("last_used", "2026-04-11")
        .build()
})
```

**API：**
- `FileStore(path)` — 内置 `Mutex` 并发锁
- `load() / get() / save(value) / update(updater) / exists() / path()`

### 5. `cangstream.process` — 子进程执行器

```cangjie
import cangstream.process.*

let runner = ProcessRunner(timeoutSeconds: 10)
let result = runner.run("cmd", ["/c", "echo", "hello"])

if (result.isSuccess()) {
    println(result.stdout)
} else {
    println("failed (${result.exitCode}): ${result.stderr}")
}

// 便捷 shell 方法
let r = runner.runShell("git rev-parse HEAD")
```

**API：**
- `ProcessRunner(timeoutSeconds)`
- `runner.run(command, args)` — 基于 `std.process.launch + waitOutput`
- `runner.runShell(command)` — cmd /c 封装
- `ProcessResult.exitCode / stdout / stderr / timedOut / elapsedMs / isSuccess() / combinedOutput()`

---

## 🎬 示例

`examples/` 目录下 5 个独立示例：

| 文件 | 说明 |
|------|------|
| `01_json_basic.cj` | JSON 路径访问 + 链式构建基础 |
| `02_http_client.cj` | 调用 DeepSeek API（需配置 Key） |
| `03_json_server.cj` | 启动 REST + SSE 服务器 |
| `04_file_store.cj` | FileStore 持久化计数器 |
| `05_process_runner.cj` | 子进程执行 |

**运行某个示例：**
```bash
# 把示例文件复制到 src/main.cj，然后 cjpm run
cp examples/03_json_server.cj src/main.cj
cjpm run
```

默认的 `src/main.cj` 是一个集成 demo，依次演示所有 9 个模块能力。

---

## 🏗️ 项目结构

```
CangStream/
├── cjpm.toml                # 项目配置
├── README.md                # 本文档
├── CHANGELOG.md             # 版本历史
├── src/
│   ├── main.cj              # 集成 demo（9 个模块演示）
│   ├── json/
│   │   ├── JsonExt.cj       # JsonValue 扩展
│   │   └── JsonBuilder.cj   # 链式构建器
│   ├── http/
│   │   ├── JsonClient.cj    # JSON API 客户端
│   │   └── SseReader.cj     # SSE 解析器
│   ├── api/
│   │   ├── JsonServer.cj    # 主服务器
│   │   ├── JsonRequest.cj
│   │   ├── JsonResponse.cj
│   │   └── SseSender.cj
│   ├── store/
│   │   └── FileStore.cj     # 持久化
│   └── process/
│       └── ProcessRunner.cj # 子进程
├── examples/                # 独立示例
└── legacy_v0.1/             # v0.1.0 UI 框架模块（待 v1.3 重构）
```

---

## 🎯 路线图

### v1.2 — AI Agent Ready（当前版本）
- ✅ JSON 路径访问 + 链式构建
- ✅ JSON HTTP 客户端 + SSE 解析
- ✅ JSON / SSE 服务端
- ✅ 文件持久化
- ✅ 子进程执行

### v1.3 — UI + Agent 一体化（规划中）
- [ ] 重构 v0.1.0 的 UI 框架（解决循环依赖）
- [ ] 在 `CangStreamApp` 中集成 `JsonServer`
- [ ] 加入 WebSocket 支持
- [ ] 主题自定义

### v1.4 — CangBot 完整实现（规划中）
- [ ] 用 CangStream 1.3 重写 CangBot 智能体
- [ ] 验证 SDK 设计的完整性

---

## 📝 License

Apache License 2.0 — Copyright 2025 Li Qingsheng

完整许可证见 [LICENSE](LICENSE) 文件；第三方归属见 [NOTICE](NOTICE) 文件。

---

## 致谢

CangStream 1.2 由 CangBot 智能体项目驱动。
用仓颉原生重写，并把其中可复用的能力沉淀为 CangStream 框架，
让仓颉生态的每一个开发者都能轻松构建 AI 应用。

特别感谢 **浙江传媒学院桐乡研究院有限公司** 提供的研究设施、计算环境和协作支持。
详见 [NOTICE](NOTICE) 文件。

**作者**：Li Qingsheng
