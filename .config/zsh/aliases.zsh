_exists() {
    command -v $1 > /dev/null 2>&1
}

alias up=update
alias systemctl-restart=systemctl-enable
alias teams="teams --disable-seccomp-filter-sandbox"
alias get-class="xprop | grep \"WM_CLASS\""

# ---- System ----------------------------
alias t="touch"
alias cat="cat"
alias r="ranger"
alias ca="calcurse"
alias help="tldr"
alias dir="dir --color "
alias rms="shred -uzvn3"

alias iexm="iex -S mix"

alias bye="shutdown 0"
alias soon="i3lock -c 000000; systemctl suspend"

alias xev="xev -event keyboard  | egrep -o 'keycode.*\)'"

alias x+="chmod +x"
alias x++="sudo chmod +x"
alias -- +x="chmod +x"
alias -- ++x="sudo chmod +x"

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

alias c.="code ."
alias c..="code . && exit"

alias vi="nvim"
alias nv="nvim"
alias nv.="nvim ."

alias e="$EDITOR"
alias e.="$EDITOR ."
alias e..="$EDITOR . && exit"

# ls  -  colorflag="--color=auto"
# alias l="lsd -a ${colorflag}"
# alias ls="lsd -lF ${colorflag}"
# alias lsa="lsd -lAF ${colorflag}"

alias l='eza --icons '
alias ls='eza --icons -l'
alias la='eza --icons -la'
alias ll='ls -la'
alias lt='eza --icons --tree'

# tar
alias tarzip='unzip'
alias tarx='tar -xvf'
alias targz='tar -zxvf'
alias tarbz2='tar -jxvf'

# ---- Apps ----------------------------

# Docker
alias dr="docker run"
alias ds="docker start"
alias dst="docker stop"
alias di="docker image"
alias dv="docker volume"

alias dls="docker ps -a"
alias drmall="docker rm $(docker ps -a -q)"

alias dc="docker-compose"
alias dcup="docker-compose up"
alias dcupd="docker-compose up -d"


# Elixir
alias mcr="mix credo"
alias mco="mix compile"
alias mf="mix format"

alias mdg="mix deps.get"
alias mec="mix ecto.create "
alias mes="mix ecto.setup"
alias mem="mix ecto.migrate"
alias megm="mix ecto.gen.migration"

alias mpn="mix phx.new"
alias mps="mix phx.server"


# Playerctl
alias plspotify="playerctl -p spotify "
alias plplay="plspotify play-pause"
alias plnext="plspotify next"
alias plprev="plspotify previous"
alias plvolu="plspotify volume"


# Du / Agedu
alias ageduh="sudo agedu -s /home/meimfhd -w --auth none"
alias agedus="sudo agedu -s / -w --auth none"
alias sizes="sudo du -sh ~/.* | sort -rh | head -10"


# MISC
alias findd="sudo find / -iname "
alias xmonadr="xmonad --recompile"
alias selfestival="xsel | festival --tts"
alias kitty-theme="kitty +kitten themes "

alias rofi-drun="rofi -show drun"
alias rofi-calc="rofi -show calc"

alias disks="sudo gnome-disks"

alias infos="inxi & inxi -G"
alias char="gucharmap"

alias df='duf'
alias du='gdu -c' # -c para mostrar cores

alias fordasa='sudo openfortivpn dasavpn2.dasa.com.br:443 --saml-login'






ipconfig() {
    echo "--- IPs Locais ---"
    ip a | grep 'inet' | grep -v '127.0.0.1' | awk '{print $2}'
    echo "\n--- IP Público ---"
    curl -s ifconfig.me || curl -s icanhazip.com
}

mkcd() {
    mkdir -p "$1" && cd "$1"
}

bak() {
    cp -- "$1" "$1.bak"
}


reload(){
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # Sem Cor

    echo -e "${GREEN}--- Iniciando Atualização de Caches ---${NC}"

    # Valida o timestamp do sudo no início para não pedir senha a cada comando
    sudo -v

    # 1. Cache de fontes (Font Cache)
    echo -e "\n${YELLOW}Reconstruindo o cache de fontes...${NC}"
    fc-cache -fv

    # 2. Cache de ícones (Icon Cache)
    echo -e "\n${YELLOW}Atualizando o cache de ícones...${NC}"
    # Atualiza os caches nos diretórios padrão de ícones do sistema
    # O GTK usa esses caches para carregar ícones de forma mais rápida.
    sudo gtk-update-icon-cache -qtf /usr/share/icons/hicolor
    # Se você usa outros temas, pode adicionar o caminho deles aqui também.

    # 3. Base de dados de aplicativos (Desktop Database)
    echo -e "\n${YELLOW}Atualizando a base de dados de tipos MIME...${NC}"
    # Garante que o sistema saiba qual aplicativo abrir para cada tipo de arquivo.
    sudo update-desktop-database -q

    # 4. Base de dados do 'man'
    echo -e "\n${YELLOW}Atualizando a base de dados das 'man pages'...${NC}"
    sudo mandb -q

    echo -e "\n${GREEN}--- Atualização de Caches Concluída ---${NC}"
}

killp(){
    fuser -k -n tcp 3000
    fuser -k -n tcp 3001
    fuser -k -n tcp 3002
    fuser -k -n tcp 3004
}


status() {
    while getopts ":hvdncs" opt; do
        case $opt in
            h)
                echo "Usage: status [OPTION]"
                echo ""
                echo "   -h    Show this help message"
                echo "   -d    Show disk usage (duf)"
                echo "   -n    Show network info"
                echo "   -m    Show monitor info"
                echo "   -c    Show config info (clock, keyboard, locale)"
                echo "   -a    Apps"
                echo "   -i    Show audio info (pactl info)"

            ;;

            # v)
            #   VBoxManage setextradata global GUI/SuppressMessages "all"
            # ;;

            a)
                xprop
                mozo
                pkgbrowser
            ;;

            m)
                arandr
            ;;

            i)
                pactl info
            ;;

            d)
                echo_separate "duf"
                duf
            ;;

            n)
                echo_separate "lspci -v"
                lspci -vv | grep -A11 "Ethernet controller"

                echo_separate "cat /etc/modprobe.d/blacklist.conf"
                cat /etc/modprobe.d/blacklist.conf

                echo_separate "cat /usr/lib/modprobe.d/r8168.conf"
                cat /usr/lib/modprobe.d/r8168.conf

                echo_separate "dmesg | grep r8169"
                sudo dmesg | grep r8169

                echo_separate "dmesg | grep r8168"
                sudo dmesg | grep r8168

                echo_separate "httpstat google.com"
                httpstat https://www.google.com
            ;;

            c)
                echo_separate "Clock (hwclock --show)"
                sudo hwclock --show
                timedatectl

                echo_separate "Keyboard (localectl status)"
                localectl status

                echo_separate "Locale (locale)"
                locale
            ;;

            s)
                echo_separate "du"
            ;;

            \?) echo "Invalid option: -$OPTARG"
            ;;

            :) echo "Option -$OPTARG requires an argument."
            ;;
        esac
    done
}
