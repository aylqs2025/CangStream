//****************************************************************
//* CangStream Framework v1.0
//* Module: DisplayComponents
//* Author: Li Qingsheng
//* Organization: Zhejiang University of Media and Communications
//* Creation Date: 2025-12-15
//* Description: Base interface for all UI components
//****************************************************************

// 展示组件
package cangstream.components

import cangstream.core.Component
import std.time.*

// 指标卡片组件
public class MetricComponent <: Component {
    private let label: String
    private let value: String
    private let delta: String
    private let id: String
    
    public init(label: String, value: String, delta: String) {
        this.label = label
        this.value = value
        this.delta = delta
        this.id = "metric_${Duration.millisecond}"
    }
    
    public func render(): String {
        let deltaHtml = if (!delta.isEmpty()) {
            """
            <div class="metric-delta">${delta}</div>
            """
        } else { "" }
        
        return """
            <div class="cs-metric">
                <div class="metric-label">${label}</div>
                <div class="metric-value">${value}</div>
                ${deltaHtml}
            </div>
            """
    }
    
    public func getId(): String { return id }
}

// 代码展示组件
public class CodeComponent <: Component {
    private let code: String
    private let language: String
    private let id: String
    
    public init(code: String, language: String) {
        this.code = code
        this.language = language
        this.id = "code_${Duration.millisecond}"
    }
    
    public func render(): String {
        return """
            <div class="cs-code">
                <pre><code class="language-${language}">${escapeHtml(code)}</code></pre>
            </div>
            """
    }
    
    private func escapeHtml(text: String): String {
        return text.replace("&", "&amp;")
                   .replace("<", "&lt;")
                   .replace(">", "&gt;")
    }
    
    public func getId(): String { return id }
}