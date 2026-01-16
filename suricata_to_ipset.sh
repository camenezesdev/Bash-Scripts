#!/bin/bash

# ********************************************
# Script para Monitorização Real-Time Suricata
# 	    Carlos 'Snake' Menezes
#   [Megabyte Security Labs] - VoRTeX Corp.
# ********************************************

# CONFIGURAÇÃO
SURICATA_EVE="/var/log/suricata/eve.json"
IPSET_NAME="blacklist"
LOG_FILE="/opt/splunk/var/log/splunk/suricata_ips.log"
MY_IP=""

echo "$(date): Iniciando monitorização Suricata -> IPSet" >> $LOG_FILE

# tail -F para ler o ficheiro em tempo real
tail -F "$SURICATA_EVE" | while read -r line; do
    # Verifica se a linha contém um alerta
    if echo "$line" | grep -q '"event_type":"alert"'; then
        # Extrai o IP de origem usando jq
        SRC_IP=$(echo "$line" | jq -r '.src_ip')
        
        # Proteção: Não banir o teu próprio IP
        if [ "$SRC_IP" != "$MY_IP" ] && [ "$SRC_IP" != "null" ]; then
            # Verifica se o IP já está no ipset para não duplicar logs
            if ! sudo ipset test $IPSET_NAME "$SRC_IP" 2>/dev/null; then
                sudo ipset add $IPSET_NAME "$SRC_IP" -exist
                echo "$(date): [BLOCK] IP $SRC_IP banido por alerta do Suricata" >> $LOG_FILE
            fi
        fi
    fi
done