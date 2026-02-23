#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${GREEN}============ VPS 包工头 · 引路人 v2.0 (全栈旗舰版) ===========${NC}"
echo -e "${BLUE}功能：x-ui级安全门禁 + 实时面板监控 + 网页一键部署隧道${NC}"
echo -e "${GREEN}===============================================================${NC}"

# --- 1. 收集房主需求 ---
echo -e "\n${YELLOW}【安保设置】请为你的面板配置门禁：${NC}"
read -p "1. 面板端口 (默认 9000): " PANEL_PORT
PANEL_PORT=${PANEL_PORT:-9000}

read -p "2. 安全暗道后缀 (如 caiduo, 默认 mypanel): " SECRET_PATH
SECRET_PATH=${SECRET_PATH:-mypanel}
SECRET_PATH=$(echo $SECRET_PATH | tr -d '/')

read -p "3. 登录账号 (默认 admin): " PANEL_USER
PANEL_USER=${PANEL_USER:-admin}

read -p "4. 登录密码 (默认 123456): " PANEL_PASS
PANEL_PASS=${PANEL_PASS:-123456}

# --- 2. 打地基 ---
echo -e "\n${BLUE}正在安装基础环境，请稍候...${NC}"
apt-get update -qq && apt-get install -y -qq python3 openssl curl wget >/dev/null 2>&1

if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh >/dev/null 2>&1
    systemctl start docker && systemctl enable docker
fi

# --- 3. 部署面板与防盗门 ---
docker rm -f vps_panel 2>/dev/null
pkill -f monitor.sh 2>/dev/null
pkill -f api_server.py 2>/dev/null
rm -rf /root/yinluren_panel
mkdir -p /root/yinluren_panel/html/$SECRET_PATH
mkdir -p /root/yinluren_panel/conf

HTHASH=$(openssl passwd -5 "$PANEL_PASS")
echo "${PANEL_USER}:${HTHASH}" > /root/yinluren_panel/conf/.htpasswd

cat <<EOF > /root/yinluren_panel/conf/default.conf
server {
    listen 80;
    location / { root /usr/share/nginx/html; index fake.html; }
    location /$SECRET_PATH/ {
        alias /usr/share/nginx/html/$SECRET_PATH/;
        auth_basic "VPS Supervisor - Restricted Area";
        auth_basic_user_file /etc/nginx/conf/.htpasswd;
        index index.html;
    }
}
EOF

echo "<h1>404 Not Found - 闲人免进</h1>" > /root/yinluren_panel/html/fake.html
curl -fsSL https://raw.githubusercontent.com/zhangcaiduo/yinluren/refs/heads/main/index.html -o /root/yinluren_panel/html/$SECRET_PATH/index.html

# --- 4. 部署“监工” (每3秒写一次数据) ---
cat << 'EOF' > /root/yinluren_panel/monitor.sh
#!/bin/bash
DIR=$1
while true; do
    CPU=$(vmstat 1 2 | tail -1 | awk '{print 100 - $15}')
    RAM=$(free -m | awk '/Mem:/ { printf "%.1f", $3/$2*100 }')
    DISK=$(df -h / | awk '/\// { print $5 }' | sed 's/%//' | head -n 1)
    UPTIME=$(awk '{print int($1/3600)}' /proc/uptime)
    echo "{\"cpu\": \"$CPU\", \"ram\": \"$RAM\", \"disk\": \"$DISK\", \"uptime\": \"$UPTIME\"}" > "$DIR/data.json"
    sleep 3
done
EOF
chmod +x /root/yinluren_panel/monitor.sh
nohup /root/yinluren_panel/monitor.sh "/root/yinluren_panel/html/$SECRET_PATH" >/dev/null 2>&1 &

# --- 5. 部署“施工队API” (接收网页Token) ---
cat << 'EOF' > /root/yinluren_panel/api_server.py
import http.server, socketserver, json, subprocess
class Handler(http.server.SimpleHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(200, "ok"); self.send_header('Access-Control-Allow-Origin', '*'); self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS'); self.send_header('Access-Control-Allow-Headers', 'Content-Type'); self.end_headers()
    def do_POST(self):
        if self.path == '/api/tunnel':
            content_length = int(self.headers['Content-Length'])
            token = json.loads(self.rfile.read(content_length).decode('utf-8')).get('token', '')
            if token:
                subprocess.run("curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null && echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared jammy main' | tee /etc/apt/sources.list.d/cloudflared.list && apt-get update && apt-get install -y cloudflared", shell=True)
                subprocess.run("cloudflared service uninstall", shell=True)
                subprocess.run(f"cloudflared service install {token}", shell=True)
                subprocess.run("systemctl start cloudflared", shell=True)
                self.send_response(200); self.send_header('Content-type', 'application/json'); self.send_header('Access-Control-Allow-Origin', '*'); self.end_headers()
                self.wfile.write(b'{"status": "success"}')
            else:
                self.send_response(400); self.end_headers()
with socketserver.TCPServer(("", 9001), Handler) as httpd:
    httpd.serve_forever()
EOF
nohup python3 /root/yinluren_panel/api_server.py >/dev/null 2>&1 &

# --- 6. 启动展厅与放行大门 ---
docker run -d --name vps_panel -p $PANEL_PORT:80 -v /root/yinluren_panel/html:/usr/share/nginx/html:ro -v /root/yinluren_panel/conf/default.conf:/etc/nginx/conf.d/default.conf:ro -v /root/yinluren_panel/conf/.htpasswd:/etc/nginx/conf/.htpasswd:ro --restart always nginx:alpine >/dev/null 2>&1

ufw disable >/dev/null 2>&1
iptables -I INPUT -p tcp --dport $PANEL_PORT -j ACCEPT
iptables -I INPUT -p tcp --dport 9001 -j ACCEPT
IP=$(curl -s4 icanhazip.com)

echo -e "\n${GREEN}===============================================================${NC}"
echo -e "${CYAN}🎉 包工头全栈系统部署完毕！${NC}"
echo -e "你的专属管理面板地址是："
echo -e "${YELLOW}http://$IP:$PANEL_PORT/$SECRET_PATH/${NC}"
echo -e "账号：${GREEN}$PANEL_USER${NC}"
echo -e "密码：${GREEN}$PANEL_PASS${NC}"
echo -e "${RED}请妥善保存此地址。进入后，即可体验实时数据跳动与一键打通隧道！${NC}"
echo -e "${GREEN}===============================================================${NC}"
