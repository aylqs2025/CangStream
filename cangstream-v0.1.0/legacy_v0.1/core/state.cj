//****************************************************************
//* CangStream Framework v1.0
//* Module: SessionState - Application State Management
//* Author: Li Qingsheng
//* Organization: Zhejiang University of Media and Communications
//* Creation Date: 2025-12-15
//* Description: Thread-safe state management with mutex protection
//****************************************************************

// 状态管理
package cangstream.core

import std.collection.*
import std.sync.*

public class SessionState {
    private var data: HashMap<String, String>
    private let mtx: Mutex
    
    public init() {
        data = HashMap<String, String>()
        mtx = Mutex()
    }
    
    public func get(key: String): Option<String> {
        mtx.lock()
        let result = data.get(key)
        mtx.unlock()
        return result
    }
    
    public func get(key: String, default: String): String {
        mtx.lock()
        let result = match (data.get(key)) {
            case Some(v) => v
            case None => default
        }
        mtx.unlock()
        return result
    }
    
    public func set(key: String, value: String) {
        mtx.lock()
        data[key] = value
        mtx.unlock()
    }
    
    public func clear() {
        mtx.lock()
        data.clear()
        mtx.unlock()
    }
}