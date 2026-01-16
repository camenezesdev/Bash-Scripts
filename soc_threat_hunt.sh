#!/bin/bash

# ********************************************
# Script para Procura por IPs que dispararam 
# 	alertas no Suricata (eve.json)
# 	    Carlos 'Snake' Menezes
#   [Megabyte Security Labs] - VoRTeX Corp.
# ********************************************

SURICATA_EVE="/var/log/suricata/eve.json"
NGINX_LOG="/var/log/nginx/access.log"

echo "*** [THREAT HUNTING: Suricata Alerts] ***"

# Extrai IPs únicos que geraram alertas no Suricata
ALERTS=$(grep '"event_type":"alert"' $SURICATA_EVE | jq -r '.src_ip' | sort -u)

if [ -z "$ALERTS" ]; then
    echo "[!] Nenhum alerta crítico detetado pelo Suricata."
else
    for IP in $ALERTS; do
        echo "[ALERT] IP: $IP detetado pelo IDS!"
        echo "   -> Atividade no Nginx para este IP:"
        grep "$IP" $NGINX_LOG | tail -n 3
        echo "**************************************"
    done
fi