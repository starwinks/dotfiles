WIN_IP="127.0.0.1"
PROXY_PORT="7890"
# 反向隧道：将目标服务器的 1080 端口转发至本地 Windows 代理
function star_proxy() {
    # 检查是否输入了服务器地址
    if [ -z "$1" ]; then
        echo "Usage: star_proxy <alias_or_ip>"
        return 1
    fi

    # 1. 自动清理针对该服务器的旧隧道进程
    pkill -f "ssh -R 1080.*$1" 2>/dev/null

    # 2. 建立新隧道
    echo "Routing $1:1080 -> $WIN_IP:$PROXY_PORT"
    ssh -R 1080:"$WIN_IP":"$PROXY_PORT" -Nf "$1"
}