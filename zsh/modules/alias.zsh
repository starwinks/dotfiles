# Color support for ls and grep
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Proxy control
alias proxy_off='unset http_proxy https_proxy all_proxy HTTPS_PROXY HTTP_PROXY ALL_PROXY no_proxy NO_PROXY'

# Cloudflare tunnel
alias starttunnel='cloudflared tunnel --config ~/.cloudflared/config.yml run starserver'

# EasyConnect VPN container
alias ec='docker run -d --device /dev/net/tun --cap-add NET_ADMIN -ti -p 127.0.0.1:1080:1080 -p 127.0.0.1:8888:8888 -v /tmp/.X11-unix:/tmp/.X11-unix -e EC_VER=7.6.7 -e DISPLAY hagb/docker-easyconnect:vncless-7.6.7'
alias eckill='docker ps -q --filter ancestor=hagb/docker-easyconnect:vncless-7.6.7 | xargs -r docker stop | xargs -r docker rm'

# Markdown to PDF
alias md2pdf='md-to-pdf --config-file ~/tools/md2pdf/config.js'