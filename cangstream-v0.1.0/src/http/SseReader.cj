/*
 * =====================================================================
 *  CangStream Framework v1.2 — AI Agent Ready
 *  Module:       http.SseReader
 *  Description:  SSE 事件流解析器（Server-Sent Events）
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
 * SseReader.cj - Server-Sent Events 事件流解析器
 *
 * 从 InputStream 持续读取，按 SSE 协议（RFC 8895）解析事件并通过回调输出。
 *
 * SSE 格式：
 *   data: {"choices":[{"delta":{"content":"hello"}}]}
 *   data: {"choices":[{"delta":{"content":" world"}}]}
 *   data: [DONE]
 *
 * 每个事件以空行（\n\n）分隔，每行可能是 data:、event:、id:、retry: 之一。
 *
 * 用途：解析 DeepSeek / OpenAI / Claude 等 LLM 的流式响应。
 */
package cangstream.http

import std.collection.*
import std.convert.*
import std.io.*
import stdx.encoding.json.*

// 字符的 UTF-8 字节常量（避免 String[i] 返回 UInt8 与 Rune 比较不能编译）
const BYTE_LF: UInt8 = 10           // '\n'
const BYTE_CR: UInt8 = 13           // '\r'
const BYTE_SPACE: UInt8 = 32        // ' '
const BYTE_COLON: UInt8 = 58        // ':'

/**
 * 单个 SSE 事件。
 */
public class SseEvent {
    public let event: String      // event: 字段，默认 "message"
    public let data: String       // data: 字段（可能多行拼接）
    public let id: String         // id: 字段，默认 ""
    public let retry: Int64       // retry: 字段，默认 -1

    public init(event: String, data: String, id: String, retry: Int64) {
        this.event = event
        this.data = data
        this.id = id
        this.retry = retry
    }

    /**
     * 把 data 字段解析为 JsonValue。失败返回 None。
     */
    public func parseJson(): ?JsonValue {
        if (data.size == 0) {
            return None
        }
        try {
            return Some(JsonValue.fromStr(data))
        } catch (e: Exception) {
            return None
        }
    }

    /**
     * 是否为流结束标记（OpenAI/DeepSeek 约定 data: [DONE]）。
     */
    public func isDone(): Bool {
        return data == "[DONE]"
    }
}

/**
 * SSE 事件读取器。
 */
public class SseReader {

    /**
     * 从 InputStream 持续读取并解析 SSE 事件。
     *
     * @param stream 响应体输入流
     * @param onEvent 事件回调，返回 false 则中断读取
     */
    public static func read(stream: InputStream, onEvent: (SseEvent) -> Bool): Unit {
        let parser = SseParser()
        let bufSize = 4096

        while (true) {
            let buf = Array<UInt8>(bufSize, repeat: 0)
            let n = stream.read(buf)
            if (n <= 0) {
                break
            }
            // 把读到的字节追加到解析器
            let chunk = String.fromUtf8(buf.slice(0, n).toArray())
            parser.feed(chunk)

            // 提取所有完整事件
            while (true) {
                match (parser.nextEvent()) {
                    case Some(ev) =>
                        if (!onEvent(ev)) {
                            return
                        }
                    case None => break
                }
            }
        }

        // 流结束时再尝试输出剩余数据（可能有未以空行结尾的最后一个事件）
        match (parser.flush()) {
            case Some(ev) =>
                onEvent(ev)
                ()
            case None => ()
        }
    }
}

/**
 * SSE 流解析器（内部状态机）。
 *
 * 维护一个累积缓冲，每次 feed 后从中切分出完整事件（以 \n\n 分隔）。
 */
class SseParser {
    private var buffer: String

    init() {
        this.buffer = ""
    }

    /**
     * 追加新数据到缓冲。
     */
    func feed(chunk: String): Unit {
        this.buffer = this.buffer + chunk
    }

    /**
     * 尝试从缓冲中切出一个完整事件（以 \n\n 结尾）。
     * 没有完整事件则返回 None。
     */
    func nextEvent(): ?SseEvent {
        // 查找事件分隔符 \n\n
        let sepIdx = findDoubleNewline(this.buffer)
        if (sepIdx < 0) {
            return None
        }

        // 切出事件块
        let block = this.buffer[0..sepIdx]
        // 移除已消费的部分（包括 \n\n）
        this.buffer = this.buffer[sepIdx + 2..]

        return Some(parseBlock(block))
    }

    /**
     * 流结束时调用，把缓冲中剩余的内容当作一个事件输出。
     */
    func flush(): ?SseEvent {
        let trimmed = trimRight(this.buffer)
        if (trimmed.size == 0) {
            return None
        }
        let ev = parseBlock(trimmed)
        this.buffer = ""
        return Some(ev)
    }

    /**
     * 解析单个事件块（多行 key:value）为 SseEvent。
     */
    private func parseBlock(block: String): SseEvent {
        var event = "message"
        var dataLines = ArrayList<String>()
        var id = ""
        var retry: Int64 = -1

        let lines = block.split("\n")
        for (rawLine in lines) {
            let line = trimRight(rawLine)
            if (line.size == 0) {
                continue
            }
            // 注释行（以 : 开头）
            if (line[0] == BYTE_COLON) {
                continue
            }
            // 查找冒号
            let colonIdx = indexOfByte(line, BYTE_COLON)
            var field: String
            var value: String
            if (colonIdx < 0) {
                field = line
                value = ""
            } else {
                field = line[0..colonIdx]
                value = line[(colonIdx + 1)..]
                // 去掉值前的单个空格（SSE 规范）
                if (value.size > 0 && value[0] == BYTE_SPACE) {
                    value = value[1..]
                }
            }

            if (field == "event") {
                event = value
            } else if (field == "data") {
                dataLines.add(value)
            } else if (field == "id") {
                id = value
            } else if (field == "retry") {
                try {
                    retry = Int64.parse(value)
                } catch (e: Exception) {
                    ()
                }
            }
        }

        // 多行 data 用 \n 连接
        let data = joinLines(dataLines)
        return SseEvent(event, data, id, retry)
    }
}

// ========== 字符串辅助函数 ==========

/**
 * 在字符串中查找 \n\n 的位置。
 * 找不到返回 -1。
 */
func findDoubleNewline(s: String): Int64 {
    let n = s.size
    if (n < 2) {
        return -1
    }
    var i = 0
    while (i < n - 1) {
        if (s[i] == BYTE_LF && s[i + 1] == BYTE_LF) {
            return i
        }
        i++
    }
    return -1
}

/**
 * 在字符串中查找首个指定字节的位置。
 */
func indexOfByte(s: String, c: UInt8): Int64 {
    var i = 0
    while (i < s.size) {
        if (s[i] == c) {
            return i
        }
        i++
    }
    return -1
}

/**
 * 去除字符串右侧的 \r 和 \n。
 */
func trimRight(s: String): String {
    var end = s.size
    while (end > 0) {
        let c = s[end - 1]
        if (c == BYTE_LF || c == BYTE_CR) {
            end--
        } else {
            break
        }
    }
    if (end == s.size) {
        return s
    }
    return s[0..end]
}

/**
 * 用 \n 连接字符串列表。
 */
func joinLines(lines: ArrayList<String>): String {
    if (lines.size == 0) {
        return ""
    }
    var result = lines[0]
    var i = 1
    while (i < lines.size) {
        result = result + "\n" + lines[i]
        i++
    }
    return result
}
