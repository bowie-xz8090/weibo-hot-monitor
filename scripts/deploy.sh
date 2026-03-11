#!/bin/bash
# 微博热点监控工具 - 部署脚本

set -e

echo "🚀 开始部署微博热点监控工具..."

# 项目目录
PROJECT_DIR="/workspace/projects/weibo-hot-monitor"
BACKEND_DIR="$PROJECT_DIR/backend"

# 检查 Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 未安装"
    exit 1
fi

echo "📦 安装依赖..."
cd "$BACKEND_DIR"
pip3 install -r requirements.txt -q

echo "🔧 创建 systemd 服务..."

# 创建服务文件
sudo tee /etc/systemd/system/weibo-hot-monitor.service > /dev/null <<EOF
[Unit]
Description=Weibo Hot Monitor Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$BACKEND_DIR
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
ExecStart=/usr/local/bin/gunicorn -w 2 -b 0.0.0.0:5001 app:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "🔄 启动服务..."
sudo systemctl daemon-reload
sudo systemctl enable weibo-hot-monitor.service
sudo systemctl restart weibo-hot-monitor.service

echo "✅ 部署完成！"
echo "📊 访问地址: http://172.22.196.16:5001/"
echo ""
echo "📋 常用命令:"
echo "  查看状态: sudo systemctl status weibo-hot-monitor"
echo "  停止服务: sudo systemctl stop weibo-hot-monitor"
echo "  重启服务: sudo systemctl restart weibo-hot-monitor"
echo "  查看日志: sudo journalctl -u weibo-hot-monitor -f"
