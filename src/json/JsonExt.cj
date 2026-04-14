/**
 * JsonExt.cj - JsonValue 路径访问扩展
 *
 * 基于 stdx.encoding.json，通过【接口扩展】机制为 JsonValue 增加便捷的路径访问方法。
 *
 * ⚠ 仓颉规范 8.6.1 限制：直接扩展跨包不导出。
 *    必须用 public interface + 接口扩展，才能让其他包通过 import 使用扩展方法。
 *
 * 支持的路径语法：
 *   - 对象字段：  "user.name"
 *   - 数组下标：  "users.0.email"
 *   - 多层嵌套：  "data.choices.0.message.content"
 *
 * 示例：
 *   import cangstream.json.*
 *   let resp = JsonValue.fromStr(httpBody)
 *   let content = resp.pathString("choices.0.message.content") ?? ""
 */
package cangstream.json

import std.convert.*
import stdx.encoding.json.*

/**
 * JsonValue 路径访问接口。
 * 通过接口扩展，让 stdx 的 JsonValue 跨包获得这些方法。
 */
public interface JsonPathExt {
    func path(p: String): ?JsonValue
    func pathString(p: String): ?String
    func pathInt(p: String): ?Int64
    func pathFloat(p: String): ?Float64
    func pathBool(p: String): ?Bool
    func has(p: String): Bool
    func pathArray(p: String): ?JsonArray
    func pathObject(p: String): ?JsonObject
}

/**
 * 为 stdx.encoding.json.JsonValue 实现 JsonPathExt 接口。
 */
extend JsonValue <: JsonPathExt {

    /**
     * 按路径访问 JsonValue。
     * @param p 点号分隔的路径，如 "a.b.0.c"。空字符串返回自身。
     */
    public func path(p: String): ?JsonValue {
        if (p.size == 0) {
            return Some(this)
        }

        let parts = p.split(".")
        var cur: JsonValue = this

        for (part in parts) {
            let idxOpt = tryParseInt(part)

            match (idxOpt) {
                case Some(idx) =>
                    // 数字段：优先尝试数组下标，否则当字符串 key 试对象访问
                    match (cur.kind()) {
                        case JsonKind.JsArray =>
                            match (cur.asArray().get(idx)) {
                                case Some(v) => cur = v
                                case None => return None
                            }
                        case JsonKind.JsObject =>
                            match (cur.asObject().get(part)) {
                                case Some(v) => cur = v
                                case None => return None
                            }
                        case _ => return None
                    }
                case None =>
                    // 字符串段：必须是对象访问
                    match (cur.kind()) {
                        case JsonKind.JsObject =>
                            match (cur.asObject().get(part)) {
                                case Some(v) => cur = v
                                case None => return None
                            }
                        case _ => return None
                    }
            }
        }

        return Some(cur)
    }

    public func pathString(p: String): ?String {
        match (this.path(p)) {
            case Some(v) =>
                match (v.kind()) {
                    case JsonKind.JsString => Some(v.asString().getValue())
                    case _ => None
                }
            case None => None
        }
    }

    public func pathInt(p: String): ?Int64 {
        match (this.path(p)) {
            case Some(v) =>
                match (v.kind()) {
                    case JsonKind.JsInt => Some(v.asInt().getValue())
                    case JsonKind.JsFloat => Some(Int64(v.asFloat().getValue()))
                    case _ => None
                }
            case None => None
        }
    }

    public func pathFloat(p: String): ?Float64 {
        match (this.path(p)) {
            case Some(v) =>
                match (v.kind()) {
                    case JsonKind.JsFloat => Some(v.asFloat().getValue())
                    case JsonKind.JsInt => Some(Float64(v.asInt().getValue()))
                    case _ => None
                }
            case None => None
        }
    }

    public func pathBool(p: String): ?Bool {
        match (this.path(p)) {
            case Some(v) =>
                match (v.kind()) {
                    case JsonKind.JsBool => Some(v.asBool().getValue())
                    case _ => None
                }
            case None => None
        }
    }

    public func has(p: String): Bool {
        match (this.path(p)) {
            case Some(_) => true
            case None => false
        }
    }

    public func pathArray(p: String): ?JsonArray {
        match (this.path(p)) {
            case Some(v) =>
                match (v.kind()) {
                    case JsonKind.JsArray => Some(v.asArray())
                    case _ => None
                }
            case None => None
        }
    }

    public func pathObject(p: String): ?JsonObject {
        match (this.path(p)) {
            case Some(v) =>
                match (v.kind()) {
                    case JsonKind.JsObject => Some(v.asObject())
                    case _ => None
                }
            case None => None
        }
    }
}

/**
 * 尝试解析整数，失败返回 None（不抛异常）。
 */
func tryParseInt(s: String): ?Int64 {
    if (s.size == 0) {
        return None
    }
    try {
        return Some(Int64.parse(s))
    } catch (e: Exception) {
        return None
    }
}
