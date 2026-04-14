/**
 * JsonBuilder.cj - JSON 链式构建器
 *
 * 提供 Json.obj() / Json.arr() 工厂方法和流畅的 put/add 链式 API，
 * 比手动 new JsonObject + put 更简洁。
 *
 * 示例：
 *   let body = Json.obj()
 *       .put("model", "deepseek-chat")
 *       .put("temperature", 0.75)
 *       .put("messages", Json.arr()
 *           .add(Json.obj().put("role", "system").put("content", sysPrompt).build())
 *           .add(Json.obj().put("role", "user").put("content", userMsg).build())
 *           .build())
 *       .toString()
 */
package cangstream.json

import stdx.encoding.json.*

/**
 * JSON 工厂入口。
 */
public class Json {
    /**
     * 创建 JSON 对象构建器。
     */
    public static func obj(): JsonObjBuilder {
        return JsonObjBuilder()
    }

    /**
     * 创建 JSON 数组构建器。
     */
    public static func arr(): JsonArrBuilder {
        return JsonArrBuilder()
    }

    /**
     * 包装 JsonValue.fromStr，便于统一入口。
     */
    public static func parse(s: String): JsonValue {
        return JsonValue.fromStr(s)
    }

    /**
     * 包装常用字面量构造（避免每次写 JsonString(...)）。
     */
    public static func str(v: String): JsonValue {
        return JsonString(v)
    }

    public static func int(v: Int64): JsonValue {
        return JsonInt(v)
    }

    public static func float(v: Float64): JsonValue {
        return JsonFloat(v)
    }

    public static func bool(v: Bool): JsonValue {
        return JsonBool(v)
    }

    public static func nullValue(): JsonValue {
        return JsonNull()
    }
}

/**
 * JSON 对象链式构建器。
 *
 * 所有 put 方法返回 this，支持链式调用。
 * build() 返回 JsonObject；toString() 直接序列化为字符串。
 */
public class JsonObjBuilder {
    private let obj: JsonObject

    public init() {
        this.obj = JsonObject()
    }

    public func put(key: String, value: String): JsonObjBuilder {
        obj.put(key, JsonString(value))
        return this
    }

    public func put(key: String, value: Int64): JsonObjBuilder {
        obj.put(key, JsonInt(value))
        return this
    }

    public func put(key: String, value: Float64): JsonObjBuilder {
        obj.put(key, JsonFloat(value))
        return this
    }

    public func put(key: String, value: Bool): JsonObjBuilder {
        obj.put(key, JsonBool(value))
        return this
    }

    public func put(key: String, value: JsonValue): JsonObjBuilder {
        obj.put(key, value)
        return this
    }

    /**
     * 嵌套对象的便捷方法。
     */
    public func put(key: String, value: JsonObjBuilder): JsonObjBuilder {
        obj.put(key, value.build())
        return this
    }

    /**
     * 嵌套数组的便捷方法。
     */
    public func put(key: String, value: JsonArrBuilder): JsonObjBuilder {
        obj.put(key, value.build())
        return this
    }

    /**
     * 放入 null 值。
     */
    public func putNull(key: String): JsonObjBuilder {
        obj.put(key, JsonNull())
        return this
    }

    /**
     * 完成构建，返回 JsonObject。
     */
    public func build(): JsonObject {
        return obj
    }

    /**
     * 直接序列化为紧凑 JSON 字符串。
     */
    public func toString(): String {
        return obj.toJsonString()
    }

    /**
     * 序列化为带缩进的 JSON 字符串。
     */
    public func toPrettyString(): String {
        return obj.toJsonString(0, indent: "  ")
    }
}

/**
 * JSON 数组链式构建器。
 */
public class JsonArrBuilder {
    private let arr: JsonArray

    public init() {
        this.arr = JsonArray()
    }

    public func add(value: String): JsonArrBuilder {
        arr.add(JsonString(value))
        return this
    }

    public func add(value: Int64): JsonArrBuilder {
        arr.add(JsonInt(value))
        return this
    }

    public func add(value: Float64): JsonArrBuilder {
        arr.add(JsonFloat(value))
        return this
    }

    public func add(value: Bool): JsonArrBuilder {
        arr.add(JsonBool(value))
        return this
    }

    public func add(value: JsonValue): JsonArrBuilder {
        arr.add(value)
        return this
    }

    public func add(value: JsonObjBuilder): JsonArrBuilder {
        arr.add(value.build())
        return this
    }

    public func add(value: JsonArrBuilder): JsonArrBuilder {
        arr.add(value.build())
        return this
    }

    public func addNull(): JsonArrBuilder {
        arr.add(JsonNull())
        return this
    }

    /**
     * 完成构建，返回 JsonArray。
     */
    public func build(): JsonArray {
        return arr
    }

    /**
     * 直接序列化为紧凑 JSON 字符串。
     */
    public func toString(): String {
        return arr.toJsonString()
    }

    public func toPrettyString(): String {
        return arr.toJsonString(0, indent: "  ")
    }
}
