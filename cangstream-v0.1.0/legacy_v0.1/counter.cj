//***************************
//* CangStream v1.0
//* Author: Li Qingsheng
//* Organization: Zhejiang University of Media and Communications
//* Creation Date: 2025-12-15
//* Description: A Streamlit-like Web Framework for Cangjie
//* GitHub: https://github.com/aylqs2025/CangStream
//***************************
// 计数器示例
package examples

import cangstream.core.*

main() {
    let app = CangStreamApp()
    
    app.setUIBuilder({ app =>
        app.title("📊 计数器应用")
        
        let count = app.slider("选择数值", 0, 100, 50, "count")
        
        if (app.button("计算双倍", "calc_btn")) {
            app.metric("结果", "${count * 2}", "+${count}")
        }
    })
    
    app.run()
}