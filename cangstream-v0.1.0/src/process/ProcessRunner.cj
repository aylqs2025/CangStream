/*
 * =====================================================================
 *  CangStream Framework v1.2 — AI Agent Ready
 *  Module:       process.ProcessRunner
 *  Description:  子进程执行器（带超时控制和输出捕获）
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
 * ProcessRunner.cj - 子进程执行器（带超时和输出捕获）
 *
 * 基于 std.process.launch / executeWithOutput，提供：
 * - 一站式执行：拿命令、参数 → 拿结果
 * - 超时控制：超时后强制终止
 * - 退出码 + stdout + stderr 一并返回
 *
 * 用途：
 * - 调用编译器（cjpm build）
 * - 调用系统工具（git、curl）
 * - 沙箱化执行用户代码
 *
 * 示例：
 *   import cangstream.process.*
 *   import std.collection.*
 *
 *   let runner = ProcessRunner(timeoutSeconds: 10)
 *   let result = runner.run("cmd", ["/c", "echo", "hello"])
 *
 *   if (result.isSuccess()) {
 *       println("stdout: ${result.stdout}")
 *   } else {
 *       println("failed (${result.exitCode}): ${result.stderr}")
 *   }
 */
package cangstream.process

import std.process.*
import std.time.*
// std.time 提供 Duration 和 DateTime；spawn / sleep 在 core，无需显式 import

/**
 * 子进程执行结果。
 */
public class ProcessResult {
    public let exitCode: Int64
    public let stdout: String
    public let stderr: String
    public let timedOut: Bool
    public let elapsedMs: Int64

    public init(
        exitCode: Int64,
        stdout: String,
        stderr: String,
        timedOut: Bool,
        elapsedMs: Int64
    ) {
        this.exitCode = exitCode
        this.stdout = stdout
        this.stderr = stderr
        this.timedOut = timedOut
        this.elapsedMs = elapsedMs
    }

    /**
     * 是否成功（未超时且退出码为 0）。
     */
    public func isSuccess(): Bool {
        return !timedOut && exitCode == 0
    }

    /**
     * 合并的输出（stdout + stderr）。
     */
    public func combinedOutput(): String {
        if (stderr.size == 0) {
            return stdout
        }
        if (stdout.size == 0) {
            return stderr
        }
        return stdout + "\n" + stderr
    }
}

/**
 * 子进程执行器。
 */
public class ProcessRunner {
    private let timeoutSeconds: Int64

    /**
     * 创建运行器。
     *
     * @param timeoutSeconds 命令超时秒数（默认 30 秒）
     */
    public init(timeoutSeconds!: Int64 = 30) {
        this.timeoutSeconds = timeoutSeconds
    }

    /**
     * 执行命令并返回结果。
     *
     * @param command 可执行文件路径或命令名
     * @param args 参数数组
     * @return ProcessResult，包含 exitCode/stdout/stderr/timedOut
     */
    public func run(command: String, args: Array<String>): ProcessResult {
        let startTime = currentMillis()

        try {
            // 使用 launch 创建 SubProcess，重定向 stdout/stderr 为 Pipe
            let proc = launch(
                command,
                args,
                stdOut: ProcessRedirect.Pipe,
                stdErr: ProcessRedirect.Pipe
            )

            // 用一个监督协程控制超时：超时时强制终止子进程
            let timeoutFlag = TimeoutFlag()
            let timeoutMs = timeoutSeconds * 1000
            let watchdog = spawn {
                sleep(Duration.millisecond * timeoutMs)
                if (!timeoutFlag.done) {
                    timeoutFlag.timedOut = true
                    try { proc.terminate(force: true) } catch (_) {}
                }
            }

            // waitOutput() 会同时读取 stdout/stderr 并等待进程结束
            // 这是仓颉 SubProcess 的官方一站式 API（无超时参数）
            let (exitCode, outBytes, errBytes) = proc.waitOutput()
            timeoutFlag.done = true

            let elapsed = currentMillis() - startTime
            let stdout = String.fromUtf8(outBytes)
            let stderr = String.fromUtf8(errBytes)

            if (timeoutFlag.timedOut) {
                return ProcessResult(
                    -1,
                    stdout,
                    "Process timed out after ${timeoutSeconds}s\n${stderr}",
                    true,
                    elapsed
                )
            }

            return ProcessResult(exitCode, stdout, stderr, false, elapsed)
        } catch (e: Exception) {
            let elapsed = currentMillis() - startTime
            return ProcessResult(
                -1,
                "",
                "Process error: ${e.message}",
                false,
                elapsed
            )
        }
    }


    /**
     * 在 shell 中执行命令字符串。
     * Windows 用 cmd /c，类 Unix 用 sh -c。
     *
     * 注意：command 字符串会被 shell 解析，请勿拼接不可信输入！
     */
    public func runShell(command: String): ProcessResult {
        // 简化：根据可执行文件存在与否选择 shell
        // 这里默认 Windows cmd（运行环境是 Windows），生产中可根据 OS 切换
        let args: Array<String> = ["/c", command]
        return run("cmd", args)
    }
}

/**
 * 超时标志（引用类型，可在 spawn 协程间共享）。
 */
class TimeoutFlag {
    var done: Bool = false
    var timedOut: Bool = false
}

/**
 * 当前毫秒时间戳。
 */
func currentMillis(): Int64 {
    return DateTime.now().toUnixTimeStamp().toMilliseconds()
}
