//****************************************************************
//* CangStream Framework v1.0
//* Module: CangStreamApp - Main Application Class
//* Author: Li Qingsheng
//* Organization: Zhejiang University of Media and Communications
//* Creation Date: 2025-12-15
//* Description: Core application class managing UI, state, and server
//****************************************************************
// CangStream 主应用类
package cangstream.core

import std.collection.*
import std.convert.*
import stdx.net.http.*
import cangstream.components.*
import cangstream.server.*

public class CangStreamApp {
    private var components: ArrayList<Component>
    private let state: SessionState
    private let port: Int64
    private var buildUI: (CangStreamApp) -> Unit
    private var serverManager: HttpServerManager
    
    public init() {
        this.components = ArrayList<Component>()
        this.state = SessionState()
        this.port = 8080
        this.buildUI = { app => }
        this.serverManager = HttpServerManager(this.port)
    }
    
    public init(port: Int64) {
        this.components = ArrayList<Component>()
        this.state = SessionState()
        this.port = port
        this.buildUI = { app => }
        this.serverManager = HttpServerManager(port)
    }
    
    // 设置 UI 构建函数
    public func setUIBuilder(builder: (CangStreamApp) -> Unit) {
        this.buildUI = builder
    }
    
    // 重新构建 UI
    private func rebuildUI() {
        components.clear()
        buildUI(this)
    }
    
    // ==================== UI 构建方法 ====================
    
    public func title(text: String) {
        components.add(TitleComponent(text))
    }
    
    public func header(text: String) {
        components.add(HeaderComponent(text, 2))
    }
    
    public func header(text: String, level: Int64) {
        components.add(HeaderComponent(text, level))
    }
    
    public func text(text: String) {
        components.add(TextComponent(text))
    }
    
    public func button(label: String, key: String): Bool {
        components.add(ButtonComponent(label, key))
        let clicked = state.get("${key}_clicked", "false")
        state.set("${key}_clicked", "false")
        return clicked == "true"
    }
    
    public func textInput(label: String, value: String, key: String): String {
        let currentValue = state.get(key, value)
        components.add(TextInputComponent(label, currentValue, key))
        return currentValue
    }
    
    public func slider(label: String, min: Int64, max: Int64, value: Int64, key: String): Int64 {
        var currentValue = value
        let storedValue = state.get(key, value.toString())
        
        try {
            currentValue = Int64.parse(storedValue)
        } catch (e: Exception) {
            currentValue = value
        }
        
        components.add(SliderComponent(label, min, max, currentValue, key))
        return currentValue
    }
    
    public func metric(label: String, value: String) {
        components.add(MetricComponent(label, value, ""))
    }
    
    public func metric(label: String, value: String, delta: String) {
        components.add(MetricComponent(label, value, delta))
    }
    
    public func code(code: String) {
        components.add(CodeComponent(code, "cangjie"))
    }
    
    public func code(code: String, language: String) {
        components.add(CodeComponent(code, language))
    }
    
    public func columns(count: Int64): ArrayList<ColumnContext> {
        var cols = ArrayList<ColumnContext>()
        for (i in 0..count) {
            cols.add(ColumnContext(this, i))
        }
        return cols
    }
    
    // ==================== 渲染方法 ====================
    
    private func renderPage(): String {
        var html = ""
        
        html += getHTMLHeader()
        html += "<div class='container'>"
        
        for (component in components) {
            html += component.render()
        }
        
        html += "</div>"
        html += getHTMLFooter()
        
        return html
    }
    
    private func getHTMLHeader(): String {
        return """
            <!DOCTYPE html>
            <html lang="zh-CN">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>CangStream App</title>
                <style>
                    * { margin: 0; padding: 0; box-sizing: border-box; }
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        min-height: 100vh;
                        padding: 20px;
                    }
                    .container {
                        max-width: 1200px;
                        margin: 0 auto;
                        background: white;
                        border-radius: 12px;
                        padding: 40px;
                        box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                    }
                    .title h1 {
                        color: #667eea;
                        font-size: 2.5em;
                        margin-bottom: 20px;
                        font-weight: 700;
                    }
                    .header h2 { color: #333; margin: 30px 0 15px; font-size: 1.8em; }
                    .header h3 { color: #555; margin: 25px 0 12px; font-size: 1.4em; }
                    .text p { color: #666; line-height: 1.8; margin: 10px 0; font-size: 1.05em; }
                    .cs-button {
                        background: linear-gradient(135deg, #667eea, #764ba2);
                        color: white;
                        border: none;
                        padding: 12px 30px;
                        border-radius: 8px;
                        cursor: pointer;
                        font-size: 16px;
                        font-weight: 600;
                        margin: 10px 5px;
                        transition: all 0.3s ease;
                        box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
                    }
                    .cs-button:hover {
                        transform: translateY(-2px);
                        box-shadow: 0 6px 20px rgba(102, 126, 234, 0.6);
                    }
                    .cs-input-group, .cs-slider-group {
                        margin: 20px 0;
                    }
                    .cs-input-group label, .cs-slider-group label {
                        display: block;
                        margin-bottom: 8px;
                        color: #333;
                        font-weight: 600;
                    }
                    .cs-input-group input[type="text"] {
                        width: 100%;
                        padding: 12px;
                        border: 2px solid #e0e0e0;
                        border-radius: 8px;
                        font-size: 16px;
                        transition: border-color 0.3s;
                    }
                    .cs-input-group input[type="text"]:focus {
                        outline: none;
                        border-color: #667eea;
                    }
                    .cs-slider-group input[type="range"] {
                        width: 100%;
                        height: 6px;
                        border-radius: 3px;
                        background: #e0e0e0;
                        outline: none;
                    }
                    .cs-slider-group input[type="range"]::-webkit-slider-thumb {
                        appearance: none;
                        width: 20px;
                        height: 20px;
                        border-radius: 50%;
                        background: #667eea;
                        cursor: pointer;
                    }
                    .cs-metric {
                        background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
                        padding: 20px;
                        border-radius: 10px;
                        margin: 15px 0;
                        text-align: center;
                    }
                    .metric-label {
                        color: #666;
                        font-size: 0.9em;
                        text-transform: uppercase;
                        letter-spacing: 1px;
                    }
                    .metric-value {
                        color: #333;
                        font-size: 2.5em;
                        font-weight: 700;
                        margin: 10px 0;
                    }
                    .metric-delta {
                        color: #10b981;
                        font-weight: 600;
                    }
                    .cs-code {
                        background: #1e1e1e;
                        border-radius: 8px;
                        padding: 20px;
                        margin: 15px 0;
                        overflow-x: auto;
                    }
                    .cs-code pre {
                        margin: 0;
                    }
                    .cs-code code {
                        color: #d4d4d4;
                        font-family: 'Consolas', 'Monaco', monospace;
                        font-size: 14px;
                        line-height: 1.6;
                    }
                </style>
            </head>
            <body>
            """
    }
    
    private func getHTMLFooter(): String {
        return """
                <script>
                    function handleClick(key) {
                        fetch('/action', {
                            method: 'POST',
                            headers: {'Content-Type': 'application/json'},
                            body: JSON.stringify({type: 'click', key: key})
                        }).then(() => location.reload());
                    }
                    
                    function handleInput(key, value) {
                        fetch('/action', {
                            method: 'POST',
                            headers: {'Content-Type': 'application/json'},
                            body: JSON.stringify({type: 'input', key: key, value: value})
                        });
                    }
                </script>
            </body>
            </html>
            """
    }
    
    // ==================== HTTP 服务器 ====================
    
    public func run() {
        // 注册主页路由
        serverManager.registerRoute("/", { httpContext =>
            rebuildUI()
            let html = renderPage()
            httpContext.responseBuilder
                .status(200)
                .header("Content-Type", "text/html; charset=utf-8")
                .body(html)
        })
        
        // 注册 action 路由
        serverManager.registerRoute("/action", { httpContext =>
            handleAction(httpContext)
            httpContext.responseBuilder
                .status(200)
                .header("Content-Type", "application/json")
                .body("{\"status\":\"ok\"}")
        })
        
        // 启动服务
        serverManager.start()
    }
    
    private func handleAction(httpContext: HttpContext) {
        let buffer = Array<UInt8>(4096, item: 0)
        let length = httpContext.request.body.read(buffer)
        
        if (length > 0) {
            let body = String.fromUtf8(buffer[0..length])
            
            if (body.contains("\"type\":\"click\"")) {
                processClickAction(body)
            } else if (body.contains("\"type\":\"input\"")) {
                processInputAction(body)
            }
        }
    }
    
    private func processClickAction(body: String) {
        let keyStartOpt = body.indexOf("\"key\":\"")
        match (keyStartOpt) {
            case Some(keyStart) => 
                state.set("${extractJsonValue(body, keyStart + 7)}_clicked", "true")
            case None => 
                ()
        }
    }
    
    private func processInputAction(body: String) {
        let keyStartOpt = body.indexOf("\"key\":\"")
        let valueStartOpt = body.indexOf("\"value\":\"")
        
        match (keyStartOpt) {
            case Some(keyStart) => 
                match (valueStartOpt) {
                    case Some(valueStart) => 
                        state.set(
                            extractJsonValue(body, keyStart + 7),
                            extractJsonValue(body, valueStart + 9)
                        )
                    case None => 
                        ()
                }
            case None => 
                ()
        }
    }
}