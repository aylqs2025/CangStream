//****************************************************************
//* CangStream Framework v1.0
//* Module: LayoutComponents
//* Author: Li Qingsheng
//* Organization: Zhejiang University of Media and Communications
//* Creation Date: 2025-12-15
//* Description: Base interface for all UI components
//****************************************************************

// 布局组件

package cangstream.components

import std.collection.*
import cangstream.core.*

// 列上下文（用于多列布局）
public class ColumnContext {
    private let app: CangStreamApp
    private let index: Int64
    
    public init(app: CangStreamApp, index: Int64) {
        this.app = app
        this.index = index
    }
    
    public func text(content: String) {
        app.text(content)
    }
}