#!/bin/bash
# 微博热点监控工具 - 启动脚本（systemd 不可用环境）

set -e

echo "🚀 启动微博热点监控工具..."

# 项目目录
PROJECT_DIR="/workspace/projects/weibo-hot-monitor"
BACKEND_DIR="$PROJECT_DIR/backend"
PID_FILE="/tmp/weibo-hot-monitor.pid"

# 检查是否已在运行
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "⚠️ 服务已在运行 (PID: $OLD_PID)"
        echo "📝 访问地址: http://172.22.196.16:5001/"
        exit 0
    fi
fi

# 检查 Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 未安装"
    exit 1
fi

echo "📦 检查依赖..."
cd "$BACKEND_DIR"
pip3 install -r requirements.txt -q

echo "🔧 启动服务..."
cd "$BACKEND_DIR"

# 使用 gunicorn 启动（后台运行）
if command -v gunicorn &> /dev/null; then
    gunicorn -w 2 -b 0.0.0.0:5001 app:app --daemon --pid "$PID_FILE" --access-logfile /var/log/weibo-monitor-access.log --error-logfile /var/log/weibo-monitor-error.log
else
    # 如果没有 gunicorn，使用 flask 内置服务器（仅用于开发）
    echo "⚠️ Gunicorn 未安装，使用 Flask 开发服务器（不推荐生产环境）"
    nohup python3 app.py > /var/log/weibo-monitor.log 2>&1 &
    echo $! > "$PID_FILE"
fi

echo "✅ 服务已启动！"
echo "📊 访问地址: http://172.22.196.16:5001/"
echo "📝 PID: $(cat $PID_FILE)"
echo ""
echo "📋 常用命令:"
echo "  停止服务: kill $(cat $PID_FILE)"
echo "  查看日志: tail -f /var/log/weibo-monitor*.log"
