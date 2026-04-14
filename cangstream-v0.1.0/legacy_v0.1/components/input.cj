//****************************************************************
//* CangStream Framework v1.0
//* Module: LayoutComponents
//* Author: Li Qingsheng
//* Organization: Zhejiang University of Media and Communications
//* Creation Date: 2025-12-15
//* Description: Base interface for all UI components
//****************************************************************
// 输入组件
package cangstream.components

import cangstream.core.Component
import std.time.*

// 按钮组件
public class ButtonComponent <: Component {
    private let label: String
    private let id: String
    private let key: String
    
    public init(label: String, key: String) {
        this.label = label
        this.key = key
        this.id = this.key
    }
    
    public func render(): String {
        return """
            <button class="cs-button" onclick="handleClick('${key}')">
                ${label}
            </button>
            """
    }
    
    public func getId(): String { return id }
}

// 文本输入框组件
public class TextInputComponent <: Component {
    private let label: String
    private let value: String
    private let key: String
    private let id: String
    
    public init(label: String, value: String, key: String) {
        this.label = label
        this.value = value
        this.key = key
        this.id = this.key
    }
    
    public func render(): String {
        return """
            <div class="cs-input-group">
                <label>${label}</label>
                <input type="text" 
                       id="${key}" 
                       value="${value}" 
                       onchange="handleInput('${key}', this.value)">
            </div>
            """
    }
    
    public func getId(): String { return id }
}

// 滑动条组件
public class SliderComponent <: Component {
    private let label: String
    private let min: Int64
    private let max: Int64
    private let value: Int64
    private let key: String
    private let id: String
    
    public init(label: String, min: Int64, max: Int64, value: Int64, key: String) {
        this.label = label
        this.min = min
        this.max = max
        this.value = value
        this.key = key
        this.id = this.key
    }
    
    public func render(): String {
        return """
            <div class="cs-slider-group">
                <label>${label}: <span id="${key}_value">${value}</span></label>
                <input type="range" 
                       id="${key}" 
                       min="${min}" 
                       max="${max}" 
                       value="${value}"
                       oninput="document.getElementById('${key}_value').textContent=this.value; handleInput('${key}', this.value)">
            </div>
            """
    }
    
    public func getId(): String { return id }
}