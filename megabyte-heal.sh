#!/bin/bash

# ********************************************
# 	    Script de Auto Healing
# 	    Carlos 'Snake' Menezes
#   [Megabyte Security Labs] - VoRTeX Corp.
# ********************************************

# Configuração das Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Define o ficheiro de log
LOG_FILE="/var/log/megabyte-heal.log"

log_action() {

local type="$1" 
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Define a cor com base no tipo
    local color=$NC
    case "$type" in
        "OK") color=$GREEN ;;
        "ALERTA"|"INTERVENÇÃO"|"[BAN]") color=$RED ;;
        "MANUTENÇÃO") color=$YELLOW ;;
        "INFO") color=$CYAN ;;
    esac

    # Faz o log limpo, sem lixo de ANSI
    echo "[$timestamp] $type: $message" >> "$LOG_FILE"

    # Exibe no ecrã com cores
    echo -e "[$timestamp] ${color}$type${NC}: $message"
}

# 1. Recuperação de Rede e DNS
if ! ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    log_action "INTERVENÇÃO: Sem internet. Iniciando cura de rede..."
    echo "nameserver 8.8.8.8" > /etc/resolv.conf
    ip route del default 2>/dev/null
    ip route add default via 192.168.1.254 dev wlan0 2>/dev/null
else
    log_action "OK" "Conectividade de rede estável."
fi

# 2. Garantia do Firewall (IPSet)
if ! ipset list blacklist > /dev/null 2>&1; then
    log_action "INTERVENÇÃO" "Recriando IPSet blacklist..."
    ipset create blacklist hash:ip
else
    log_action "OK" "IPSet blacklist ativo."
fi

# 3. Saúde do Splunk
SPLUNK_STATUS=$(systemctl is-active splunk)
if [ "$SPLUNK_STATUS" = "activating" ]; then
    log_action "ALERTA" "Splunk travado. Matando zumbis e reiniciando..."
    killall -9 wget 2>/dev/null
    systemctl restart splunk
else
    log_action "OK" "Splunk status: $SPLUNK_STATUS."
fi

# 4. Verificação MySQL
MYSQL_STATUS=$(systemctl is-active mysql)
if [ "$MYSQL_STATUS" != "active" ]; then
    log_action "ALERTA" "MySQL status: $MYSQL_STATUS. Reiniciando..."
    systemctl start mysql
    log_action "OK" "MySQL restaurado."
else
    log_action "OK" "MySQL status: active."
fi

# 6. Bloqueio de Datacenters em paginas Login
log_action "ALERTA" "Analisando logs do Nginx para reconhecimento hostil..."

# Filtra IPs que acederam a caminhos de login/admin nas ultimas 1000 linhas de logs do nginx
SUSPECT_IPS=$(sudo tail -n 1000 /var/log/nginx/access.log | awk '$7 ~ /\/login|\/admin|\/account|\/webmin/ {print $1}' | sort -u)

for ip in $SUSPECT_IPS; do
    # Verifica se o IP existe na blacklist antes de processar o whois para poupar recursos
    if ! sudo ipset test blacklist $ip >/dev/null 2>&1; then

        # Só faz o Whois se o IP for novo
        ORG=$(whois $ip | grep -Ei "DigitalOcean|Hetzner|Amazon|OVH|Linode|Google-Cloud" | head -1)

        if [ ! -z "$ORG" ]; then
            log_action "[BAN] Bloqueando IP de Datacenter detetado em área sensível: $ip ($ORG)"
            sudo ipset add blacklist $ip
            logger "[BAN]" "MEGABYTE-HEAL: Bloqueio preventivo do IP $ip."
        fi
    else
        # Devolve que o IP já encontra-se na Blacklist não adicionando.
        log_action "INFO" "IP $ip já se encontra na blacklist. Ignorando." > /dev/null
    fi
done

# 7. Destravar APT
# Nota: Remover locks sempre pode ser arriscado, mas regista-se a limpeza
log_action "MANUTENÇÃO" "Limpando locks residuais do APT."
rm -f /var/lib/apt/lists/lock
rm -f /var/cache/apt/archives/lock
rm -f /var/lib/dpkg/lock*

# 8. Finalização do Scripts
log_action "OK" "Checkup concluído."
log_action "OK" "Obrigado por usar o script de auto-heal."
log_action "OK" "Script por Carlos 'Snake' Menezes"

