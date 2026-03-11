#!/bin/bash
# 微博热点监控工具 - 完整自动部署脚本

set -e

echo "🔥 微博热点监控工具 - 自动部署脚本"
echo "=================================="

PROJECT_DIR="/workspace/projects/weibo-hot-monitor"
BACKEND_DIR="$PROJECT_DIR/backend"
PID_FILE="/tmp/weibo-hot-monitor.pid"
LOG_DIR="/var/log"

cd "$PROJECT_DIR"

# 函数：启动服务
start_service() {
    echo "🚀 启动微博热点监控服务..."
    
    # 检查是否已在运行
    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(cat "$PID_FILE")
        if ps -p "$OLD_PID" > /dev/null 2>&1; then
            echo "⚠️ 服务已在运行 (PID: $OLD_PID)"
            echo "📊 访问地址: http://172.22.196.16:5001/"
            return 0
        fi
    fi
    
    # 安装依赖
    echo "📦 检查依赖..."
    pip3 install -r "$BACKEND_DIR/requirements.txt" --quiet 2>/dev/null || pip3 install flask requests apscheduler flask-cors gunicorn beautifulsoup4 lxml --quiet
    
    # 启动服务
    cd "$BACKEND_DIR"
    if command -v gunicorn &> /dev/null; then
        gunicorn -w 2 -b 0.0.0.0:5001 app:app --daemon --pid "$PID_FILE" \
            --access-logfile "$LOG_DIR/weibo-monitor-access.log" \
            --error-logfile "$LOG_DIR/weibo-monitor-error.log"
        echo "✅ 服务已启动 (Gunicorn)"
    else
        nohup python3 app.py > "$LOG_DIR/weibo-monitor.log" 2>&1 &
        echo $! > "$PID_FILE"
        echo "✅ 服务已启动 (Flask Dev)"
    fi
    
    echo "📊 访问地址: http://172.22.196.16:5001/"
    echo "📝 PID: $(cat $PID_FILE)"
}

# 函数：停止服务
stop_service() {
    echo "🛑 停止服务..."
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            kill "$PID" 2>/dev/null || true
        fi
        rm -f "$PID_FILE"
    fi
    # 尝试清理其他进程
    pkill -f "gunicorn.*5001" 2>/dev/null || true
    pkill -f "python.*app.py" 2>/dev/null || true
    echo "✅ 服务已停止"
}

# 函数：重启服务
restart_service() {
    stop_service
    sleep 2
    start_service
}

# 函数：查看状态
status_service() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "✅ 服务运行中 (PID: $PID)"
            echo "📊 访问地址: http://172.22.196.16:5001/"
            echo "🔄 最后更新: $(tail -1 $LOG_DIR/weibo-monitor-error.log 2>/dev/null | grep '成功更新' | tail -1)"
        else
            echo "❌ 服务未运行"
        fi
    else
        echo "❌ 服务未运行"
    fi
}

# 函数：推送到 GitHub
push_to_github() {
    echo "📤 推送到 GitHub..."
    
    # 检查远程仓库
    if ! git remote get-url origin > /dev/null 2>&1; then
        echo "⚠️ 请先创建 GitHub 仓库并添加 remote"
        echo "   仓库名: weibo-hot-monitor"
        echo "   命令: git remote add origin https://github.com/bowie-xz8090/weibo-hot-monitor.git"
        return 1
    fi
    
    git add -A
    git diff --cached --quiet || git commit -m "Update: $(date '+%Y-%m-%d %H:%M:%S')"
    git push origin main
    echo "✅ 已推送到 GitHub"
}

# 主逻辑
case "${1:-start}" in
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    restart)
        restart_service
        ;;
    status)
        status_service
        ;;
    push)
        push_to_github
        ;;
    deploy)
        restart_service
        push_to_github
        echo ""
        echo "🎉 部署完成！"
        echo "📊 服务地址: http://172.22.196.16:5001/"
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status|push|deploy}"
        echo ""
        echo "命令说明:"
        echo "  start   - 启动服务"
        echo "  stop    - 停止服务"
        echo "  restart - 重启服务"
        echo "  status  - 查看状态"
        echo "  push    - 推送到 GitHub"
        echo "  deploy  - 完整部署（重启+推送）"
        exit 1
        ;;
esac
