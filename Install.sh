#!/bin/bash

# --- 颜色定义 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear

# --- 欢迎 Logo ---
echo -e "${CYAN}"
echo "   ██████╗  █████╗  ██████╗ ██████╗ ██████╗ ████████╗██╗   ██╗ ██████╗ "
echo "   ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔═══██╗╚══██╔══╝██║   ██║██╔═══██╗"
echo "   ██████╔╝███████║██║   ██║██║     ██║   ██║   ██║   ██║   ██║██║   ██║"
echo "   ██╔═══╝ ██╔══██║██║   ██║██║     ██║   ██║   ██║   ██║   ██║██║   ██║"
echo "   ██║     ██║  ██║╚██████╔╝╚██████╗╚██████╔╝   ██║   ╚██████╔╝╚██████╔╝"
echo "   ╚═╝     ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═════╝    ╚═╝    ╚═════╝  ╚═════╝ "
echo -e "${NC}"
echo -e "${GREEN}============ VPS 包工头 · 引路人 v1.0.3 (直连稳定版) ===========${NC}"
echo -e "${BLUE}作者：张财多 | 宗旨：让每一台小鸡都有尊严地装修${NC}"
echo -e "${GREEN}===============================================================${NC}"

# --- 第一步：地基找平 (安装 Docker) ---
echo -e "${BLUE}[1/3] 正在清理地基，安装 Docker 环境...${NC}"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
    systemctl start docker && systemctl enable docker
    echo -e "${GREEN}✅ Docker 施工完毕！${NC}"
else
    echo -e "${GREEN}✅ 检测到 Docker 已存在，地基很稳。${NC}"
fi

# --- 第二步：搬运网页家具 ---
echo -e "\n${BLUE}[2/3] 正在从图纸库搬运黑白看板...${NC}"
# 清理旧数据，确保每次都是最新的图纸
docker rm -f vps_panel 2>/dev/null
rm -rf /root/yinluren_panel
mkdir -p /root/yinluren_panel

# 从你的 GitHub 下载网页文件
curl -fsSL https://raw.githubusercontent.com/zhangcaiduo/yinluren/refs/heads/main/index.html -o /root/yinluren_panel/index.html

# --- 第三步：开通大门与展厅 ---
echo -e "\n${BLUE}[3/3] 正在点亮管理面板展厅...${NC}"
# 启动轻量级 Nginx 容器，把 9000 端口暴露给公网
docker run -d --name vps_panel \
  -p 9000:80 \
  -v /root/yinluren_panel:/usr/share/nginx/html:ro \
  --restart always \
  nginx:alpine >/dev/null 2>&1

# 暴力拆除系统自带防火墙，防止 9000 端口被拦截
ufw disable >/dev/null 2>&1
iptables -F
iptables -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# 获取本机公网 IP
IP=$(curl -s4 icanhazip.com)

echo -e "\n${GREEN}===============================================================${NC}"
echo -e "${CYAN}🎉 恭喜房主，引路人施工完毕！${NC}"
echo -e "你可以通过以下地址直接访问你的管理面板："
echo -e "${YELLOW}http://$IP:9000${NC}"
echo -e "${GREEN}===============================================================${NC}"
