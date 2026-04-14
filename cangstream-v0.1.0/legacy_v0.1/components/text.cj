//****************************************************************
//* CangStream Framework v1.0
//* Module: TextComponents
//* Author: Li Qingsheng
//* Organization: Zhejiang University of Media and Communications
//* Creation Date: 2025-12-15
//* Description: Base interface for all UI components
//****************************************************************
// 文本展示组件
package cangstream.components

import cangstream.core.Component
import std.time.*

// 标题组件
public class TitleComponent <: Component {
    private let text: String
    private let id: String
    
    public init(text: String) {
        this.text = text
        this.id = "title_${Duration.millisecond}"
    }
    
    public func render(): String {
        return """
            <div class="title">
                <h1>${text}</h1>
            </div>
            """
    }
    
    public func getId(): String { return id }
}

// 标题组件
public class HeaderComponent <: Component {
    private let text: String
    private let level: Int64
    private let id: String
    
    public init(text: String, level: Int64) {
        this.text = text
        this.level = level
        this.id = "header_${Duration.millisecond}"
    }
    
    public func render(): String {
        return """
            <div class="header">
                <h${level}>${text}</h${level}>
            </div>
            """
    }
    
    public func getId(): String { return id }
}

// 文本组件
public class TextComponent <: Component {
    private let text: String
    private let id: String
    
    public init(text: String) {
        this.text = text
        this.id = "text_${Duration.millisecond}"
    }
    
    public func render(): String {
        return """
            <div class="text">
                <p>${text}</p>
            </div>
            """
    }
    
    public func getId(): String { return id }
}