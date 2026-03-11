# 微博热点监控工具

实时监控微博热搜榜，每分钟自动更新。

## 功能特性

- 🔥 实时抓取微博热搜榜单
- 📊 热度趋势分析
- 🔄 每分钟自动更新
- 🌐 Web 可视化界面
- 📱 响应式设计

## 技术栈

- **后端**: Python + Flask + APScheduler
- **前端**: HTML5 + CSS3 + JavaScript
- **部署**: Gunicorn + Nginx

## API 接口

- `GET /api/hot` - 获取当前热点列表
- `GET /api/hot/<rank>` - 获取指定排名的热点详情

## 部署地址

http://172.22.196.16:5001/
