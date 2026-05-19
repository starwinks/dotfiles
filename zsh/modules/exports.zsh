# Proxy configuration
# Windows host IP for proxy forwarding

WIN_IP="127.0.0.1"
PROXY_PORT="7890"
export http_proxy="http://${WIN_IP}:${PROXY_PORT}"
export https_proxy="http://${WIN_IP}:${PROXY_PORT}"
export all_proxy="http://${WIN_IP}:${PROXY_PORT}"

# Local loopback, campus network traffic direct connection
export no_proxy="localhost,127.0.0.1,::1,172.17.0.0/16,${WIN_IP},.edu.cn,114.212.0.0/16"