#!/bin/bash
# 微博热点监控工具 - 停止脚本

PID_FILE="/tmp/weibo-hot-monitor.pid"

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "🛑 停止服务 (PID: $PID)..."
        kill "$PID"
        rm -f "$PID_FILE"
        echo "✅ 服务已停止"
    else
        echo "⚠️ 服务未在运行"
        rm -f "$PID_FILE"
    fi
else
    # 尝试查找并停止 gunicorn 进程
    PIDS=$(pgrep -f "gunicorn.*weibo-hot-monitor" || true)
    if [ -n "$PIDS" ]; then
        echo "🛑 停止服务..."
        kill $PIDS
        echo "✅ 服务已停止"
    else
        echo "⚠️ 服务未在运行"
    fi
fi
