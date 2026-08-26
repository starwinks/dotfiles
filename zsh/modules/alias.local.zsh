# Machine-specific aliases.

# EasyConnect VPN container
alias ec='docker run -d --device /dev/net/tun --cap-add NET_ADMIN -ti -p 127.0.0.1:1080:1080 -p 127.0.0.1:8888:8888 -v /tmp/.X11-unix:/tmp/.X11-unix -e EC_VER=7.6.7 -e DISPLAY hagb/docker-easyconnect:vncless-7.6.7'
alias eckill='docker ps -q --filter ancestor=hagb/docker-easyconnect:vncless-7.6.7 | xargs -r docker stop | xargs -r docker rm'

# Markdown to PDF
alias md2pdf='md2pdf --config-file ~/tools/md2pdf/config.js'

# cc-switch
alias ccc=cc-switch-cli
alias ccu='cc-switch > /dev/null 2>&1 &'

alias format='clang-format-20'
alias clang-format='clang-format-20'
alias llama='/home/starwink/llama.cpp/build/bin/llama-server'
