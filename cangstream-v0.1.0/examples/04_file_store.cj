/*
 * =====================================================================
 *  CangStream Framework v1.2 — AI Agent Ready
 *  Module:       examples.FileStore
 *  Description:  FileStore JSON 文件持久化示例
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
 * examples/04_file_store.cj
 * FileStore：JSON 文件持久化示例
 *
 * 运行：复制此文件到 src/main.cj → cjpm run
 */
package cangstream

import cangstream.json.*
import cangstream.store.*

main() {
    let configPath = "app_config.json"
    let store = FileStore(configPath)
    store.load()

    // 首次运行：初始化配置
    if (!store.exists()) {
        store.save(Json.obj()
            .put("api_key", "sk-initial")
            .put("model", "deepseek-chat")
            .put("temperature", 0.75)
            .put("launch_count", 0)
            .build())
        println("✓ 初始化配置文件")
    }

    // 读取配置
    let current = store.get()
    let apiKey = current.pathString("api_key") ?? ""
    let model = current.pathString("model") ?? ""
    let launchCount = current.pathInt("launch_count") ?? 0

    println("API Key: ${apiKey}")
    println("Model: ${model}")
    println("已启动次数: ${launchCount}")

    // 更新启动次数
    store.update({ json =>
        Json.obj()
            .put("api_key", json.pathString("api_key") ?? "")
            .put("model", json.pathString("model") ?? "")
            .put("temperature", json.pathFloat("temperature") ?? 0.5)
            .put("launch_count", (json.pathInt("launch_count") ?? 0) + 1)
            .build()
    })

    println("✓ 启动次数 +1 → ${store.get().pathInt("launch_count") ?? 0}")
}
