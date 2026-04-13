# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# network settings
WIN_IP="127.0.0.1"
PROXY_PORT="7890"
export http_proxy="http://${WIN_IP}:${PROXY_PORT}"
export https_proxy="http://${WIN_IP}:${PROXY_PORT}"
export all_proxy="http://${WIN_IP}:${PROXY_PORT}"
# 本地回环, 校内流量等直连
export no_proxy="localhost,127.0.0.1,::1,172.17.0.0/16,${WIN_IP},.nju.edu.cn,114.212.0.0/16"