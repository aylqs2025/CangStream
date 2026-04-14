//****************************************************************
//* CangStream Framework v1.0
//* Module: Component - UI Component Interface
//* Author: Li Qingsheng
//* Organization: Zhejiang University of Media and Communications
//* Creation Date: 2025-12-15
//* Description: Base interface for all UI components
//****************************************************************
// 组件基础接口
package cangstream.core

public interface Component {
    func render(): String
    func getId(): String
}

public enum ComponentType {
    | Title
    | Header
    | Text
    | Markdown
    | Button
    | TextInput
    | NumberInput
    | Slider
    | Selectbox
    | Checkbox
    | Radio
    | DataFrame
    | Chart
    | Image
    | Columns
    | Expander
    | Metric
    | Code
}