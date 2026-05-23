# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

alias starttunnel='cloudflared tunnel --config ~/.cloudflared/config.yml run starserver'
alias ec='docker run -d --device /dev/net/tun --cap-add NET_ADMIN -ti -p 127.0.0.1:1080:1080 -p 127.0.0.1:8888:8888 -v /tmp/.X11-unix:/tmp/.X11-unix -e EC_VER=7.6.7 -e DISPLAY hagb/docker-easyconnect:vncless-7.6.7'
alias eckill='docker ps -q --filter ancestor=hagb/docker-easyconnect:vncless-7.6.7 | xargs -r docker stop | xargs -r docker rm'

alias md2pdf='md2pdf --config-file ~/tools/md2pdf/config.js'
alias proxy_off='unset http_proxy https_proxy all_proxy HTTPS_PROXY HTTP_PROXY'