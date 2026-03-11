#!/usr/bin/env python3
"""
微博热点监控工具 - 后端服务
实时抓取微博热搜榜单
"""

from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS
from apscheduler.schedulers.background import BackgroundScheduler
import requests
import json
import re
import time
from datetime import datetime
from urllib.parse import quote

app = Flask(__name__)
CORS(app)

# 存储热点数据
hot_data = {
    "update_time": None,
    "items": []
}

def fetch_weibo_hot():
    """抓取微博热搜"""
    try:
        url = "https://weibo.com/ajax/side/hotSearch"
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Referer": "https://weibo.com/hot/search",
            "Accept": "application/json, text/plain, */*"
        }
        
        response = requests.get(url, headers=headers, timeout=10)
        data = response.json()
        
        items = []
        if "data" in data and "realtime" in data["data"]:
            realtime = data["data"]["realtime"]
            for i, item in enumerate(realtime[:50], 1):  # 取前50条
                hot_item = {
                    "rank": i,
                    "title": item.get("word", ""),
                    "category": item.get("category", "")
                }
                
                # 获取热度值
                if "raw_hot" in item:
                    hot_item["hot"] = item["raw_hot"]
                elif "num" in item:
                    hot_item["hot"] = item["num"]
                else:
                    hot_item["hot"] = 0
                
                # 获取链接
                if "scheme" in item:
                    hot_item["link"] = item["scheme"]
                else:
                    encoded_word = quote(item.get("word", ""))
                    hot_item["link"] = f"https://s.weibo.com/weibo?q=%23{encoded_word}%23"
                
                # 热度标签
                hot_item["tag"] = item.get("rank_desc", "")
                
                items.append(hot_item)
        
        hot_data["items"] = items
        hot_data["update_time"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{hot_data['update_time']}] 成功更新热点，共 {len(items)} 条")
        return True
        
    except Exception as e:
        print(f"抓取失败: {e}")
        return False

# 初始化时抓取一次
fetch_weibo_hot()

# 设置定时任务 - 每分钟更新
scheduler = BackgroundScheduler()
scheduler.add_job(func=fetch_weibo_hot, trigger="interval", minutes=1)
scheduler.start()

@app.route("/")
def index():
    """首页"""
    return send_from_directory("../frontend", "index.html")

@app.route("/api/hot")
def get_hot():
    """获取热点列表"""
    return jsonify({
        "code": 200,
        "message": "success",
        "data": hot_data
    })

@app.route("/api/hot/<int:rank>")
def get_hot_by_rank(rank):
    """获取指定排名的热点"""
    for item in hot_data["items"]:
        if item["rank"] == rank:
            return jsonify({
                "code": 200,
                "message": "success",
                "data": item
            })
    return jsonify({
        "code": 404,
        "message": "not found",
        "data": None
    }), 404

@app.route("/static/<path:path>")
def send_static(path):
    """静态文件"""
    return send_from_directory("../frontend/static", path)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=False)
