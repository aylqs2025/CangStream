/*
 * =====================================================================
 *  CangStream Framework v1.2 — AI Agent Ready
 *  Module:       examples.ProcessRunner
 *  Description:  ProcessRunner 子进程执行示例
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
 * examples/05_process_runner.cj
 * ProcessRunner：带超时的子进程执行示例
 *
 * 运行：复制此文件到 src/main.cj → cjpm run
 */
package cangstream

import cangstream.process.*

main() {
    let runner = ProcessRunner(timeoutSeconds: 5)

    // 测试 1：简单 echo
    println("▸ 测试 echo")
    let r1 = runner.run("cmd", ["/c", "echo", "Hello", "from", "Cangjie"])
    println("  退出码: ${r1.exitCode}")
    println("  输出: ${r1.stdout.trimAscii()}")
    println("  耗时: ${r1.elapsedMs}ms")
    println()

    // 测试 2：多命令组合
    println("▸ 测试多行输出")
    let r2 = runner.run("cmd", ["/c", "echo line1 && echo line2 && echo line3"])
    println("  输出:")
    println(r2.stdout.trimAscii())
    println()

    // 测试 3：非零退出码
    println("▸ 测试错误退出")
    let r3 = runner.run("cmd", ["/c", "exit", "42"])
    println("  退出码: ${r3.exitCode}")
    println("  成功: ${r3.isSuccess()}")
    println()

    // 测试 4：便捷 shell 方法
    println("▸ 测试 runShell")
    let r4 = runner.runShell("echo %CD%")
    println("  当前目录: ${r4.stdout.trimAscii()}")
}
