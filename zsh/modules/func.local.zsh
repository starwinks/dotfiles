# Machine-specific custom functions.

WIN_IP="127.0.0.1"
PROXY_PORT="7890"

# Reverse tunnel: forward remote server's 1080 port to local Windows proxy
function star_proxy() {
    if [ -z "$1" ]; then
        echo "Usage: star_proxy <alias_or_ip>"
        return 1
    fi

    # Kill old tunnel processes for this server
    pkill -f "ssh -R 1080.*$1" 2>/dev/null

    # Establish new tunnel
    echo "Routing $1:1080 -> $WIN_IP:$PROXY_PORT"
    ssh -R 1080:"$WIN_IP":"$PROXY_PORT" -Nf "$1"
}
