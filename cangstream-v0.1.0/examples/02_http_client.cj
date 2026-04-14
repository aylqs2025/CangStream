/*
 * =====================================================================
 *  CangStream Framework v1.2 — AI Agent Ready
 *  Module:       examples.HttpClient
 *  Description:  JsonClient + SSE 调用 DeepSeek API 示例
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
 * examples/02_http_client.cj
 * JsonClient + SseReader 示例（调用真实 LLM API）
 *
 * 运行：设置 API_KEY 环境变量 → 复制此文件到 src/main.cj → cjpm run
 *
 * ⚠ 此示例需要真实的 DeepSeek API Key 才能运行。
 */
package cangstream

import std.collection.*
import cangstream.json.*
import cangstream.http.*

main() {
    // ====== 配置 ======
    let apiKey = "sk-YOUR-KEY-HERE"  // 替换为你的 DeepSeek Key
    let headers = HashMap<String, String>()
    headers.add("Authorization", "Bearer ${apiKey}")

    let client = JsonClient(
        "https://api.deepseek.com",
        headers,
        timeoutSeconds: 60
    )

    // ====== 普通请求 ======
    let req = Json.obj()
        .put("model", "deepseek-chat")
        .put("temperature", 0.75)
        .put("max_tokens", 500)
        .put("messages", Json.arr()
            .add(Json.obj()
                .put("role", "system")
                .put("content", "你是仓颉编程语言专家"))
            .add(Json.obj()
                .put("role", "user")
                .put("content", "用一句话介绍仓颉语言")))
        .build()

    println("→ 发送请求...")
    let resp = client.post("/v1/chat/completions", req)

    if (resp.isSuccess()) {
        let content = resp.body.pathString("choices.0.message.content") ?? "(无回复)"
        let tokens = resp.body.pathInt("usage.total_tokens") ?? 0
        println("✓ 回复: ${content}")
        println("✓ Token 用量: ${tokens}")
    } else {
        println("✗ 失败: status=${resp.status}")
        println("   ${resp.raw}")
    }

    client.close()
}
