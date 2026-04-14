/*
 * =====================================================================
 *  CangStream Framework v1.2 — AI Agent Ready
 *  Module:       examples.JsonServer
 *  Description:  JSON API + SSE 服务器示例
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
 * examples/03_json_server.cj
 * JsonServer：JSON API + SSE 服务器示例
 *
 * 运行：复制此文件到 src/main.cj → cjpm run
 *   服务器监听 http://127.0.0.1:8080
 *
 * 测试：
 *   curl http://127.0.0.1:8080/
 *   curl -X POST http://127.0.0.1:8080/api/calc -d '{"a":3,"b":4}'
 *   curl http://127.0.0.1:8080/api/stream
 */
package cangstream

import cangstream.json.*
import cangstream.api.*

main() {
    let server = JsonServer(8080)

    // 首页：返回服务器信息
    server.jsonRoute("/", { _: JsonRequest =>
        return JsonResponse.ok(Json.obj()
            .put("name", "CangStream 1.2 Demo")
            .put("version", "1.2.0")
            .put("endpoints", Json.arr()
                .add("POST /api/calc - 计算 a+b, a*b")
                .add("GET  /api/stream - SSE 心跳流")
                .build())
            .build())
    })

    // 计算器：POST /api/calc
    server.jsonRoute("/api/calc", { req: JsonRequest =>
        let a = req.body.pathInt("a") ?? 0
        let b = req.body.pathInt("b") ?? 0
        return JsonResponse.ok(Json.obj()
            .put("a", a)
            .put("b", b)
            .put("sum", a + b)
            .put("product", a * b)
            .build())
    })

    // SSE 流：GET /api/stream
    server.sseRoute("/api/stream", { _: JsonRequest, sse: SseSender =>
        for (i in 1..=10) {
            sse.sendJson(Json.obj()
                .put("tick", i)
                .put("message", "心跳 ${i}")
                .build())
        }
        sse.sendDone()
    })

    server.run()
}
