//***************************
//* CangStream v1.0
//* Author: Li Qingsheng
//* Organization: Zhejiang University of Media and Communications
//* Creation Date: 2025-12-15
//* Description: A Streamlit-like Web Framework for Cangjie
//* GitHub: https://github.com/aylqs2025/CangStream
//***************************
// 仪表板示例
package examples

import cangstream.core.*

main() {
    let app = CangStreamApp(8888)
    
    app.setUIBuilder({ app =>
        app.title("📊 销售数据仪表板")
        
        app.header("数据筛选")
        let threshold = app.slider("销售阈值", 0, 1000, 500, "threshold")
        
        app.header("核心指标", 2)
        app.metric("总销售额", "¥ 125,678", "+15.3%")
        app.metric("订单数量", "2,345", "+8.7%")
        
        if (threshold > 500) {
            app.text("✅ 当前阈值较高，显示优质客户数据")
            app.metric("优质客户", "187", "+12%")
        } else {
            app.text("ℹ️ 当前阈值较低，显示全部客户数据")
            app.metric("全部客户", "856", "+5%")
        }
        
        if (app.button("📥 导出报表", "export_btn")) {
            app.text("报表已生成，阈值: ${threshold}")
        }
    })
    
    app.run()
}