/*
 * =====================================================================
 *  CangStream Framework v1.2 — AI Agent Ready
 *  Module:       examples.JsonBasic
 *  Description:  JSON 路径访问 + 链式构建基础示例
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
 * examples/01_json_basic.cj
 * JSON 路径访问 + 链式构建 基础示例
 *
 * 运行：cjpm run
 *   （先把此文件复制到 src/main.cj）
 */
package cangstream

import stdx.encoding.json.*
import cangstream.json.*

main() {
    // ====== 链式构建 JSON ======
    let req = Json.obj()
        .put("model", "deepseek-chat")
        .put("temperature", 0.75)
        .put("messages", Json.arr()
            .add(Json.obj().put("role", "user").put("content", "你好")))
        .build()

    println("请求体:")
    println(req.toJsonString(0, indent: "  "))

    // ====== 路径访问 ======
    let respStr = ##"
    {
        "choices": [
            {"message": {"content": "你好！有什么可以帮你的？"}}
        ],
        "usage": {"total_tokens": 42}
    }
    "##

    let resp = Json.parse(respStr)
    let content = resp.pathString("choices.0.message.content") ?? "(空)"
    let tokens = resp.pathInt("usage.total_tokens") ?? 0

    println("\n回复: ${content}")
    println("Tokens: ${tokens}")
}
