//***************************
//* CangStream v1.0
//* Author: Li Qingsheng
//* Organization: Zhejiang University of Media and Communications
//* Creation Date: 2025-12-15
//* Description: A Streamlit-like Web Framework for Cangjie
//* GitHub: https://github.com/aylqs2025/CangStream
//***************************
// Hello World 示例
package examples

import cangstream.core.*

main() {
    let app = CangStreamApp()
    
    app.setUIBuilder({ app =>
        app.title("🎉 Hello CangStream")
        app.text("这是我的第一个仓颉 Web 应用！")
    })
    
    app.run()
}