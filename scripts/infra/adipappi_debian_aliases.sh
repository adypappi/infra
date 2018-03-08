export COLOR="--color=auto"
alias ls="ls -F $COLOR"
alias ll="ls -ltra $COLOR"
alias rmdir="rm -rf $COLOR" 

# tail -f command
alias tailf='tail -f '

#finds big and very big file in current directory
alias bigfiles="find . -type f 2>/dev/null | xargs du -a 2>/dev/null | awk '{ if ( \$1 > 5000) print \$0 }'" 

alias verybigfiles="find . -type f 2>/dev/null | xargs du -a 2>/dev/null | awk '{ if ( \$1 > 500000) print \$0 }'" 

#show only my procs
alias psef='ps -ef | grep `whoami` | grep -v grep | grep -v "ps -ef"'
alias psaux='ps  -aux | grep `whoami` | grep -v grep | grep -v "ps -aux"'

# history
alias h='history'
alias j='jobs -l'

# get date and time
alias nowtime='date +"%T"'
alias nowdate='date +"%d-%m-%Y"'

# file edition
alias vi=vim
alias vis='vim "+set si"'
alias edit='vim'

# Fast ping doe not wait for 1 secondess
alias fastping='ping -c 100 -s.2'
alias portslist='netstat -plantu'
alias iptlist='sudo /sbin/iptables -L -n -v --line-numbers'
alias iptinlist='sudo /sbin/iptables -L INPUT -n -v --line-numbers'
alias iptoutlist='sudo /sbin/iptables -L OUTPUT -n -v --line-numbers'

# Parenting changing perms on / #
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'

# distro update commande - Debian  based distro
alias upgrade='sudo apt-get update  -y && sudo apt-get upgrade -y'2

# pass options to free ##
alias meminfo='free -m -l -t'

# Get top 10 processes memory
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'

# Get top 10 processes cpu ##
alias pscpu='ps auxf | sort -nr -k 3'
alias pscpu10='ps auxf | sort -nr -k 3 | head -10'

## Get server cpu info ##
alias cpuinfo='lscpu'

