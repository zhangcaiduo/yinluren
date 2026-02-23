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
echo -e "${GREEN}============ VPS 包工头 · 引路人 v1.0.1 (修正版) ==============${NC}"
echo -e "${BLUE}作者：张财多 | 宗旨：让每一台小鸡都有尊严地装修${NC}"
echo -e "${GREEN}===============================================================${NC}"

# --- 第一步：地基找平 (Docker) ---
echo -e "${BLUE}[1/4] 正在清理地基，安装 Docker 环境...${NC}"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
    systemctl start docker && systemctl enable docker
else
    echo -e "${GREEN}✅ 检测到 Docker 已存在。${NC}"
fi

# --- 第二步：接通总线 (Cloudflare Tunnel) ---
echo -e "\n${BLUE}[2/4] 正在接通 Cloudflare Tunnel 隧道总线...${NC}"

# 彻底清理旧的 cloudflared 干扰
sudo systemctl stop cloudflared 2>/dev/null
sudo cloudflared service uninstall 2>/dev/null

# 重新配置源并安装
sudo mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared jammy main" | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt-get update
sudo apt-get install -y cloudflared

read -p "请输入你的 Tunnel Token: " TUNNEL_TOKEN
if [ -z "$TUNNEL_TOKEN" ]; then
    echo -e "${RED}错误：Token 不能为空。${NC}"
    exit 1
fi

sudo cloudflared service install "$TUNNEL_TOKEN"
sudo systemctl start cloudflared

# --- 第三步：面板子域名绑定 ---
echo -e "\n${BLUE}[3/4] 配置管理面板域名...${NC}"
read -p "请输入管理面板二级域名 (例如 yinluren.example.com): " PANEL_DOMAIN

# 写入配置文件
sudo mkdir -p /etc/cloudflared
cat <<EOF | sudo tee /etc/cloudflared/config.yml
ingress:
  - hostname: $PANEL_DOMAIN
    service: http://localhost:9000
  - service: http_status:404
EOF

sudo systemctl restart cloudflared
echo -e "${GREEN}✅ 隧道配置已更新。${NC}"

# --- 第四步：面板家具进场 (Docker 容器 + index.html) ---
echo -e "\n${BLUE}[4/4] 正在搬运“包工头管理面板”家具...${NC}"

# 清理旧容器
docker rm -f vps_panel 2>/dev/null
mkdir -p /root/yinluren_panel

# 下载网页
curl -L https://raw.githubusercontent.com/zhangcaiduo/yinluren/refs/heads/main/index.html -o /root/yinluren_panel/index.html

# 启动面板
docker run -d --name vps_panel \
  -p 127.0.0.1:9000:80 \
  -v /root/yinluren_panel:/usr/share/nginx/html:ro \
  --restart always \
  nginx:alpine

echo -e "\n${GREEN}===============================================================${NC}"
echo -e "${CYAN}🎉 恭喜房主，引路人施工完毕！${NC}"
echo -e "你的管理面板地址：${GREEN}https://$PANEL_DOMAIN${NC}"
echo -e "${YELLOW}如果页面打不开，请检查 Cloudflare 后台是否添加了 Public Hostname。${NC}"
echo -e "${GREEN}===============================================================${NC}"
