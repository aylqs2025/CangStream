# CangStream v1.2

> 🌐 **仓穹——源自仓颉，广阔如穹的 Web 框架与 AI Agent 基础设施**

<div align="center">

![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=for-the-badge)
![Cangjie](https://img.shields.io/badge/Cangjie-1.0.5-green.svg?style=for-the-badge)
![Version](https://img.shields.io/badge/Version-1.2.0-orange.svg?style=for-the-badge)

**基于仓颉原生语言构建的全栈 Web & AI Agent 框架**

</div>

---

## ✨ 简介

**CangStream**（中文名：仓穹）是一个完全使用华为仓颉（Cangjie）编程语言实现的 Web 框架与 AI Agent 基础设施，面向 AI 时代的智能应用开发。

v1.2 在 v0.1.0 的基础上，围绕 AI Agent 的典型需求（JSON 驱动、LLM 调用、SSE 流式推送、本地持久化、外部进程沙箱）全面重构，提供五大核心模块。

## 🧱 五大模块

| 模块 | 功能 | 代表 API |
|------|------|---------|
| **json** | JsonValue 路径访问 + 链式构造器 | `val.pathString("a.b")` / `Json.obj().put(...).build()` |
| **http** | 封装 stdx HttpClient 的 JSON 客户端 | `JsonClient.post(url, body)` + SSE 流读取 |
| **api** | Web 服务路由（JSON / SSE / Raw）| `jsonRoute` / `sseRoute` / `rawRoute` |
| **store** | 带互斥锁的 JSON 文件持久化 | `FileStore.load()` / `save()` |
| **process** | 带超时看门狗的子进程执行器 | `ProcessRunner.run(cmd, timeoutMs)` |

## 🚀 为什么选 CangStream

- ✅ **仓颉原生**：零 C/C++ 粘合，纯仓颉实现
- ✅ **AI Agent Ready**：JSON + SSE + LLM 调用 + 沙箱一应俱全
- ✅ **零第三方依赖**：只依赖仓颉 std 与 stdx
- ✅ **生产验证**：已支撑 CangBot 等在线应用

## 🛠️ 快速开始

### 前置条件

- 仓颉 SDK 1.0.5（或兼容版本）
- Cangjie stdx 扩展库

### 编译

```bash
cjpm build -o cangstream
```

### 运行示例

示例代码位于 [examples/](examples/) 目录。

## 📚 目录结构

```
cangstream-1.2/
├── LICENSE                    Apache 2.0
├── NOTICE                     第三方归属声明
├── README.md                  本文档
├── cjpm.toml                  包配置
├── src/
│   ├── json/                  JSON 扩展
│   ├── http/                  HTTP 客户端 + SSE
│   ├── api/                   Web 服务
│   ├── store/                 文件存储
│   ├── process/               子进程
│   └── main.cj                入口
├── examples/                  示例程序
├── test/                      测试
└── cangstream-v0.1.0/         v0.1.0 历史版本存档
```

## 📝 License

Apache License 2.0 — Copyright 2025 Li Qingsheng

详见 [LICENSE](LICENSE) 与 [NOTICE](NOTICE)。

## 🙏 致谢

- **华为仓颉团队** — 提供仓颉编程语言与 stdx 扩展库
- **浙江传媒学院汉字文化计算团队** — 提供研究场景与验证环境

---

<div align="center">

**仓颉为体，仓穹为用** 🌌

</div>
