#!/bin/bash

# --- 颜色定义 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${GREEN}============ VPS 包工头 · 引路人 v1.0.4 (安全强化版) ===========${NC}"
echo -e "${BLUE}作者：张财多 | 引入 x-ui 级安全防线：自定义暗道与密码${NC}"
echo -e "${GREEN}===============================================================${NC}"

# --- 第一步：收集房主安保需求 ---
echo -e "\n${YELLOW}【安保设置】请为你的面板配置门禁：${NC}"
read -p "1. 设置面板端口 (默认 9000): " PANEL_PORT
PANEL_PORT=${PANEL_PORT:-9000}

read -p "2. 设置安全暗道后缀 (例如 caiduo, 默认 mypanel): " SECRET_PATH
SECRET_PATH=${SECRET_PATH:-mypanel}
# 过滤掉用户可能输入的斜杠
SECRET_PATH=$(echo $SECRET_PATH | tr -d '/')

read -p "3. 设置登录账号 (默认 admin): " PANEL_USER
PANEL_USER=${PANEL_USER:-admin}

read -p "4. 设置登录密码 (默认 123456): " PANEL_PASS
PANEL_PASS=${PANEL_PASS:-123456}

echo -e "${GREEN}配置已记录，正在施工...${NC}"

# --- 第二步：打地基 (Docker) ---
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
    systemctl start docker && systemctl enable docker
fi

# --- 第三步：配置暗道与门禁文件 ---
# 1. 停掉旧项目
docker rm -f vps_panel 2>/dev/null
rm -rf /root/yinluren_panel
mkdir -p /root/yinluren_panel/html/$SECRET_PATH

# 2. 生成密码文件 (htpasswd)
# 使用 Python 3 快速生成 Nginx 认可的密码哈希
HTHASH=$(python3 -c "import crypt; print(crypt.crypt('${PANEL_PASS}', crypt.mksalt(crypt.METHOD_SHA512)))")
echo "${PANEL_USER}:${HTHASH}" > /root/yinluren_panel/.htpasswd

# 3. 编写 Nginx 路由规则
cat <<EOF > /root/yinluren_panel/default.conf
server {
    listen 80;
    
    # 大门：伪装成 404 或者空白
    location / {
        root /usr/share/nginx/html;
        index fake.html;
    }
    
    # 暗道：你的真实面板
    location /$SECRET_PATH/ {
        alias /usr/share/nginx/html/$SECRET_PATH/;
        auth_basic "VPS 包工头 - 闲人免进";
        auth_basic_user_file /etc/nginx/.htpasswd;
        index index.html;
    }
}
EOF

# --- 第四步：搬运家具 ---
# 1. 伪装页
echo "<h1>404 Not Found - 闲人免进</h1>" > /root/yinluren_panel/html/fake.html

# 2. 真实面板 (下载你的 index.html 到暗道里)
curl -fsSL https://raw.githubusercontent.com/zhangcaiduo/yinluren/refs/heads/main/index.html -o /root/yinluren_panel/html/$SECRET_PATH/index.html

# --- 第五步：启动安保系统 ---
docker run -d --name vps_panel \
  -p $PANEL_PORT:80 \
  -v /root/yinluren_panel/html:/usr/share/nginx/html:ro \
  -v /root/yinluren_panel/default.conf:/etc/nginx/conf.d/default.conf:ro \
  -v /root/yinluren_panel/.htpasswd:/etc/nginx/.htpasswd:ro \
  --restart always \
  nginx:alpine >/dev/null 2>&1

# 拆除系统防火墙拦截
ufw disable >/dev/null 2>&1
iptables -F
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# 获取本机公网 IP
IP=$(curl -s4 icanhazip.com)

echo -e "\n${GREEN}===============================================================${NC}"
echo -e "${CYAN}🎉 防盗门安装完毕！${NC}"
echo -e "你的专属管理面板地址是："
echo -e "${YELLOW}http://$IP:$PANEL_PORT/$SECRET_PATH/${NC}"
echo -e "账号：${GREEN}$PANEL_USER${NC}"
echo -e "密码：${GREEN}$PANEL_PASS${NC}"
echo -e "${RED}请务必保存好以上地址，别人即使扫到你的端口，也找不到门在哪！${NC}"
echo -e "${GREEN}===============================================================${NC}"
