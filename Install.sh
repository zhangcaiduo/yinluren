#!/bin/bash

# --- 颜色定义 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear

# --- 欢迎 Logo (建议此处放你设计的简笔画字符版) ---
echo -e "${CYAN}"
echo "   ██████╗  █████╗  ██████╗ ██████╗ ██████╗ ████████╗██╗   ██╗ ██████╗ "
echo "   ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔═══██╗╚══██╔══╝██║   ██║██╔═══██╗"
echo "   ██████╔╝███████║██║   ██║██║     ██║   ██║   ██║   ██║   ██║██║   ██║"
echo "   ██╔═══╝ ██╔══██║██║   ██║██║     ██║   ██║   ██║   ██║   ██║██║   ██║"
echo "   ██║     ██║  ██║╚██████╔╝╚██████╗╚██████╔╝   ██║   ╚██████╔╝╚██████╔╝"
echo "   ╚═╝     ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═════╝    ╚═╝    ╚═════╝  ╚═════╝ "
echo -e "${NC}"
echo -e "${GREEN}============ VPS 包工头 · 引路人 v1.0.0 ========================${NC}"
echo -e "${BLUE}作者：张财多 | 宗旨：让每一台小鸡都有尊严地装修${NC}"
echo -e "${GREEN}===============================================================${NC}"

# --- 枯燥但硬核的科普环节 ---
echo -e "${YELLOW}【包工头科普时间】${NC}"
echo -e "房主请留步，看一眼这套“精装修”的逻辑，别处可不教这些： "
echo -e "1. ${CYAN}总线逻辑${NC}：本脚本默认占用 VPS 的 ${GREEN}80/443${NC} 端口作为“总出口”。 "
echo -e "2. ${CYAN}暗道分配${NC}：我们会把不同的应用（比如面板、网盘）塞进 VPS 内部的不同端口。 [cite: 101, 107]"
echo -e "3. ${CYAN}隧道穿透${NC}：通过 Cloudflare Tunnel，把这些“内网端口”安全地发射到你的域名上。 [cite: 56, 61]"
echo -e "   ${RED}好处${NC}：你不需要在 VPS 上开火（放行防火墙），所有家具都在防火墙后安稳呆着。 [cite: 13, 14]"
echo "---------------------------------------------------------------"
sleep 2

# --- 第一步：地基找平 (安装 Docker) ---
echo -e "${BLUE}[1/4] 正在清理地基，安装 Docker 环境...${NC}"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh [cite: 16]
    systemctl start docker && systemctl enable docker [cite: 17]
    echo -e "${GREEN}✅ Docker 施工完毕！${NC}"
else
    echo -e "${GREEN}✅ 检测到 Docker 已存在，地基很稳！${NC}"
fi

# --- 第二步：接通总线 (Cloudflare Tunnel) ---
echo -e "\n${BLUE}[2/4] 正在接通 Cloudflare Tunnel 隧道总线...${NC}"
echo -e "${YELLOW}请前往：Cloudflare Zero Trust -> Access -> Tunnels${NC}"
echo -e "${YELLOW}创建一个新 Tunnel，选择 Connector，复制页面生成的 Token。${NC}"
read -p "请输入你的 Tunnel Token: " TUNNEL_TOKEN

if [ -z "$TUNNEL_TOKEN" ]; then
    echo -e "${RED}错误：Token 不能为空，施工中断。${NC}"
    exit 1
fi

# 安装 cloudflared [cite: 70]
sudo mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt-get update && sudo apt-get install -y cloudflared [cite: 70]

# 安装服务 [cite: 75]
sudo cloudflared service install "$TUNNEL_TOKEN"
sudo systemctl start cloudflared && sudo systemctl enable cloudflared [cite: 75, 76]

# --- 第三步：面板子域名绑定 ---
echo -e "\n${BLUE}[3/4] 配置包工头管理面板域名...${NC}"
read -p "请输入你为“管理面板”预留的二级域名 (例如 guanli.example.com): " PANEL_DOMAIN

if [ -z "$PANEL_DOMAIN" ]; then
    PANEL_DOMAIN="vps-manager.yourdomain.com"
    echo -e "${YELLOW}未输入，将使用默认占位域名，请稍后手动修改。${NC}"
fi

# 修改配置文件映射到面板容器端口 (假设面板在 9000 端口) [cite: 61, 65]
TUNNEL_CONFIG="/etc/cloudflared/config.yml"
sudo mkdir -p /etc/cloudflared
cat <<EOF | sudo tee $TUNNEL_CONFIG
ingress:
  - hostname: $PANEL_DOMAIN
    service: http://localhost:9000
  - service: http_status:404
EOF

sudo systemctl restart cloudflared [cite: 67]
echo -e "${GREEN}✅ 隧道已指向 https://$PANEL_DOMAIN${NC}"

# --- 第四步：面板家具进场 (Docker 容器 + 你的 index.html) ---
echo -e "\n${BLUE}[4/4] 正在搬运“包工头管理面板”家具...${NC}"

# 1. 创建面板存放目录
mkdir -p /root/yinluren_panel

# 2. 从你的仓库下载最新的 index.html [cite: 5, 37]
curl -L https://raw.githubusercontent.com/zhangcaiduo/yinluren/refs/heads/main/index.html -o /root/yinluren_panel/index.html

# 3. 把你那张黑白线描图也下载下来 (假设文件名是 zhangcaiduo.png)
# curl -L https://raw.githubusercontent.com/zhangcaiduo/yinluren/refs/heads/main/zhangcaiduo.png -o /root/yinluren_panel/zhangcaiduo.png

# 4. 启动轻量级 Web 容器，并挂载你的网页文件 [cite: 101, 107]
docker run -d --name vps_panel \
  -p 127.0.0.1:9000:80 \
  -v /root/yinluren_panel:/usr/share/nginx/html:ro \
  --restart always \
  nginx:alpine

echo -e "\n${GREEN}===============================================================${NC}"
echo -e "${CYAN}🎉 恭喜房主，引路人施工完毕！${NC}"
echo -e "你的管理面板地址：${GREEN}https://$PANEL_DOMAIN${NC}"
echo -e "${YELLOW}现在，你可以放心地关闭 SSH 窗口，去网页端继续装修了。${NC}"
echo -e "${GREEN}===============================================================${NC}"
