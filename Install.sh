#!/bin/bash

# --- 颜色定义 ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

clear
echo -e "${GREEN}============ VPS 包工头 · 引路人 v1.0.2 (IP直连版) ==============${NC}"

# --- 1. 安装 Docker ---
echo -e "${BLUE}[1/3] 正在准备 Docker 地基...${NC}"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
    systemctl start docker && systemctl enable docker
else
    echo -e "${GREEN}✅ Docker 已就位。${NC}"
fi

# --- 2. 准备网页家具 ---
echo -e "\n${BLUE}[2/3] 正在从 GitHub 搬运黑白看板图纸...${NC}"
docker rm -f vps_panel 2>/dev/null
mkdir -p /root/yinluren_panel

# 下载你的 index.html
curl -L https://raw.githubusercontent.com/zhangcaiduo/yinluren/refs/heads/main/index.html -o /root/yinluren_panel/index.html

# --- 3. 启动面板 ---
echo -e "\n${BLUE}[3/3] 正在点亮管理面板...${NC}"
docker run -d --name vps_panel \
  -p 9000:80 \
  -v /root/yinluren_panel:/usr/share/nginx/html:ro \
  --restart always \
  nginx:alpine

# 暴力拆除防火墙拦截
ufw disable 2>/dev/null
iptables -F

# 获取公网 IP
IP=$(curl -s4 icanhazip.com)

echo -e "\n${GREEN}===============================================================${NC}"
echo -e "🎉 施工完毕！请在浏览器访问以下地址："
echo -e "${YELLOW}http://$IP:9000${NC}"
echo -e "\n${BLUE}提示：这是本地直连模式，不消耗 Cloudflare 流量。${NC}"
echo -e "${GREEN}===============================================================${NC}"
